# App Store 審査メモ・スクショ用（エールミー / YellMe）

App Store Connect の **App 審査情報 → メモ** に貼り付けられる文面と、**スクリーンショット**で撮るとよい画面の一覧です。

---

## 審査メモ（日本語・そのまま貼り付け可）

```
【ログイン】
・初回起動でオンボーディング後、Sign in with Apple でログインしてください。

【アプリ内課金（自動更新サブスクリプション）】
・Premium（月額）の購入・購入の復元は、画面下のタブ「マイページ」を開き、
  スクロールして「プラン」セクションから行ってください。
・商品 ID: com.takahiro.yellme.premium.monthly
・課金のテストは Sandbox アカウントを利用できます。

【プライバシー・規約】
・同じ「マイページ」内の「プラン」に、プライバシーポリシーと利用規約のリンクがあります。
```

## Review notes (English, paste into App Store Connect)

```
Sign-in:
- Complete onboarding on first launch, then sign in with Sign in with Apple.

In-App Purchase (auto-renewing subscription):
- To purchase or restore Premium (monthly), open the bottom tab "マイページ" (Profile),
  scroll to the "プラン" (Plan) section, and use "Premiumにアップグレード" or "購入を復元".
- Product ID: com.takahiro.yellme.premium.monthly
- You may test purchases using a Sandbox Apple ID (Settings → App Store → Sandbox Account).

Legal links:
- Privacy Policy and Terms links are shown in the Plan section on マイページ.
```

---

## スクリーンショットで撮影するとよい画面（審査・ストア用）

実機またはシミュレータで **6.7 / 6.5 / 5.5 インチ** など、App Store Connect が要求するサイズに合わせてキャプチャしてください。

| # | 画面 | 内容のポイント |
|---|------|----------------|
| 1 | **いま**（ホーム） | 日付・コンパニオン・記録 UI。Free のとき **Premium 案内バナー**（ピンク枠）が写ると課金導線の説明と整合します。 |
| 2 | **マイページ** タブ | 上部のプロフィールと、**「プラン」見出し**・現在の Free/Premium 表示。 |
| 3 | **マイページ → プラン**（スクロール） | **「Premiumにアップグレード」**・**「購入を復元」**・**プライバシーポリシー / 利用規約** のリンクが写る範囲。 |
| 4 | **きろく** | 記録一覧または空状態。 |
| 5 | （任意）**購入確認** | StoreKit のシートが出た画面（Sandbox で撮影）。 |

---

## 実装メモ（開発者向け）

- 課金 UI は `ProfileView` の `subscriptionSection` に実装済み。
- メイン `TabView` に **「マイページ」** タブを追加し、審査員がタブバーから直接開けるようにしている。
- **きろく** 一覧下部の **「マイページ（プラン・設定）」** からも同一画面へ遷移可能。
