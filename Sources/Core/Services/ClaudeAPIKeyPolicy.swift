import Foundation

/// Claude API キーの扱い（モック判定・プレースホルダー定義）。
/// 実キーは `Secrets.swift`（gitignore）側のみに置く。
enum ClaudeAPIKeyPolicy {
    /// `Secrets.swift.example` のデフォルト値と一致させること。
    static let placeholderValue = "YOUR_CLAUDE_API_KEY_HERE"

    static func shouldUseMockAPI(for key: String) -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || trimmed == placeholderValue
    }
}
