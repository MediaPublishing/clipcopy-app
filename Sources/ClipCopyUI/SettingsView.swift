import AppKit
import Combine
import SwiftUI
import ClipCopyCore

public struct SettingsView: NSViewRepresentable {
    let model: ClipModel
    public init(model: ClipModel) { self.model = model }
    public func makeNSView(context: Context) -> GeneralPreferencesView { GeneralPreferencesView(model: model) }
    public func updateNSView(_ view: GeneralPreferencesView, context: Context) { view.refresh() }
}

@MainActor public final class GeneralPreferencesView: NSView, NSTextFieldDelegate {
    private let model: ClipModel
    public let remember = NSTextField()
    public let display = NSTextField()
    private let record = NSButton(checkboxWithTitle: "Record clipboard history", target: nil, action: nil)
    private let startup = NSButton(checkboxWithTitle: "Start ClipCopy at system startup", target: nil, action: nil)
    private var observation: AnyCancellable?
    public init(model: ClipModel) {
        self.model = model
        super.init(frame: NSRect(x: 0,y: 0,width: 420,height: 230))
        wantsLayer = true; layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        let clips = section("Clippings", frame: NSRect(x: 12,y: 136,width: 396,height: 82))
        addSubview(clips)
        for (label,field,y) in [("Remember:",remember,32.0),("Display:",display,2.0)] {
            let name = NSTextField(labelWithString: label); name.frame = NSRect(x: 20,y: y+2,width: 80,height: 18)
            field.frame = NSRect(x: 104,y: y,width: 55,height: 22); field.delegate = self
            field.font = .systemFont(ofSize: 13); field.setAccessibilityLabel(label == "Remember:" ? "Remember Clippings" : "Display Clippings")
            let unit = NSTextField(labelWithString: "clippings"); unit.frame = NSRect(x: 165,y: y+2,width: 120,height: 18)
            clips.contentView?.addSubview(name); clips.contentView?.addSubview(field); clips.contentView?.addSubview(unit)
        }
        remember.toolTip = "Maximum: 9,999 clippings"
        let options = section("Options", frame: NSRect(x: 12,y: 54,width: 396,height: 70)); addSubview(options)
        startup.frame = NSRect(x: 20,y: 27,width: 350,height: 20); startup.target = self; startup.action = #selector(toggleStartup)
        record.frame = NSRect(x: 20,y: 1,width: 350,height: 20); record.target = self; record.action = #selector(toggleRecording)
        options.contentView?.addSubview(startup); options.contentView?.addSubview(record)
        observation = model.objectWillChange.sink { [weak self] in DispatchQueue.main.async { self?.refresh() } }
        refresh()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    public override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }
    public func refresh() {
        if remember.currentEditor() == nil { remember.stringValue = String(model.history.settings.storeLimit) }
        if display.currentEditor() == nil { display.stringValue = String(model.history.settings.displayLimit) }
        record.state = model.paused ? .off : .on
        startup.state = model.startAtLogin ? .on : .off
        startup.isEnabled = !model.isDemo && model.changeStartAtLogin != nil
        remember.isEnabled = !model.locked; display.isEnabled = !model.locked; record.isEnabled = !model.locked
        display.toolTip = "Maximum: \(model.history.settings.storeLimit) clippings"
    }
    private func section(_ title: String, frame: NSRect) -> NSBox {
        let box = NSBox(frame: frame); box.title = title; box.boxType = .primary
        box.titleFont = .systemFont(ofSize: 13, weight: .medium); return box
    }
    public func controlTextDidEndEditing(_ obj: Notification) {
        defer {
            remember.stringValue = String(model.history.settings.storeLimit)
            display.stringValue = String(model.history.settings.displayLimit)
        }
        guard let requested = Int(remember.stringValue), let shown = Int(display.stringValue), requested > 0, shown > 0 else { return }
        let store = min(requested, 9999)
        if requested > 9999 {
            let alert = NSAlert(); alert.messageText = "Value Too High"
            alert.informativeText = "The maximum allowed value for Remember Clippings is 9999. The value has been adjusted automatically."
            alert.addButton(withTitle: "OK"); alert.runModal()
        }
        if store < model.history.entries.count {
            let alert = NSAlert(); alert.messageText = "Reduce Clipping Limit"
            alert.informativeText = "You currently have \(model.history.entries.count) clippings stored. Reducing the limit to \(store) will immediately and permanently remove the oldest clippings. Do you want to continue?"
            alert.addButton(withTitle: "Continue"); alert.addButton(withTitle: "Cancel")
            guard alert.runModal() == .alertFirstButtonReturn else { refresh(); return }
        }
        model.applySettings(store: String(store), display: String(min(shown, store)), excludedIDs: model.history.settings.excludedBundleIDs, excludedNames: model.history.settings.excludedNames)
        refresh()
    }
    @objc private func toggleStartup() {
        let enabled = startup.state == .on
        model.changeStartAtLogin?(enabled)
        if model.startAtLogin != enabled {
            let alert = NSAlert(); alert.messageText = "ClipCopy"; alert.informativeText = model.message
            alert.addButton(withTitle: "OK"); alert.runModal()
        }
        refresh()
    }
    @objc private func toggleRecording() {
        model.setPaused(record.state != .on)
        if model.clipboardAccessNeeded {
            let alert = NSAlert(); alert.messageText = "ClipCopy"; alert.informativeText = model.message
            alert.addButton(withTitle: "Continue"); alert.addButton(withTitle: "Cancel")
            if alert.runModal() == .alertFirstButtonReturn { model.requestClipboardAccess?() }
        } else if (record.state == .on) == model.paused {
            let alert = NSAlert(); alert.messageText = "ClipCopy"; alert.informativeText = model.message
            alert.addButton(withTitle: "OK"); alert.runModal()
        }
        refresh()
    }
}

