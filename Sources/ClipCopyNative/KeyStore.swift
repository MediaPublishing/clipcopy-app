import Foundation
import Security
import CryptoKit

public enum KeyError: Error { case unavailable, cannotCreate, malformed }

public enum KeyStore {
    private static let service = "com.mediapublishing.ClipCopy.history"
    private static var query: [String: Any] { [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: "archive-v1", kSecAttrSynchronizable as String: false] }
    public static func load(interactive: Bool = false) throws -> SymmetricKey {
        // The classic macOS keychain also needs this process-local switch;
        // kSecUseAuthenticationUI alone does not suppress its legacy dialogs.
        var previous = DarwinBoolean(true)
        SecKeychainGetUserInteractionAllowed(&previous)
        if !interactive { SecKeychainSetUserInteractionAllowed(false) }
        defer { SecKeychainSetUserInteractionAllowed(previous.boolValue) }
        var q = query; q[kSecReturnData as String] = true; q[kSecMatchLimit as String] = kSecMatchLimitOne
        q[kSecUseAuthenticationUI as String] = interactive ? kSecUseAuthenticationUIAllow : kSecUseAuthenticationUIFail
        var result: CFTypeRef?
        guard SecItemCopyMatching(q as CFDictionary, &result) == errSecSuccess else { throw KeyError.unavailable }
        guard let data = result as? Data, data.count == 32 else { throw KeyError.malformed }
        return SymmetricKey(data: data)
    }
    public static func createForNewArchive() throws -> SymmetricKey {
        // Never replace an existing key, including an inaccessible one.
        var probe = query; probe[kSecReturnAttributes as String] = true; probe[kSecUseAuthenticationUI as String] = kSecUseAuthenticationUIFail
        let status = SecItemCopyMatching(probe as CFDictionary, nil)
        guard status == errSecItemNotFound else { throw KeyError.cannotCreate }
        var app: SecTrustedApplication?
        guard SecTrustedApplicationCreateFromPath(nil, &app) == errSecSuccess, let app else { throw KeyError.cannotCreate }
        var access: SecAccess?
        guard SecAccessCreate("ClipCopy-Verlauf" as CFString, [app] as CFArray, &access) == errSecSuccess, let access else { throw KeyError.cannotCreate }
        let key = SymmetricKey(size: .bits256)
        var item = query
        item[kSecAttrLabel as String] = "ClipCopy: lokaler Verlauf"
        item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        item[kSecAttrAccess as String] = access
        item[kSecValueData as String] = key.withUnsafeBytes { Data($0) }
        guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else { throw KeyError.cannotCreate }
        return key
    }
}
