import Foundation

enum MockData {
    /// 互換用（日記本文のみ）
    static func mockFeedback(mode: FeedbackMode, content: String) -> String {
        mockFeedback(mode: mode, userMessage: content)
    }

    /// 日記＋「できたこと」ラベルを含むユーザー文面を想定したモック返答。
    static func mockFeedback(mode: FeedbackMode, userMessage: String) -> String {
        let snippet = Self.diarySnippet(from: userMessage) ?? "今日の記録"
        switch mode {
        case .praise:
            return """
            「\(snippet)」と書いてくれたところから、いくつもキラリと光るところがありました。

            まず、それを言葉にして書き出せたこと自体がすごいです。感じたことを整理して表現するのって、実は簡単じゃないんですよ。

            それから、その状況での行動や気持ちの動き方が、あなたらしさを感じさせます。無理せず自分のペースで向き合っていますよね。

            今日も一日、お疲れさまでした。こういう積み重ねが、きっとあなたの力になっています。
            """
        case .empathy:
            return """
            「\(snippet)」のくだりを読んで、そんな一日だったんだねと感じました。

            それは大変だったね。よく話してくれました。

            ただここにいるよ。それだけ伝えたくて。
            """
        case .advice:
            return """
            「\(snippet)」と書いてくれた内容、ちゃんと向き合えていますね。それだけで十分すごいです。

            一つだけ、もし良かったら——
            今日感じたことを、明日の朝もう一度読み返してみてください。夜と朝では、同じ言葉でも違って見えることがあります。新しい気づきが生まれるかもしれません。
            """
        case .courage:
            return """
            「\(snippet)」から、あなたの中にある力を感じました。

            完璧じゃなくていい。今日のあなたのまま、一歩だけ踏み出してみてください。その一歩が、明日のあなたを少し変えてくれるはずです。

            応援しています！
            """
        }
    }

    /// `buildUserMessage` 形式の文字列から日記ブロックの先頭を抜き出す（モック用）。
    private static func diarySnippet(from userMessage: String, maxLen: Int = 72) -> String? {
        guard let marker = userMessage.range(of: "【日記】") else { return nil }
        let tail = userMessage[marker.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
        guard let winsStart = tail.range(of: "【今日できた") else {
            return normalizedDiarySnippet(String(tail), maxLen: maxLen)
        }
        let block = String(tail[..<winsStart.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        return normalizedDiarySnippet(block, maxLen: maxLen)
    }

    private static func normalizedDiarySnippet(_ block: String, maxLen: Int) -> String? {
        if block.isEmpty || block == "（未入力）" { return nil }
        let singleLine = block.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        if singleLine.count <= maxLen { return singleLine }
        let idx = singleLine.index(singleLine.startIndex, offsetBy: maxLen)
        return String(singleLine[..<idx]) + "…"
    }
}