@MainActor public final class PreferencesWindowController: NSWindowController, NSToolbarDelegate {
    private let model: ClipModel
    private let panes = ["General", "Clips Management", "Ignored Apps", "About"]
    public init(model: ClipModel) {
        self.model = model
        let window = NSWindow(contentRect: NSRect(x: 0,y: 0,width: 420,height: 230), styleMask: [.titled,.closable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        super.init(window: window)
        let toolbar = NSToolbar(identifier: "ClipCopyPreferencesToolbar")
        toolbar.delegate = self; toolbar.displayMode = .iconAndLabel; toolbar.allowsUserCustomization = false
        window.toolbar = toolbar
        toolbar.selectedItemIdentifier = .init(panes[0])
        selectPane(panes[0]); window.center()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    public func show() { NSApp.activate(ignoringOtherApps: true); showWindow(nil); window?.makeKeyAndOrderFront(nil) }
    public func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] { panes.map { .init($0) } }
    public func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] { toolbarAllowedItemIdentifiers(toolbar) }
    public func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] { toolbarAllowedItemIdentifiers(toolbar) }
    public func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier id: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        let item = NSToolbarItem(itemIdentifier: id); item.label = id.rawValue
        let symbols = ["gearshape","list.clipboard","eye.slash","info.circle"]
        item.image = NSImage(systemSymbolName: symbols[panes.firstIndex(of: id.rawValue) ?? 0], accessibilityDescription: id.rawValue)
        item.target = self; item.action = #selector(changePane); return item
    }
    @objc private func changePane(_ item: NSToolbarItem) { selectPane(item.itemIdentifier.rawValue) }
    public func selectPane(_ name: String) {
        guard let window else { return }
        let view: NSView
        switch name {
        case "Clips Management": view = ClippingsPreferencesView(model: model)
        case "Ignored Apps": view = ExceptionsPreferencesView(model: model)
        case "About":
            let about = PreferencesPaneView(frame: NSRect(x: 0,y: 0,width: 420,height: 200))
            let icon = NSImageView(frame: NSRect(x: 20,y: 56,width: 128,height: 128))
            icon.image = NSImage(systemSymbolName: "paperclip", accessibilityDescription: "ClipCopy"); icon.imageScaling = .scaleProportionallyUpOrDown; about.addSubview(icon)
            let title = NSTextField(labelWithString: "ClipCopy"); title.font = .boldSystemFont(ofSize: 18)
            title.frame = NSRect(x: 160,y: 122,width: 240,height: 22); about.addSubview(title)
            let versionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0"
            let version = NSTextField(labelWithString: "Version " + versionNumber); version.font = .systemFont(ofSize: 12)
            version.frame = NSRect(x: 160,y: 102,width: 240,height: 16); about.addSubview(version)
            let copyright = NSTextField(labelWithString: "© MediaPublishing"); copyright.font = .systemFont(ofSize: 11)
            copyright.frame = NSRect(x: 160,y: 86,width: 240,height: 16); about.addSubview(copyright)
            let line = NSBox(frame: NSRect(x: 0,y: 33,width: 420,height: 1)); line.boxType = .separator; about.addSubview(line)
            for (name,x,width) in [("FAQ",7.0,61.0),("Fan Page",78.0,85.0),("Twitter",173.0,72.0),("ClipCopy",255.0,98.0)] {
                let button = NSButton(title: name, target: nil, action: nil); button.bezelStyle = .rounded
                button.frame = NSRect(x: x,y: 4,width: width,height: 25); button.isEnabled = false; about.addSubview(button)
            }
            view = about
        default: view = GeneralPreferencesView(model: model)
        }
        let top = window.frame.maxY
        let contentSize = view.frame.size
        window.contentView = view; window.setContentSize(contentSize)
        window.setFrameOrigin(NSPoint(x: window.frame.minX,y: top - window.frame.height))
        window.title = name; window.toolbar?.selectedItemIdentifier = .init(name)
    }
}

