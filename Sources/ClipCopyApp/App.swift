import SwiftUI
import AppKit
import ClipCopyNative
import ClipCopyUI
import ServiceManagement

@main struct ClipCopyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var controller: Controller
    init() {
        let args = CommandLine.arguments
        if args.contains("--self-check") {
            _ = NSApplication.shared
            let model = ClipModel.demo()
            let menu = MenuBarController(model: model).makeHistoryMenu()
            precondition(menu.items.count > 3)
            print("{\"launchSelfCheck\":true,\"syntheticOnly\":true,\"archiveOpened\":false,\"keychainAccessed\":false}")
            Foundation.exit(0)
        }
        if args.contains("--key-probe") {
            do { _ = try KeyStore.load(); print("{\"keyReadable\":true}"); Foundation.exit(0) }
            catch { print("{\"keyReadable\":false}"); Foundation.exit(1) }
        }
        let owner = Controller()
        owner.open()
        if args.contains("--verify-archive") {
            do {
                let receipt = try owner.verifyArchiveIntegrity()
                print(String(decoding: try JSONEncoder().encode(receipt), as: UTF8.self))
                Foundation.exit(receipt.authenticated ? 0 : 2)
            } catch { print("{\"authenticated\":false,\"error\":\"archive-check-failed\"}"); Foundation.exit(1) }
        }
        if args.contains("--status") {
            Self.report(owner, runningRecorder: false)
            Foundation.exit(owner.model.locked ? 1 : 0)
        }
        if args.contains("--enable-login") { owner.model.changeStartAtLogin?(true) }
        if args.contains("--enable-recording") {
            if owner.model.locked { owner.open(interactiveKeyAccess: true) }
            owner.setRecording(true)
            if owner.model.clipboardAccessNeeded {
                owner.model.requestClipboardAccess?()
                owner.setRecording(true)
            }
        } else { owner.resumeSavedRecording() }
        if args.contains("--enable-login") || args.contains("--enable-recording") {
            Self.report(owner, runningRecorder: true)
        }
        owner.observeSession()
        _controller = StateObject(wrappedValue: owner)
        AppDelegate.owner = owner
    }
    @MainActor private static func report(_ owner: Controller, runningRecorder: Bool) {
        var result: [String: Any] = [
            "archiveOpen": !owner.model.locked,
            "recordingPreference": owner.model.locked ? NSNull() : owner.model.history.settings.recordingEnabled,
            "loginEnabled": SMAppService.mainApp.status == .enabled,
            "loginNeedsApproval": SMAppService.mainApp.status == .requiresApproval,
            "otherCopyClipRunning": !NSRunningApplication.runningApplications(withBundleIdentifier: "com.fiplab.clipboard").isEmpty
        ]
        if #available(macOS 15.4, *) { result["clipboardAccessBehavior"] = NSPasteboard.general.accessBehavior.rawValue }
        if runningRecorder { result["recorderActiveInThisProcess"] = !owner.model.paused && !owner.model.locked }
        if let at = CommandLine.arguments.firstIndex(of: "--check-probe"), CommandLine.arguments.count > at + 1,
           let id = UUID(uuidString: CommandLine.arguments[at+1]), !owner.model.locked {
            let text = "ClipCopy Wechseltest " + id.uuidString
            result["syntheticProbeCaptured"] = owner.model.history.entries.contains { $0.text == text }
        }
        if let data = try? JSONSerialization.data(withJSONObject: result, options: [.sortedKeys]) {
            FileHandle.standardOutput.write(data + Data([10]))
        }
    }
    var body: some Scene { Settings { EmptyView() } }
}

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate {
    static var owner: Controller?
    private var menus: MenuBarController?
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let owner = Self.owner else { return }
        menus = MenuBarController(model: owner.model)
        menus?.start()
    }
}
