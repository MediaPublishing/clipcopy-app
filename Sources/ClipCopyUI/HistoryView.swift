import AppKit
import Combine
import SwiftUI
import ClipCopyCore

/// Compatibility wrapper; all live and demo windows use the same native view.
public struct HistoryView: NSViewRepresentable {
    let model: ClipModel
    let onSelected: () -> Void
    public init(model: ClipModel, onSelected: @escaping () -> Void = {}) { self.model = model; self.onSelected = onSelected }
    public func makeNSView(context: Context) -> HistoryPanelView { HistoryPanelView(model: model, onSelected: onSelected) }
    public func updateNSView(_ view: HistoryPanelView, context: Context) { view.reload() }
}

@MainActor public final class HistoryPanelView: NSView, NSTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate {
    public let searchField = NSTextField(frame: NSRect(x: 20, y: 263, width: 560, height: 50))
    public let scrollView = NSScrollView(frame: NSRect(x: 20, y: 10, width: 560, height: 250))
    public let table = NSTableView()
    private let model: ClipModel
    private let onSelected: () -> Void
    private var observation: AnyCancellable?
    private var entries: [ClipEntry] = []
    private var loading = false
    public init(model: ClipModel, onSelected: @escaping () -> Void = {}) {
        self.model = model; self.onSelected = onSelected
        super.init(frame: NSRect(x: 0, y: 0, width: 600, height: 325))
        wantsLayer = true; layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        searchField.font = .systemFont(ofSize: 32)
        searchField.delegate = self
        searchField.setAccessibilityLabel("Search clippings")
        addSubview(searchField)
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("clipping"))
        column.width = 545; table.addTableColumn(column)
        table.headerView = nil; table.rowHeight = 50; table.intercellSpacing = .zero
        table.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
        table.dataSource = self; table.delegate = self
        table.target = self; table.action = #selector(clicked)
        table.setAccessibilityLabel("Clippings list")
        scrollView.borderType = .bezelBorder; scrollView.hasVerticalScroller = true
        scrollView.documentView = table; addSubview(scrollView)
        observation = model.objectWillChange.sink { [weak self] in
            DispatchQueue.main.async { self?.reload() }
        }
        reload()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    public override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }
    public func reload() {
        loading = true
        entries = model.visible
        if searchField.stringValue != model.query { searchField.stringValue = model.query }
        table.reloadData()
        if let id = model.selectedID, let index = entries.firstIndex(where: { $0.id == id }) {
            table.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
            table.scrollRowToVisible(index)
        } else { table.deselectAll(nil) }
        loading = false
    }
    public func numberOfRows(in tableView: NSTableView) -> Int { entries.count }
    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = ClipRowView(entry: entries[row], index: row)
        return cell
    }
    public func tableViewSelectionDidChange(_ notification: Notification) {
        guard !loading else { return }
        model.selectedID = entries.indices.contains(table.selectedRow) ? entries[table.selectedRow].id : nil
    }
    public func controlTextDidChange(_ obj: Notification) {
        model.query = searchField.stringValue
        model.selectedID = model.visible.first?.id
        reload()
    }
    public func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        switch commandSelector {
        case #selector(NSResponder.moveDown(_:)): model.moveSelection(by: 1); reload(); return true
        case #selector(NSResponder.moveUp(_:)): model.moveSelection(by: -1); reload(); return true
        case #selector(NSResponder.insertNewline(_:)): activateSelection(); return true
        case #selector(NSResponder.cancelOperation(_:)): window?.close(); return true
        default: return false
        }
    }
    @objc private func clicked() { guard table.clickedRow >= 0 else { return }; model.selectedID = entries[table.clickedRow].id; activateSelection() }
    public func activateSelection() {
        if model.selectedID == nil { model.selectedID = entries.first?.id }
        if model.copySelected() { onSelected() }
    }
    public override func keyDown(with event: NSEvent) {
        if event.keyCode == 36 { activateSelection() }
        else if event.keyCode == 53 { window?.close() }
        else { super.keyDown(with: event) }
    }
}

@MainActor private final class ClipRowView: NSTableCellView {
    init(entry: ClipEntry, index: Int) {
        super.init(frame: NSRect(x: 0, y: 0, width: 547, height: 50))
        let title = NSTextField(labelWithString: entry.text.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "\r", with: " "))
        title.frame = NSRect(x: 41, y: 14, width: 448, height: 33)
        title.font = .systemFont(ofSize: 21); title.lineBreakMode = .byTruncatingTail
        title.autoresizingMask = [.width]; addSubview(title); textField = title
        let formatter = RelativeDateTimeFormatter(); formatter.unitsStyle = .full; formatter.locale = Locale(identifier: "en_US")
        let source = entry.sourceName ?? ""
        let subtitle = NSTextField(labelWithString: "Added \(formatter.localizedString(for: entry.createdAt, relativeTo: Date()))" + (source.isEmpty ? "" : " via \(source)"))
        subtitle.frame = NSRect(x: 41, y: 3, width: 448, height: 15)
        subtitle.font = .systemFont(ofSize: 12); subtitle.textColor = .secondaryLabelColor
        subtitle.lineBreakMode = .byTruncatingTail; subtitle.autoresizingMask = [.width]; addSubview(subtitle)
        let image = NSImageView(frame: NSRect(x: 0, y: 0, width: 35, height: 50))
        if let sourceID = entry.sourceID, let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: sourceID) {
            image.image = NSWorkspace.shared.icon(forFile: url.path)
        } else { image.image = NSImage(named: NSImage.applicationIconName) }
        image.imageScaling = .scaleProportionallyDown; addSubview(image)
        let shortcut = NSTextField(labelWithString: index < 9 ? String(index + 1) : "")
        shortcut.frame = NSRect(x: 495, y: 6, width: 51, height: 39)
        shortcut.font = .systemFont(ofSize: 26); shortcut.alignment = .right
        shortcut.autoresizingMask = [.minXMargin]; addSubview(shortcut)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