@MainActor private class PreferencesPaneView: NSView {
    override func draw(_ dirtyRect: NSRect) { NSColor.windowBackgroundColor.setFill(); bounds.fill() }
}

@MainActor private final class ClippingsPreferencesView: PreferencesPaneView, NSTableViewDataSource, NSTableViewDelegate {
    private let model: ClipModel
    private let table = NSTableView()
    private let confirm = NSButton(checkboxWithTitle: "Confirm before deleting", target: nil, action: nil)
    private var observation: AnyCancellable?
    init(model: ClipModel) {
        self.model = model; super.init(frame: NSRect(x: 0,y: 0,width: 420,height: 320))
        let scroll = NSScrollView(frame: NSRect(x: 20,y: 54,width: 380,height: 246))
        let column = NSTableColumn(identifier: .init("ClipColumn")); column.width = 360
        table.addTableColumn(column); table.headerView = nil; table.dataSource = self; table.delegate = self
        table.allowsMultipleSelection = true; table.rowHeight = 26; table.usesAlternatingRowBackgroundColors = true; table.intercellSpacing = .zero
        scroll.documentView = table; scroll.hasVerticalScroller = true; scroll.borderType = .bezelBorder; addSubview(scroll)
        let delete = NSButton(title: "Delete", target: self, action: #selector(deleteSelected)); delete.bezelStyle = .rounded
        delete.frame = NSRect(x: 20,y: 15,width: 80,height: 30); addSubview(delete)
        confirm.frame = NSRect(x: 110,y: 20,width: 290,height: 20); confirm.state = model.confirmBeforeDeleting ? .on : .off; confirm.target = self; confirm.action = #selector(changeConfirmation); addSubview(confirm)
        observation = model.objectWillChange.sink { [weak self] in DispatchQueue.main.async { self?.table.reloadData() } }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func numberOfRows(in tableView: NSTableView) -> Int { model.locked ? 0 : model.history.entries.count }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let label = NSTextField(labelWithString: model.history.entries[row].text.replacingOccurrences(of: "\n", with: " "))
        label.lineBreakMode = .byTruncatingTail; return label
    }
    @objc private func changeConfirmation() { model.confirmBeforeDeleting = confirm.state == .on }
    @objc private func deleteSelected() {
        let selected = table.selectedRowIndexes.compactMap { model.history.entries.indices.contains($0) ? model.history.entries[$0].id : nil }
        guard !selected.isEmpty else { return }
        if confirm.state == .on {
            let alert = NSAlert(); alert.messageText = "Delete Selected Clippings"
            alert.informativeText = selected.count == 1 ? "Are you sure you want to delete the selected clipping? This action cannot be undone." : "Are you sure you want to delete \(selected.count) selected clippings? This action cannot be undone."
            alert.addButton(withTitle: "Delete"); alert.addButton(withTitle: "Cancel")
            guard alert.runModal() == .alertFirstButtonReturn else { return }
        }
        model.deleteEntries(ids: Set(selected))
    }
}

@MainActor private final class ExceptionsPreferencesView: PreferencesPaneView, NSTableViewDataSource, NSTableViewDelegate {
    private struct AppRow { let name: String; let id: String?; let icon: NSImage? }
    private let model: ClipModel
    private var apps: [AppRow] = []
    private let table = NSTableView()
    init(model: ClipModel) {
        self.model = model; super.init(frame: NSRect(x: 0,y: 0,width: 420,height: 320))
        if model.isDemo { apps = [AppRow(name: "Test-Editor",id: "com.example.Editor",icon: nil),AppRow(name: "Test-Browser",id: "com.example.Browser",icon: nil)] }
        else {
            let roots = [URL(fileURLWithPath: "/Applications"), FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications")]
            for root in roots {
                for url in (try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? [] where url.pathExtension == "app" {
                    guard let id = Bundle(url: url)?.bundleIdentifier else { continue }
                    apps.append(AppRow(name: url.deletingPathExtension().lastPathComponent, id: id, icon: NSWorkspace.shared.icon(forFile: url.path)))
                }
            }
            for name in model.history.settings.excludedNames where !apps.contains(where: { $0.name == name }) { apps.append(AppRow(name: name,id: nil,icon: nil)) }
            apps.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
        let column = NSTableColumn(identifier: .init("app")); column.width = 360; table.addTableColumn(column)
        table.headerView = nil; table.rowHeight = 28; table.usesAlternatingRowBackgroundColors = true; table.dataSource = self; table.delegate = self
        let scroll = NSScrollView(frame: NSRect(x: 20,y: 20,width: 380,height: 280)); scroll.documentView = table; scroll.hasVerticalScroller = true; scroll.borderType = .bezelBorder; addSubview(scroll)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func numberOfRows(in tableView: NSTableView) -> Int { apps.count }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let app = apps[row]; let cell = NSView(frame: NSRect(x: 0,y: 0,width: 360,height: 28))
        let check = NSButton(checkboxWithTitle: "", target: self, action: #selector(toggleApp)); check.frame = NSRect(x: 5,y: 5,width: 20,height: 20); check.tag = row
        let mandatory = app.id.map { CapturePolicy.mandatoryIDs.contains($0) } ?? false
        check.state = (mandatory || app.id.map { model.history.settings.excludedBundleIDs.contains($0) } == true || model.history.settings.excludedNames.contains(app.name)) ? .on : .off
        check.isEnabled = !mandatory && !model.locked; cell.addSubview(check)
        let icon = NSImageView(frame: NSRect(x: 30,y: 3,width: 24,height: 24)); icon.image = app.icon; cell.addSubview(icon)
        let label = NSTextField(labelWithString: app.name); label.frame = NSRect(x: 62,y: 5,width: 290,height: 20); cell.addSubview(label)
        return cell
    }
    @objc private func toggleApp(_ check: NSButton) {
        let app = apps[check.tag]; var ids = model.history.settings.excludedBundleIDs; var names = model.history.settings.excludedNames
        if let id = app.id { ids.removeAll { $0 == id }; if check.state == .on { ids.append(id) } }
        names.removeAll { $0 == app.name }; if check.state == .on && app.id == nil { names.append(app.name) }
        model.applySettings(store: String(model.history.settings.storeLimit), display: String(model.history.settings.displayLimit), excludedIDs: ids, excludedNames: names)
        table.reloadData()
    }
}
