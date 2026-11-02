import Foundation
import SwiftUI
import ClipCopyCore

@MainActor public final class ClipModel: ObservableObject {
    @Published public var history: History
    @Published public var query = ""
    @Published public var selectedID: UUID?
    @Published public var message = ""
    @Published public var paused = true
    @Published public var locked = false
    @Published public var testBuffer = ""
    @Published public var testResult = ""
    @Published public var tab = 0
    @Published public var startAtLogin = false
    public var changeStartAtLogin: ((Bool) -> Void)?
    @Published public var clipboardAccessNeeded = false
    @Published public var confirmBeforeDeleting = true {
        didSet { if !isDemo { UserDefaults.standard.set(confirmBeforeDeleting, forKey: "confirmBeforeDeleting") } }
    }
    public let isDemo: Bool
    public var commit: ((History) -> Bool)?
    public var copyText: ((String) -> Bool)?
    public var recordingChange: ((Bool) -> Void)?
    public var retryOpen: (() -> Void)?
    public var requestClipboardAccess: (() -> Void)?
    public init(isDemo: Bool, history: History = History()) {
        self.isDemo = isDemo; self.history = history; self.selectedID = history.entries.first?.id
        if !isDemo, UserDefaults.standard.object(forKey: "confirmBeforeDeleting") != nil {
            confirmBeforeDeleting = UserDefaults.standard.bool(forKey: "confirmBeforeDeleting")
        }
    }
    public static func demo() -> ClipModel {
        ClipModel(isDemo: true, history: History(entries: [
            ClipEntry(text: "Projektbesprechung am Freitag", sourceName: "Test-Editor"),
            ClipEntry(text: "https://example.com/demo", sourceName: "Test-Browser"),
            ClipEntry(text: "Grüße aus dem Testlabor\nZweite Zeile", sourceName: "Test-Notiz")
        ]))
    }
    public var visible: [ClipEntry] { locked ? [] : history.visibleEntries(query: query) }
    public var selected: ClipEntry? {
        guard !locked, let selectedID else { return nil }
        return visible.first { $0.id == selectedID }
    }
    @discardableResult public func copySelected() -> Bool {
        guard let entry = selected else { message = "Bitte einen Eintrag auswählen."; return false }
        if isDemo { testBuffer = entry.text; message = "Testkopie bereit."; return true }
        guard copyText?(entry.text) == true else { message = "Kopieren fehlgeschlagen."; return false }
        message = "In Zwischenablage kopiert. Mit Cmd+V einfügen."
        return true
    }
    public func pasteTest() { guard isDemo else { return }; testResult = testBuffer }
    public func moveSelection(by offset: Int) {
        let entries = visible
        guard !entries.isEmpty else { selectedID = nil; return }
        guard let selectedID, let index = entries.firstIndex(where: { $0.id == selectedID }) else {
            self.selectedID = offset < 0 ? entries.last?.id : entries.first?.id
            return
        }
        self.selectedID = entries[min(max(index + offset, 0), entries.count - 1)].id
    }
    public func setPaused(_ value: Bool) {
        if isDemo { paused = value; return }
        recordingChange?(!value)
    }
    public func applySettings(store: String, display: String, excludedIDs: [String], excludedNames: [String]) {
        guard let s = Int(store), let d = Int(display), s > 0, d > 0 else { message = "Bitte positive ganze Zahlen eingeben."; return }
        if d > s && !(s < history.settings.storeLimit && d == history.settings.displayLimit) {
            message = "Anzeigen darf die Zahl der gespeicherten Einträge nicht überschreiten."
            return
        }
        var value = history.settings
        value.storeLimit = s; value.displayLimit = min(d, s)
        value.excludedBundleIDs = excludedIDs; value.excludedNames = excludedNames
        var candidate = history
        do { try candidate.updateSettings(value) } catch { message = "Ungültige Historiengrenze."; return }
        if !isDemo && commit?(candidate) != true { return }
        history = candidate; message = "Einstellungen gespeichert."
    }
    public func deleteEntries(ids: Set<UUID>) {
        guard !locked else { return }
        var next = history
        for id in ids { next.remove(id: id) }
        if !isDemo && commit?(next) != true { return }
        history = next
        if let selectedID, ids.contains(selectedID) { self.selectedID = nil }
    }
    public func clearHistory() {
        guard !locked else { return }
        var next = history; next.removeAll()
        if !isDemo && commit?(next) != true { return }
        history = next; selectedID = nil; testBuffer = ""; testResult = ""; message = "Eigener Verlauf geleert."
    }
    public func protect() {
        locked = true; paused = true; query = ""; selectedID = nil
        history = History(settings: history.settings)
        testBuffer = ""; testResult = ""; message = "Verlauf gesperrt."
    }
}
