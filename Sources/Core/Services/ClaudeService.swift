import Foundation

actor ClaudeService {
    private let apiKey: String
    private let endpoint = "https://api.anthropic.com/v1/messages"
    private let model = "claude-sonnet-4-6"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    /// `userMessage` には日記・「今日できたこと」リストなど、ユーザーが記録した全文を渡す。
    func generateFeedback(userMessage: String, mode: FeedbackMode) async throws -> String {
        let systemPrompt = systemPrompt(for: mode)
        let requestBody: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userMessage]
            ]
        ]

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeError.apiError("レスポンスが不正です")
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "unknown"
            throw ClaudeError.apiError("HTTP \(httpResponse.statusCode): \(body)")
        }

        let result = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        return result.content.first?.text ?? ""
    }

    private func systemPrompt(for mode: FeedbackMode) -> String {
        let base = """
        あなたは「エールミー」というアプリの優しいAIです。
        ユーザーが記録した「日記」と「今日できたこと（アプリで選んだ項目）」を含むメッセージに対してフィードバックをします。
        絶対に守るルール:
        - 批判・否定・比較は一切しない
        - 「でも」「しかし」「もっと〜すべき」は使わない
        - 日記と「できたこと」の両方に触れられるときは、具体的に言及する
        - 自然な日本語で、温かく、親しみやすいトーンで
        - 医療・診断・治療の断定をしない
        - 危機的な内容（自傷/他害/希死念慮）が示唆される場合は、断定や命令ではなく「今すぐ身近な人や地域の相談窓口に繋がってほしい」と短く安全配慮の一文を添える
        - 返答は2〜6文で簡潔にする
        """

        switch mode {
        case .praise:
            return base + "\n\n必ず3つ以上の具体的な褒めポイントを文脈から発見して伝えてください。"
        case .empathy:
            return base + "\n\n評価もアドバイスもせず、ただ「わかるよ」と寄り添ってください。静かで穏やかなトーンで。"
        case .advice:
            return base + "\n\nまず褒めた上で、一つだけ小さくて実践しやすいアドバイスをやさしく伝えてください。"
        case .courage:
            return base + "\n\n一歩踏み出せるような背中を押す言葉を伝えてください。押しつけがましくなく、自然に。"
        }
    }
}

struct ClaudeResponse: Decodable {
    let content: [ContentBlock]

    struct ContentBlock: Decodable {
        let text: String
    }
}

enum ClaudeError: Error, LocalizedError {
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .apiError(let message): return message
        }
    }
}
