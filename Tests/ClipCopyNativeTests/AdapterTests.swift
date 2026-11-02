import Foundation
import AppKit
import ClipCopyCore
import ClipCopyUI
import ClipCopyNative

@MainActor final class AdapterTests: LocalTestCase {
    func testKeyboardSelectionMovesWithinFilteredResultsAndStopsAtEdges() {
        let model = ClipModel.demo()
        model.selectedID = nil
        model.moveSelection(by: 1)
        expectEqual(model.selectedID, model.visible.first?.id)
        model.moveSelection(by: 1)
        expectEqual(model.selectedID, model.visible[1].id)
        model.moveSelection(by: 99)
        expectEqual(model.selectedID, model.visible.last?.id)
        model.moveSelection(by: -99)
        expectEqual(model.selectedID, model.visible.first?.id)
        model.query = "kein-treffer-xyz"
        model.moveSelection(by: 1)
        expectNil(model.selectedID)
    }
    func testAlternativePlainTextRepresentationIsCaptured() {
        let board = NSPasteboard.withUniqueName()
        defer { board.releaseGlobally() }
        let item = NSPasteboardItem()
        item.setString("Alternative synthetic text", forType: .init("public.plain-text"))
        expectTrue(board.writeObjects([item]))
        expectEqual(PasteboardAdapter(board: board).capture(policy: CapturePolicy(), activeID: "com.example.fixture", activeName: "Fixture", paused: false, locked: false, stillValid: { true }), "Alternative synthetic text")
    }
    func testInvalidDisplayLimitKeepsConfirmedSettings() {
        let model = ClipModel.demo()
        model.applySettings(store: "1000", display: "1001", excludedIDs: [], excludedNames: [])
        expectEqual(model.history.settings.displayLimit, 1000)
        expectFalse(model.message == "Einstellungen gespeichert.")
        model.applySettings(store: "10", display: "1000", excludedIDs: [], excludedNames: [])
        expectEqual(model.history.settings.storeLimit, 10)
        expectEqual(model.history.settings.displayLimit, 10)
    }
    func testNamedPasteboardRoundtripAndOwnCopiesAreIgnored() async throws {
        await MainActor.run {
            let board = NSPasteboard.withUniqueName()
            defer { board.releaseGlobally() }
            let adapter = PasteboardAdapter(board: board)
            expectTrue(adapter.write("Synthetic äöü\nsecond line"))
            expectEqual(board.string(forType: .string), "Synthetic äöü\nsecond line")
            expectTrue(board.types?.contains(.init(CapturePolicy.ownedType)) == true)
            expectNil(adapter.capture(policy: CapturePolicy(), activeID: "com.example.fixture", activeName: "Fixture", paused: false, locked: false, stillValid: { true }))
        }
    }
    func testNamedPasteboardSensitiveAndChangingSourceAreRejected() async throws {
        await MainActor.run {
            let board = NSPasteboard.withUniqueName()
            defer { board.releaseGlobally() }
            let adapter = PasteboardAdapter(board: board)
            let item = NSPasteboardItem()
            item.setString("Synthetic concealed fixture", forType: .string)
            item.setData(Data(), forType: .init("org.nspasteboard.ConcealedType"))
            board.writeObjects([item])
            expectNil(adapter.capture(policy: CapturePolicy(), activeID: "com.example.fixture", activeName: "Fixture", paused: false, locked: false, stillValid: { true }))
            board.clearContents(); board.setString("Normal fixture", forType: .string)
            expectEqual(adapter.capture(policy: CapturePolicy(), activeID: "com.example.fixture", activeName: "Fixture", paused: false, locked: false, stillValid: { true }), "Normal fixture")
            expectNil(adapter.capture(policy: CapturePolicy(), activeID: "com.example.fixture", activeName: "Fixture", paused: false, locked: false, stillValid: { false }))
        }
    }
    func testDemoSelectionDeletedAndProtectedStateCannotCopy() async throws {
        await MainActor.run {
            let model = ClipModel.demo()
            model.query = "Grusse"; model.selectedID = model.visible.first?.id
            expectTrue(model.copySelected()); model.pasteTest()
            expectEqual(model.testResult, "Grüße aus dem Testlabor\nZweite Zeile")
            model.clearHistory()
            expectFalse(model.copySelected()); expectTrue(model.testBuffer.isEmpty)
            model.protect(); expectTrue(model.visible.isEmpty); expectFalse(model.copySelected())
        }
    }
}
