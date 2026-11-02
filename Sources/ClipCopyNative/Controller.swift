import AppKit
import Combine
import CryptoKit
import Darwin
import ServiceManagement
import ClipCopyCore
import ClipCopyUI
import ClipCopyStorage

@MainActor public final class Controller: ObservableObject {
    public let model: ClipModel
    private var store: EncryptedStore?
    private var importedAt: Date?
    private var timer: Timer?
    private var board: PasteboardAdapter?
    private var generation = 0
    private var observers: [NSObjectProtocol] = []
    private var wasRecording = false
    public static var dataDirectory: URL { FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/ClipCopy", isDirectory: true) }
    public init() {
        model = ClipModel(isDemo: false)
        model.startAtLogin = SMAppService.mainApp.status == .enabled
        model.changeStartAtLogin = { [weak self] enabled in
            guard let self else { return }
            do {
                if enabled { try SMAppService.mainApp.register() }
                else { try SMAppService.mainApp.unregister() }
            } catch { self.model.message = "Start bei Anmeldung konnte nicht geändert werden." }
            self.model.startAtLogin = SMAppService.mainApp.status == .enabled
        }
        model.commit = { [weak self] next in self?.persist(next) == true }
        model.copyText = { [weak self] text in
            guard let self, !self.model.locked, self.store != nil else { return false }
            return PasteboardAdapter(board: .general).write(text)
        }
        model.recordingChange = { [weak self] enabled in self?.setRecording(enabled, requestAccess: enabled) }
        model.retryOpen = { [weak self] in self?.open(interactiveKeyAccess: true) }
        model.requestClipboardAccess = { [weak self] in self?.requestClipboardPermission() }
    }
    public func open(interactiveKeyAccess: Bool = false) {
        umask(0o077)
        do {
            let dir = Self.dataDirectory
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
            try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: dir.path)
            var mutableDir = dir; var values = URLResourceValues(); values.isExcludedFromBackup = true; try mutableDir.setResourceValues(values)
            let url = dir.appendingPathComponent("history.sqlite")
            let existing = FileManager.default.fileExists(atPath: url.path)
            let key: SymmetricKey
            if existing { key = try KeyStore.load(interactive: interactiveKeyAccess) }
            else {
                // An existing orphaned key is reusable; never overwrite it.
                if let found = try? KeyStore.load() { key = found } else { key = try KeyStore.createForNewArchive() }
            }
            let opened = try EncryptedStore(url: url, key: key)
            if !existing { try opened.save(ArchiveState()) }
            let state = try opened.load()
            store = opened; importedAt = state.importedAt
            model.history = History(entries: state.entries, settings: state.settings)
            model.selectedID = nil; model.locked = false; model.paused = true
            model.message = "Verlauf geöffnet. Aufnahme pausiert."
        } catch {
            store = nil; model.protect()
            model.message = "Verlauf kann nicht entsperrt werden. Bestehende Daten bleiben unverändert. ClipCopy erneut öffnen, um es noch einmal zu versuchen."
        }
    }
    public struct ArchiveReceipt: Codable {
        public let archivedRows: Int
        public let imported: Bool
        public let authenticated: Bool
    }
    public func verifyArchiveIntegrity() throws -> ArchiveReceipt {
        guard let store else { throw StorageError.unavailable }
        let saved = try store.load()
        return ArchiveReceipt(archivedRows: saved.entries.count, imported: saved.importedAt != nil, authenticated: true)
    }
    @discardableResult private func persist(_ history: History) -> Bool {
        guard let store, !model.locked else { return false }
        do { try store.save(ArchiveState(entries: history.entries, settings: history.settings, importedAt: importedAt)); return true }
        catch { timer?.invalidate(); timer = nil; model.paused = true; model.message = "Speicherfehler. Aufnahme gestoppt; letzter bestätigter Stand bleibt erhalten."; return false }
    }
    public func setRecording(_ enabled: Bool, requestAccess: Bool = false) {
        if !enabled {
            stopRecorder()
            if !model.locked, store != nil {
                var settings = model.history.settings; settings.recordingEnabled = false
                var next = model.history; try? next.updateSettings(settings)
                if persist(next) { model.history = next }
            }
            return
        }
        guard !model.locked, store != nil else { return }
        guard NSRunningApplication.runningApplications(withBundleIdentifier: "com.fiplab.clipboard").isEmpty else {
            model.message = "CopyClip läuft noch. Für den Wechsel CopyClip beenden; sein Verlauf bleibt erhalten."; return
        }
        guard #available(macOS 15.4, *) else { model.message = "Live-Aufnahme benötigt macOS 15.4 oder neuer."; return }
        let adapter = PasteboardAdapter(board: .general)
        if requestAccess && !adapter.capturePermitted { requestClipboardPermission() }
        guard adapter.capturePermitted else {
            model.clipboardAccessNeeded = true
            model.message = "macOS hat den Zwischenablagezugriff noch nicht erlaubt. Über die Schaltfläche anfragen, dann die Aufnahme erneut starten."
            return
        }
        model.clipboardAccessNeeded = false
        var next = model.history; var settings = next.settings; settings.recordingEnabled = true
        try? next.updateSettings(settings)
        guard persist(next) else { return }; model.history = next
        board = adapter; generation = adapter.changeCount; model.paused = false; model.message = "Aufnahme aktiv. Vertrauliche Kopien werden übersprungen."
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }
    private func tick() {
        guard !model.paused, !model.locked, let board else { return }
        guard board.capturePermitted else { setRecording(false); model.message = "Zwischenablagezugriff verweigert. Aufnahme gestoppt."; return }
        let next = board.changeCount
        guard next != generation else { return }; generation = next
        let app = NSWorkspace.shared.frontmostApplication
        let id = app?.bundleIdentifier
        let policy = CapturePolicy(excludedBundleIDs: model.history.settings.excludedBundleIDs, excludedNames: model.history.settings.excludedNames)
        guard let text = board.capture(policy: policy, activeID: id, activeName: app?.localizedName,
                                       paused: model.paused, locked: model.locked, stillValid: {
            !self.model.paused && !self.model.locked && NSWorkspace.shared.frontmostApplication?.bundleIdentifier == id
        }) else { return }
        var candidate = model.history
        candidate.ingest(ClipEntry(text: text, sourceID: id, sourceName: app?.localizedName))
        if persist(candidate) { model.history = candidate }
    }
    public func observeSession() {
        for name in ["com.apple.screenIsLocked"] {
            observers.append(DistributedNotificationCenter.default().addObserver(forName: .init(name), object: nil, queue: .main) { [weak self] _ in Task { @MainActor in self?.lock() } })
        }
        observers.append(DistributedNotificationCenter.default().addObserver(forName: .init("com.apple.screenIsUnlocked"), object: nil, queue: .main) { [weak self] _ in Task { @MainActor in self?.unlock() } })
        for name in [NSWorkspace.sessionDidResignActiveNotification, NSWorkspace.willSleepNotification] {
            observers.append(NSWorkspace.shared.notificationCenter.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in Task { @MainActor in self?.lock() } })
        }
        for name in [NSWorkspace.sessionDidBecomeActiveNotification, NSWorkspace.didWakeNotification] {
            observers.append(NSWorkspace.shared.notificationCenter.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in Task { @MainActor in self?.unlock() } })
        }
    }
    private func stopRecorder() { timer?.invalidate(); timer = nil; board = nil; model.paused = true }
    private func requestClipboardPermission() {
        guard !model.locked, model.paused, store != nil,
              NSRunningApplication.runningApplications(withBundleIdentifier: "com.fiplab.clipboard").isEmpty else { return }
        // Only an explicit user click reaches this metadata request. Discard the
        // current pasteboard; enabling recording later establishes a fresh baseline.
        _ = NSPasteboard.general.pasteboardItems?.count
        if #available(macOS 15.4, *), NSPasteboard.general.accessBehavior == .alwaysAllow { return }
        let alert = NSAlert()
        alert.messageText = "Clipboard access"
        alert.informativeText = "Allow ClipCopy under System Settings → Privacy & Security → Clipboard, then enable Record clipboard history again. Recording starts with your next copy."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    public func resumeSavedRecording() { if model.history.settings.recordingEnabled { setRecording(true) } }
    public func lock() {
        guard !model.locked else { return }
        wasRecording = !model.paused; stopRecorder(); model.protect(); store = nil
    }
    public func unlock() {
        guard model.locked else { return }
        let resume = wasRecording; wasRecording = false; open(); if resume { setRecording(true) }
    }
}
