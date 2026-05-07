import Foundation

enum MockData {
    /// 互換用（日記本文のみ）
    static func mockFeedback(mode: FeedbackMode, content: String) -> String {
        mockFeedback(mode: mode, userMessage: content)
    }

    /// 日記＋「できたこと」ラベルを含むユーザー文面を想定したモック返答。
    static func mockFeedback(mode: FeedbackMode, userMessage: String) -> String {
        _ = userMessage
        switch mode {
        case .praise:
            return """
            読んでいて、いくつもキラリと光るところがありました✨

            まず、それを言葉にして書き出せたこと自体がすごいです。感じたことを整理して表現するのって、実は簡単じゃないんですよ。

            それから、その状況での行動や気持ちの動き方が、あなたらしさを感じさせます。無理せず自分のペースで向き合っていますよね。

            今日も一日、お疲れさまでした。こういう積み重ねが、きっとあなたの力になっています。
            """
        case .empathy:
            return """
            そうか、そんな日だったんだね。

            それは大変だったね。よく話してくれました。

            ただここにいるよ。それだけ伝えたくて。
            """
        case .advice:
            return """
            今日のこと、ちゃんと向き合えていますね。それだけで十分すごいです。

            一つだけ、もし良かったら——
            今日感じたことを、明日の朝もう一度読み返してみてください。夜と朝では、同じ言葉でも違って見えることがあります。新しい気づきが生まれるかもしれません。
            """
        case .courage:
            return """
            読んでいて、あなたの中にある力を感じました。

            完璧じゃなくていい。今日のあなたのまま、一歩だけ踏み出してみてください。その一歩が、明日のあなたを少し変えてくれるはずです。

            応援しています！
            """
        }
    }
}
