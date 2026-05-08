import Foundation
import Security

/// Claude API キーの保存先。Keychain を優先し、未保存なら `Secrets.swift` を参照する。
enum ClaudeAPIKeyStore {
    private static let service = "com.takahiro.yellme"
    private static let account = "claudeAnthropicAPIKey"

    /// Keychain → `Secrets.claudeAPIKey` の順で解決する。
    static func resolvedKey() -> String {
        if let fromKeychain = readKey() {
            let trimmed = fromKeychain.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }
        return Secrets.claudeAPIKey
    }

    static func readKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseDataProtectionKeychain as String: true
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    static func saveKey(_ key: String) -> Bool {
        guard !ClaudeAPIKeyPolicy.shouldUseMockAPI(for: key) else { return false }
        _ = deleteKey()
        guard let data = key.data(using: .utf8) else { return false }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecUseDataProtectionKeychain as String: true
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    @discardableResult
    static func deleteKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecUseDataProtectionKeychain as String: true
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    enum SaveFromSecretsResult {
        case success
        case rejectedPlaceholder
        case keychainError
    }

    /// 現在 `Secrets.swift` の値を Keychain にコピーする（プレースホルダーは拒否）。
    static func saveCurrentSecretsKeyToKeychain() -> SaveFromSecretsResult {
        let key = Secrets.claudeAPIKey
        if ClaudeAPIKeyPolicy.shouldUseMockAPI(for: key) { return .rejectedPlaceholder }
        return saveKey(key) ? .success : .keychainError
    }
}
