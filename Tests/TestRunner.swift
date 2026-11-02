import Foundation

// Standalone assertions because this Mac has Command Line Tools without XCTest.
// Every failure terminates with a nonzero exit code. Fixtures are synthetic only.
class LocalTestCase {
    private var cleanup: [() throws -> Void] = []
    func addTeardownBlock(_ block: @escaping () throws -> Void) { cleanup.append(block) }
    func tearDown() throws { for block in cleanup.reversed() { try block() }; cleanup.removeAll() }
}
func expectTrue(_ condition: @autoclosure () -> Bool, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
    if !condition() { fatalError("Expected true. \(message)", file: file, line: line) }
}
func expectFalse(_ condition: @autoclosure () -> Bool, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
    if condition() { fatalError("Expected false. \(message)", file: file, line: line) }
}
func expectEqual<T: Equatable>(_ actual: @autoclosure () throws -> T, _ expected: @autoclosure () throws -> T, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
    do { if try actual() != expected() { fatalError("Equality assertion failed", file: file, line: line) } }
    catch { fatalError("Unexpected error", file: file, line: line) }
}
func expectNil<T>(_ value: @autoclosure () -> T?, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
    if value() != nil { fatalError("Expected nil. \(message)", file: file, line: line) }
}
func expectThrows<T>(_ expression: @autoclosure () throws -> T, file: StaticString = #file, line: UInt = #line) {
    do { _ = try expression() } catch { return }
    fatalError("Expected an error", file: file, line: line)
}

@main struct TestRunner {
    @MainActor static func main() async throws {
        let core = ClipCopyCoreTests()
        core.testEntryDefaultsAndWhitespaceRules()
        core.testIngestDeduplicatesUTF8AndKeepsNewestAtFront()
        core.testImportKeepsDuplicatesButCapsStoreLimitAndOldest()
        core.testVisibleEntriesPrefixAndSearch()
        try core.testSettingsValidationAndUpdateLimit()
        core.testMutationsAndLookup()
        core.testCapturePolicyRejectsWithoutCallingReader()
        core.testCapturePolicyRequiresExactlyOnePlainTextAndKnownForeground()
        core.testCapturePolicyRejectsPausedLockedOrWrongCount()
        core.testRichTextWithExplicitPlainRepresentationIsAccepted()
        let storage = StorageTests()
        try storage.testEncryptedArchiveReopensExactlyWithoutTTL()
        try storage.testWrongKeyAndTamperFailWithoutReset()
        try storage.testFailedTransactionPreservesConfirmedState()
        try storage.testDeletedCiphertextIsNotAcceptedAsCompleteHistory()
        try storage.tearDown()
        let adapter = AdapterTests()
        adapter.testKeyboardSelectionMovesWithinFilteredResultsAndStopsAtEdges()
        adapter.testAlternativePlainTextRepresentationIsCaptured()
        adapter.testInvalidDisplayLimitKeepsConfirmedSettings()
        try await adapter.testNamedPasteboardRoundtripAndOwnCopiesAreIgnored()
        try await adapter.testNamedPasteboardSensitiveAndChangingSourceAreRejected()
        try await adapter.testDemoSelectionDeletedAndProtectedStateCannotCopy()
        let ui = OriginalUITests()
        ui.testNativeMenuCopiesThroughItsActionAndKeepsOriginalOrder()
        ui.testNativeSearchReturnAndGeometry()
        ui.testNativeMenuEmptyAndTruncation()
        ui.testPreferencesLoadAndDeleteKeepBackendSafety()
        print("{\"passedTests\":24,\"fixtures\":\"synthetic-only\",\"realClipboardRead\":false}")
    }
}
