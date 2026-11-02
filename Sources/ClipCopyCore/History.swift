import Foundation

public struct ClipEntry: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var text: String
    public var sourceID: String?
    public var sourceName: String?
    public var createdAt: Date
    public var lastCapturedAt: Date

    public init(id: UUID = UUID(), text: String, sourceID: String? = nil, sourceName: String? = nil,
                createdAt: Date = Date(), lastCapturedAt: Date? = nil) {
        self.id = id; self.text = text; self.sourceID = sourceID; self.sourceName = sourceName
        self.createdAt = createdAt; self.lastCapturedAt = lastCapturedAt ?? createdAt
    }
}

public enum SettingsError: Error { case invalidLimit }

public struct ClipSettings: Codable, Equatable, Sendable {
    public var storeLimit: Int
    public var displayLimit: Int
    public var excludedBundleIDs: [String]
    public var excludedNames: [String]
    public var recordingEnabled: Bool

    public init(storeLimit: Int = 1000, displayLimit: Int = 1000, excludedBundleIDs: [String] = [],
                excludedNames: [String] = [], recordingEnabled: Bool = false) {
        self.storeLimit = storeLimit; self.displayLimit = displayLimit
        self.excludedBundleIDs = excludedBundleIDs; self.excludedNames = excludedNames
        self.recordingEnabled = recordingEnabled
    }

    @discardableResult public func validated() throws -> Self {
        guard storeLimit > 0, displayLimit > 0, displayLimit <= storeLimit else { throw SettingsError.invalidLimit }
        return self
    }
}

public struct History: Sendable {
    public private(set) var entries: [ClipEntry]
    public private(set) var settings: ClipSettings

    /// Import and restore preserve duplicates and source order.
    public init(entries: [ClipEntry] = [], settings: ClipSettings = ClipSettings()) {
        self.settings = settings
        self.entries = Array(entries.prefix(max(0, settings.storeLimit)))
    }

    @discardableResult public mutating func ingest(_ entry: ClipEntry) -> Bool {
        guard !entry.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        if let i = entries.firstIndex(where: { $0.text.utf8.elementsEqual(entry.text.utf8) }) {
            var existing = entries.remove(at: i)
            existing.lastCapturedAt = entry.lastCapturedAt
            existing.sourceID = entry.sourceID; existing.sourceName = entry.sourceName
            entries.insert(existing, at: 0)
            return false
        }
        entries.insert(entry, at: 0)
        entries = Array(entries.prefix(settings.storeLimit))
        return true
    }

    public mutating func updateSettings(_ value: ClipSettings) throws {
        settings = try value.validated()
        entries = Array(entries.prefix(settings.storeLimit))
    }
    public func entry(id: UUID) -> ClipEntry? { entries.first { $0.id == id } }
    public mutating func remove(id: UUID) { entries.removeAll { $0.id == id } }
    public mutating func removeAll() { entries.removeAll() }

    public func visibleEntries(query: String) -> [ClipEntry] {
        if query.isEmpty { return Array(entries.prefix(settings.displayLimit)) }
        return entries.filter { $0.text.range(of: query, options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "de_DE")) != nil }
    }
}
