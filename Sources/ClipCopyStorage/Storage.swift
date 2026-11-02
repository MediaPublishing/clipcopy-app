import Foundation
import CryptoKit
import CSQLite
import ClipCopyCore
private let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

public struct ArchiveState: Codable, Equatable, Sendable {
    public var entries: [ClipEntry]
    public var settings: ClipSettings
    public var importedAt: Date?
    public init(entries: [ClipEntry] = [], settings: ClipSettings = ClipSettings(), importedAt: Date? = nil) { self.entries = entries; self.settings = settings; self.importedAt = importedAt }
}

public enum StorageError: Error, LocalizedError, Equatable {
    case unavailable, invalid, authenticationFailed, corrupt, missingHeader, io
    public var errorDescription: String? { switch self { case .unavailable: "Speicher nicht verfügbar."; case .invalid: "Ungültiger Speicher."; case .authenticationFailed: "Speicher konnte nicht geöffnet werden."; case .corrupt: "Speicher ist beschädigt."; case .missingHeader: "Speicher-Header fehlt."; case .io: "Speicherfehler." } }
}

public final class EncryptedStore {
    private let db: OpaquePointer; private let key: SymmetricKey
    public init(url: URL, key: SymmetricKey) throws {
        self.key = key
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: url.path)
        var p: OpaquePointer?
        guard sqlite3_open_v2(url.path, &p, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE, nil) == SQLITE_OK, let opened = p else {
            if let p { sqlite3_close(p) }
            throw StorageError.unavailable
        }
        db = opened
        try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
        sqlite3_busy_timeout(db, 3000)
        guard exec("PRAGMA journal_mode=WAL; PRAGMA synchronous=FULL; CREATE TABLE IF NOT EXISTS records (id TEXT PRIMARY KEY, payload BLOB NOT NULL);", db) else { sqlite3_close(db); throw StorageError.io }
    }
    deinit { sqlite3_close(db) }
    public func load() throws -> ArchiveState {
        guard let header = try read(id: "__header") else { throw StorageError.missingHeader }
        let envelope: Header; do { envelope = try decode(header) } catch { throw StorageError.authenticationFailed }
        var out: [ClipEntry] = []; var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "SELECT id,payload FROM records WHERE id != '__header' ORDER BY rowid", -1, &stmt, nil) == SQLITE_OK else { throw StorageError.io }; defer { sqlite3_finalize(stmt) }
        var orderedIDs: [String] = []
        var step = sqlite3_step(stmt)
        while step == SQLITE_ROW {
            guard let idp = sqlite3_column_text(stmt, 0), let blob = sqlite3_column_blob(stmt, 1) else { throw StorageError.corrupt }
            let id = String(cString: idp)
            let data = Data(bytes: blob, count: Int(sqlite3_column_bytes(stmt, 1)))
            do {
                let entry: ClipEntry = try decode(data, recordID: id)
                guard entry.id.uuidString == id else { throw StorageError.corrupt }
                out.append(entry); orderedIDs.append(id)
            } catch { throw StorageError.authenticationFailed }
            step = sqlite3_step(stmt)
        }
        guard step == SQLITE_DONE else { throw StorageError.io }
        guard orderedIDs == envelope.orderedIDs else { throw StorageError.corrupt }
        _ = try envelope.settings.validated()
        return ArchiveState(entries: out, settings: envelope.settings, importedAt: envelope.importedAt)
    }
    public func save(_ state: ArchiveState) throws {
        try state.settings.validated(); guard exec("BEGIN IMMEDIATE", db) else { throw StorageError.io }
        do { guard exec("DELETE FROM records", db) else { throw StorageError.io }; try write(id: "__header", value: Header(settings: state.settings, importedAt: state.importedAt, orderedIDs: state.entries.map { $0.id.uuidString })); for e in state.entries { try write(id: e.id.uuidString, value: e) }; guard exec("COMMIT", db) else { throw StorageError.io } } catch { _ = exec("ROLLBACK", db); if let e = error as? StorageError { throw e }; throw StorageError.io }
    }
    private struct Header: Codable { let settings: ClipSettings; let importedAt: Date?; let orderedIDs: [String] }
    private func encode<T: Encodable>(_ value: T, recordID: String) throws -> Data { let plain = try JSONEncoder().encode(value); let box = try AES.GCM.seal(plain, using: key, authenticating: Data((recordID + "|1").utf8)); guard let combined = box.combined else { throw StorageError.io }; return combined }
    private func decode<T: Decodable>(_ data: Data, recordID: String = "__header") throws -> T { let box = try AES.GCM.SealedBox(combined: data); let plain = try AES.GCM.open(box, using: key, authenticating: Data((recordID + "|1").utf8)); return try JSONDecoder().decode(T.self, from: plain) }
    private func read(id: String) throws -> Data? {
        var s: OpaquePointer?
        guard sqlite3_prepare_v2(db, "SELECT payload FROM records WHERE id=?", -1, &s, nil) == SQLITE_OK else { throw StorageError.io }
        defer { sqlite3_finalize(s) }
        guard sqlite3_bind_text(s, 1, id, -1, transient) == SQLITE_OK else { throw StorageError.io }
        let step = sqlite3_step(s)
        if step == SQLITE_DONE { return nil }
        guard step == SQLITE_ROW else { throw StorageError.io }
        guard let p = sqlite3_column_blob(s, 0) else { throw StorageError.corrupt }
        return Data(bytes: p, count: Int(sqlite3_column_bytes(s, 0)))
    }
    private func write<T: Encodable>(id: String, value: T) throws {
        let data = try encode(value, recordID: id)
        guard data.count <= Int32.max else { throw StorageError.io }
        var s: OpaquePointer?
        guard sqlite3_prepare_v2(db, "INSERT INTO records(id,payload) VALUES(?,?)", -1, &s, nil) == SQLITE_OK else { throw StorageError.io }
        defer { sqlite3_finalize(s) }
        guard sqlite3_bind_text(s, 1, id, -1, transient) == SQLITE_OK else { throw StorageError.io }
        let bound = data.withUnsafeBytes { sqlite3_bind_blob(s, 2, $0.baseAddress, Int32(data.count), transient) }
        guard bound == SQLITE_OK, sqlite3_step(s) == SQLITE_DONE else { throw StorageError.io }
    }
}
private func exec(_ sql: String, _ db: OpaquePointer) -> Bool { sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK }
