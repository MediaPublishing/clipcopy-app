import AppKit
import Combine

private final class HistoryWindow: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor public final class MenuBarController: NSObject, NSWindowDelegate, NSMenuDelegate {
    private let model: ClipModel
    private var statusItem: NSStatusItem!
    private var popup: NSPanel!
    private var panel: HistoryPanelView!
    private var preferences: PreferencesWindowController!
    private var localMonitor: Any?
    private var observation: AnyCancellable?
    public init(model: ClipModel) { self.model = model; super.init() }
    public func start(showImmediately: Bool = false) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "paperclip", accessibilityDescription: "ClipCopy")
            button.target = self; button.action = #selector(statusClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        popup = HistoryWindow(contentRect: NSRect(x: 0,y: 0,width: 600,height: 325), styleMask: [.borderless], backing: .buffered, defer: false)
        popup.isReleasedWhenClosed = false; popup.delegate = self
        popup.level = .popUpMenu; popup.hasShadow = true
        panel = HistoryPanelView(model: model) { [weak self] in self?.popup.close() }
        popup.contentView = panel
        preferences = PreferencesWindowController(model: model)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.popup.isKeyWindow else { return event }
            if event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.command),
               let chars = event.charactersIgnoringModifiers, let number = Int(chars), (1...9).contains(number), self.model.visible.count >= number {
                self.model.selectedID = self.model.visible[number - 1].id
                self.panel.activateSelection(); return nil
            }
            return event
        }
        if showImmediately { showHistory() }
    }
    @objc private func statusClicked() {
        showMenu()
    }
    public func showHistory() {
        if model.locked {
            model.retryOpen?()
            if model.locked { showFailure(); return }
        }
        model.query = ""; model.selectedID = nil; panel.reload()
        if let button = statusItem.button, let statusWindow = button.window {
            let anchor = statusWindow.convertToScreen(button.convert(button.bounds, to: nil))
            let visible = statusWindow.screen?.visibleFrame ?? NSScreen.main!.visibleFrame
            let x = min(max(anchor.midX - 300, visible.minX), visible.maxX - 600)
            popup.setFrameOrigin(NSPoint(x: x, y: anchor.minY - 325))
        } else { popup.center() }
        NSApp.activate(ignoringOtherApps: true)
        popup.makeKeyAndOrderFront(nil); popup.makeFirstResponder(panel.searchField)
    }
    public func windowDidResignKey(_ notification: Notification) { if popup.isVisible { popup.close() } }
    public func makeHistoryMenu() -> NSMenu {
        let menu = NSMenu(); menu.autoenablesItems = false
        let entries = model.visible
        if !entries.isEmpty {
            let title = NSMenuItem(title: "Select the clip you want to add to your clipboard", action: nil, keyEquivalent: "")
            title.isEnabled = false; menu.addItem(title); menu.addItem(.separator())
            for (index,entry) in entries.enumerated() {
                let item = NSMenuItem(title: Self.menuTitle(entry.text), action: #selector(copyMenuEntry(_:)), keyEquivalent: index < 9 ? String(index + 1) : "")
                item.target = self; item.representedObject = entry.id; item.toolTip = entry.text
                menu.addItem(item)
            }
            menu.addItem(.separator())
            let clear = NSMenuItem(title: "Clear Clippings", action: #selector(clearHistory), keyEquivalent: "")
            clear.target = self; menu.addItem(clear)
        } else {
            let empty = NSMenuItem(title: "Your clippings will appear here...", action: nil, keyEquivalent: "")
            empty.isEnabled = false; menu.addItem(empty)
        }
        menu.addItem(.separator())
        let prefs = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
        prefs.target = self; menu.addItem(prefs)
        menu.addItem(.separator())
        for name in ["Customer Support", "Join Mailing List", "Rate App"] {
            let item = NSMenuItem(title: name, action: nil, keyEquivalent: ""); item.isEnabled = false; menu.addItem(item)
        }
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self; menu.addItem(quit)
        return menu
    }
    public static func menuTitle(_ text: String) -> String {
        let line = text.components(separatedBy: .newlines).first ?? ""
        return line.count > 40 ? String(line.prefix(40)) + "..." : line
    }
    @objc private func copyMenuEntry(_ item: NSMenuItem) {
        guard let id = item.representedObject as? UUID else { return }
        model.selectedID = id
        if !model.copySelected() { showFailure() }
    }
    private func showMenu() {
        if model.locked {
            model.retryOpen?()
            if model.locked { showFailure(); return }
        }
        model.query = ""
        statusItem.menu = makeHistoryMenu(); statusItem.button?.performClick(nil); statusItem.menu = nil
    }
    @objc private func openPreferences() { preferences.show() }
    @objc private func clearHistory() {
        let alert = NSAlert(); alert.messageText = "Clear Clippings"
        alert.informativeText = "Click the Clear button if you want to delete all recorded clippings."
        alert.addButton(withTitle: "Clear"); alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn { model.clearHistory() }
    }
    @objc private func quitApp() { NSApp.terminate(nil) }
    private func showFailure() {
        let alert = NSAlert(); alert.messageText = "ClipCopy"; alert.informativeText = model.message
        alert.addButton(withTitle: "OK"); alert.runModal()
    }
}
