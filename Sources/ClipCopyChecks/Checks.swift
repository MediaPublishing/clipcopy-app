import AppKit
import SwiftUI
import ClipCopyCore
import ClipCopyUI
import ClipCopyNative

@main struct Checks {
    @MainActor static func main() throws {
        if CommandLine.arguments.contains("--benchmark-search") {
            let entries = (0..<1000).map { i -> ClipEntry in
                let prefix = "Projekt \(i) "
                let length = i < 576 ? 1049 : 1048
                return ClipEntry(text: prefix + String(repeating: "a", count: length - prefix.utf8.count))
            }
            let history = History(entries: entries)
            var milliseconds: [Double] = []
            for i in 0..<30 {
                let start = DispatchTime.now().uptimeNanoseconds
                _ = history.visibleEntries(query: i.isMultiple(of: 2) ? "Projekt" : "kein-treffer-\(i)").count
                milliseconds.append(Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000)
            }
            let p95 = milliseconds.sorted()[28]
            let bytes = entries.reduce(0) { $0 + $1.text.utf8.count }
            print("{\"entries\":1000,\"textBytes\":\(bytes),\"searches\":30,\"p95Milliseconds\":\(p95),\"syntheticOnly\":true}")
            exit(p95 < 100 ? 0 : 1)
        }
        if CommandLine.arguments.contains("--foreign-key-probe") {
            do { _ = try KeyStore.load(); print("{\"foreignKeyDenied\":false}"); exit(1) }
            catch { print("{\"foreignKeyDenied\":true}"); return }
        }
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        let model = ClipModel.demo()
        model.query = "Grusse"
        precondition(model.visible.count == 1)
        model.selectedID = model.visible.first?.id
        precondition(model.copySelected())
        model.pasteTest()
        precondition(model.testResult == "Grüße aus dem Testlabor\nZweite Zeile")
        model.query = ""
        model.setPaused(false); precondition(!model.paused)
        model.setPaused(true); precondition(model.paused)
        let board = NSPasteboard.withUniqueName()
        defer { board.releaseGlobally() }
        let adapter = PasteboardAdapter(board: board)
        precondition(adapter.write("Synthetische Kopie äöü"))
        precondition(board.string(forType: .string) == "Synthetische Kopie äöü")
        precondition(adapter.capture(policy: CapturePolicy(), activeID: "com.example.Editor", activeName: "Editor", paused: false, locked: false, stillValid: { true }) == nil)
        board.clearContents(); board.setString("Synthetischer neuer Text", forType: .string)
        precondition(adapter.capture(policy: CapturePolicy(), activeID: "com.example.Editor", activeName: "Editor", paused: false, locked: false, stillValid: { true }) == "Synthetischer neuer Text")
        precondition(adapter.capture(policy: CapturePolicy(), activeID: "com.example.Editor", activeName: "Editor", paused: false, locked: false, stillValid: { false }) == nil)
        if let at = CommandLine.arguments.firstIndex(of: "--screenshots"), CommandLine.arguments.count > at+1 {
            let directory = URL(fileURLWithPath: CommandLine.arguments[at+1], isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            for theme in ["light","dark"] {
                let history = HistoryPanelView(model: model)
                try render(history, dark: theme == "dark", to: directory.appendingPathComponent("clipcopy-popup-\(theme).png"))
                let general = GeneralPreferencesView(model: model)
                try render(general, dark: theme == "dark", to: directory.appendingPathComponent("clipcopy-general-\(theme).png"))
                let preferences = PreferencesWindowController(model: model)
                for (pane,file) in [("Clips Management","clips"),("Ignored Apps","ignored-apps"),("About","about")] {
                    preferences.selectPane(pane)
                    if let view = preferences.window?.contentView {
                        try render(view, dark: theme == "dark", to: directory.appendingPathComponent("clipcopy-\(file)-\(theme).png"))
                    }
                }
            }
        }
        print("{\"demoFlow\":true,\"namedPasteboard\":true,\"realClipboardRead\":false}")
    }
    @MainActor private static func render(_ view: NSView, dark: Bool, to url: URL) throws {
        let window = NSWindow(contentRect: view.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = view
        window.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        window.orderFront(nil)
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        view.layoutSubtreeIfNeeded()
        guard let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { throw CocoaError(.fileWriteUnknown) }
        view.cacheDisplay(in: view.bounds, to: bitmap)
        guard let png = bitmap.representation(using: .png, properties: [:]) else { throw CocoaError(.fileWriteUnknown) }
        try png.write(to: url)
        window.close()
    }
}
