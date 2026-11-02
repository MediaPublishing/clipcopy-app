import Foundation
import CryptoKit
import CSQLite
import ClipCopyCore
import ClipCopyStorage

@MainActor final class StorageTests: LocalTestCase {
    private func temporaryURL(_ name: String = "history.sqlite") throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("ClipCopyTests-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: dir) }
        return dir.appendingPathComponent(name)
    }
    func testEncryptedArchiveReopensExactlyWithoutTTL() throws {
        let url = try temporaryURL(), key = SymmetricKey(size: .bits256)
        let entries = [ClipEntry(text: "CANARY-ONLY-SYNTHETIC-äöü", sourceName: "SYNTHETIC-APP", createdAt: Date(timeIntervalSince1970: 1)), ClipEntry(text: "CANARY-ONLY-SYNTHETIC-äöü")]
        let state = ArchiveState(entries: entries, settings: ClipSettings(excludedNames: ["Test-Ausnahme"]), importedAt: Date(timeIntervalSince1970: 12345))
        do { let store = try EncryptedStore(url: url, key: key); try store.save(state); expectEqual(try store.load(), state) }
        let reopened = try EncryptedStore(url: url, key: key)
        expectEqual(try reopened.load(), state)
        for file in try FileManager.default.contentsOfDirectory(at: url.deletingLastPathComponent(), includingPropertiesForKeys: nil) {
            let bytes = try Data(contentsOf: file)
            expectNil(bytes.range(of: Data("CANARY-ONLY-SYNTHETIC".utf8)))
            expectNil(bytes.range(of: Data("SYNTHETIC-APP".utf8)))
            expectNil(bytes.range(of: Data("Test-Ausnahme".utf8)))
        }
    }
    func testWrongKeyAndTamperFailWithoutReset() throws {
        let url = try temporaryURL(), key = SymmetricKey(size: .bits256)
        let state = ArchiveState(entries: [ClipEntry(text: "Fixture only")])
        do { let store = try EncryptedStore(url: url, key: key); try store.save(state) }
        do { let wrong = try EncryptedStore(url: url, key: SymmetricKey(size: .bits256)); expectThrows(try wrong.load()) }
        do { let correct = try EncryptedStore(url: url, key: key); expectEqual(try correct.load(), state) }
        try execute("UPDATE records SET payload=x'00' WHERE id != '__header'", url)
        let damaged = try EncryptedStore(url: url, key: key)
        expectThrows(try damaged.load())
    }
    func testFailedTransactionPreservesConfirmedState() throws {
        let url = try temporaryURL(), store = try EncryptedStore(url: url, key: SymmetricKey(size: .bits256))
        let original = ArchiveState(entries: [ClipEntry(text: "Confirmed fixture")])
        try store.save(original)
        let id = UUID()
        expectThrows(try store.save(ArchiveState(entries: [ClipEntry(id: id,text: "A"),ClipEntry(id: id,text: "B")])))
        expectEqual(try store.load(), original)
    }
    func testDeletedCiphertextIsNotAcceptedAsCompleteHistory() throws {
        let url = try temporaryURL(), key = SymmetricKey(size: .bits256)
        let first = ClipEntry(text: "Synthetic first"), second = ClipEntry(text: "Synthetic second")
        do { let store = try EncryptedStore(url: url, key: key); try store.save(ArchiveState(entries: [first, second])) }
        try execute("DELETE FROM records WHERE id='" + first.id.uuidString + "'", url)
        let reopened = try EncryptedStore(url: url, key: key)
        expectThrows(try reopened.load())
    }
    private func execute(_ sql: String, _ url: URL) throws {
        var db: OpaquePointer?
        guard sqlite3_open(url.path, &db) == SQLITE_OK else { throw StorageError.io }
        defer { sqlite3_close(db) }
        guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else { throw StorageError.io }
    }
}
