import AppKit
import ClipCopyUI

@main struct ClipCopyDemoApp {
    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = DemoDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}

@MainActor final class DemoDelegate: NSObject, NSApplicationDelegate {
    private var menus: MenuBarController?
    func applicationDidFinishLaunching(_ notification: Notification) {
        menus = MenuBarController(model: ClipModel.demo())
        let showMenu = CommandLine.arguments.contains("--show-menu")
        menus?.start(showImmediately: CommandLine.arguments.contains("--show-history") || showMenu)
        if showMenu {
            DispatchQueue.main.async { [weak self] in
                guard let menus = self?.menus else { return }
                NSApp.sendAction(NSSelectorFromString("statusClicked"), to: menus, from: nil)
            }
        }
    }
}
