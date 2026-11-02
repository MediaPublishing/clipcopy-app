import AppKit
import ClipCopyUI

@MainActor final class OriginalUITests {
    func testNativeMenuCopiesThroughItsActionAndKeepsOriginalOrder() {
        _ = NSApplication.shared
        let model = ClipModel.demo()
        let controller = MenuBarController(model: model)
        let menu = controller.makeHistoryMenu()
        expectEqual(menu.items[0].title, "Select the clip you want to add to your clipboard")
        expectTrue(menu.items[1].isSeparatorItem)
        expectEqual(menu.items[2].title, "Projektbesprechung am Freitag")
        expectEqual(menu.items[2].keyEquivalent, "1")
        expectEqual(menu.items[3].title, "https://example.com/demo")
        expectEqual(menu.items[4].title, "Grüße aus dem Testlabor")
        expectEqual(menu.items.filter { !$0.isSeparatorItem }.suffix(5).map(\.title), ["Preferences...","Customer Support","Join Mailing List","Rate App","Quit"])
        let item = menu.items[3]
        expectTrue(NSApp.sendAction(item.action!, to: item.target, from: item))
        expectEqual(model.testBuffer, "https://example.com/demo")
    }
    func testNativeSearchReturnAndGeometry() {
        let model = ClipModel.demo(); var copied = false
        let view = HistoryPanelView(model: model) { copied = true }
        expectEqual(view.frame.size, NSSize(width: 600,height: 325))
        expectEqual(view.searchField.frame, NSRect(x: 20,y: 263,width: 560,height: 50))
        expectEqual(view.scrollView.frame, NSRect(x: 20,y: 10,width: 560,height: 250))
        view.searchField.stringValue = "Grusse"
        view.controlTextDidChange(Notification(name: NSControl.textDidChangeNotification))
        expectEqual(view.table.numberOfRows, 1)
        expectTrue(view.control(view.searchField, textView: NSTextView(), doCommandBy: #selector(NSResponder.insertNewline(_:))))
        expectTrue(copied)
        expectEqual(model.testBuffer, "Grüße aus dem Testlabor\nZweite Zeile")
    }
    func testNativeMenuEmptyAndTruncation() {
        let model = ClipModel.demo(); model.clearHistory()
        let menu = MenuBarController(model: model).makeHistoryMenu()
        expectEqual(menu.items[0].title, "Your clippings will appear here...")
        expectFalse(menu.items[0].isEnabled)
        expectFalse(menu.items.contains { $0.title == "Clear Clippings" })
        expectEqual(MenuBarController.menuTitle(String(repeating: "a",count: 41)), String(repeating: "a",count: 40) + "...")
        expectEqual(MenuBarController.menuTitle("first\nsecond"), "first")
    }
    func testPreferencesLoadAndDeleteKeepBackendSafety() {
        let model = ClipModel.demo()
        let view = GeneralPreferencesView(model: model)
        expectEqual(view.frame.size, NSSize(width: 420,height: 230))
        expectEqual(view.remember.stringValue, "1000")
        expectEqual(view.display.stringValue, "1000")
        let preferences = PreferencesWindowController(model: model)
        preferences.selectPane("Clips Management")
        expectEqual(preferences.window?.contentView?.frame.size, NSSize(width: 420,height: 320))
        preferences.selectPane("Ignored Apps")
        expectEqual(preferences.window?.contentView?.frame.size, NSSize(width: 420,height: 320))
        preferences.selectPane("General")
        expectEqual(preferences.window?.contentView?.frame.size, NSSize(width: 420,height: 230))
        let id = model.history.entries[0].id
        model.deleteEntries(ids: [id]); expectFalse(model.history.entries.contains { $0.id == id })
        let live = ClipModel(isDemo: false, history: model.history)
        live.commit = { _ in false }
        let remaining = live.history.entries
        live.deleteEntries(ids: Set(remaining.map(\.id)))
        expectEqual(live.history.entries, remaining)
    }
}
