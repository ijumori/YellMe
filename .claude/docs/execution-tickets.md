# 実行用チケット一覧（YellMe）

個人記録アプリ方針（SNS要素なし）を前提にした実行チケット。

## P0（MVP成立に必須）

### PROJ-001 要件凍結（個人記録アプリ方針）
- 目的: SNS要素なしを正式合意
- 完了条件: README/要件書に「非対応: フォロー/公開投稿/リアクション」明記
- 見積: 0.5d

### HOME-001 日次記録フロー安定化
- 目的: 記録入力 -> AI返答 -> 保存までを確実化
- 完了条件: 成功/失敗/通信不安定時のUI分岐が明確
- 見積: 1.5d

### SYNC-001 Firestore同期整合（ローカル優先）
- 目的: ローカル保存とクラウド同期の齟齬防止
- 完了条件: 起動時マージ、競合時updatedAt優先、非致命エラー表示
- 見積: 1.5d

### COMP-001 コンパニオン進化ロジック検証
- 目的: XP・段階遷移・ストリークの一貫性
- 完了条件: 境界値テスト（進化閾値、日跨ぎ）合格
- 見積: 1d

### HIST-001 履歴一覧/詳細の完成
- 目的: 振り返り体験の完成
- 完了条件: 月別一覧、日次詳細、空状態表示
- 見積: 1d

### SEC-001 Firestore/Storage Rules本番前検証
- 目的: 本人データのみアクセス可を保証
- 完了条件: 未ログイン/他UID操作が拒否される確認ログ
- 見積: 1d

## P0受け入れ条件（固定）

### PROJ-001
- READMEに「個人記録アプリ（SNS非対応）」が明記されている
- `posts/*` と `follows/*` がFirestore Rulesで無効化されている
- チーム運営ドキュメント（憲章/SOP）が参照可能
- 状態: Done（2026-05-07）

### HOME-001
- 「記録する -> AI返答 -> 保存」が1フローで完了する
- API失敗時にユーザー向けエラーメッセージが表示される
- 入力不足/回数上限時の送信制御がUIで明確
- 状態: Done（2026-05-07）

### SYNC-001
- 起動時にFirestore取り込み後、ローカルとマージされる
- 衝突時は `updatedAt` が新しいデータを採用する
- クラウド保存失敗でもローカル保存は維持される
- 状態: Done（2026-05-07）

### COMP-001
- XP境界値で進化段階が正しく切り替わる
- 連続日数が日跨ぎで正しく更新される
- 休止復帰時のWelcome Back表示が1回のみ
- 状態: Done（2026-05-07）

### HIST-001
- 月別セクションで記録一覧が表示される
- 日次詳細で日記/できたこと/AI返答が確認できる
- 記録なし時の空状態ガイドが表示される
- 状態: Done（2026-05-07）

### SEC-001
- 未ログインの読み書きが拒否される
- 他UIDで `users/{uid}` と `dailyEntries` へアクセスできない
- Storage `users/{uid}/**` が本人限定であることを確認する
- 状態: Done（2026-05-07）

## P0担当割り当て（Chief差配）

| Ticket | Owner | Support | QA | Safety |
|---|---|---|---|---|
| PROJ-001 | PM Agent | Chief | QA/Test Agent | Safety Agent |
| HOME-001 | UI Dev Agent | Core Dev Agent | QA/Test Agent | Safety Agent |
| SYNC-001 | Core Dev Agent | Arch Agent | QA/Test Agent | Safety Agent |
| COMP-001 | Core Dev Agent | UI Dev Agent | QA/Test Agent | Safety Agent |
| HIST-001 | UI Dev Agent | Core Dev Agent | QA/Test Agent | Safety Agent |
| SEC-001 | Safety Agent | Core Dev Agent | QA/Test Agent | Chief |

## P1（体験品質を上げる）

### PROF-001 プロフィール編集（表示名・自己紹介）
- 目的: 自分専用感の強化
- 完了条件: 保存・再表示・バリデーション
- 見積: 1.5d
- 状態: Done（2026-05-07）

### COMP-002 進化演出UI（イベント通知）
- 目的: 継続モチベーション向上
- 完了条件: 段階アップ時の演出と文言表示
- 見積: 1d
- 状態: Done（2026-05-07）

### AI-001 フィードバック文言の安全ガイド適用
- 目的: 断定/医療的助言の回避
- 完了条件: プロンプト規約反映、NG表現チェックリスト
- 見積: 1d
- 状態: Done（2026-05-07）

### UX-001 上限到達時導線改善
- 目的: Free上限時の離脱防止
- 完了条件: 残回数表示・翌日促し・課金導線（後回し可）
- 見積: 0.5d
- 状態: Done（2026-05-07）

### TEST-001 回帰テストセット整備
- 目的: 変更に強い開発体制
- 完了条件: Home/Sync/Companionのテストケース表 + 実行記録
- 見積: 1d
- 状態: Done（2026-05-07）

## P2（リリース運用・拡張）

### BILL-001 StoreKit本番化
- 目的: Premium判定の本番品質化
- 完了条件: 実Product ID、購入/復元、失敗時表示
- 見積: 2d
- 状態: Done（2026-05-07, `YELLME_PREMIUM_PRODUCT_ID` 経由で差替可能）

### BILL-002 課金検証強化（可能ならサーバー）
- 目的: 改ざん耐性向上
- 完了条件: 検証方針確定 + 実装計画
- 見積: 1.5d
- 状態: Done（2026-05-07）

### EXPORT-001 月次ダウンロード実装
- 目的: 振り返り価値の向上
- 完了条件: 月次データ生成、共有/保存
- 見積: 1.5d
- 状態: Done（2026-05-07）

### OPS-001 リリース運用チェックリスト
- 目的: 手戻り削減
- 完了条件: TestFlight->本番手順、障害時ロールバック手順
- 見積: 0.5d
- 状態: Done（2026-05-07）

## 2週間スプリント推奨順（例）

1. PROJ-001
2. HOME-001
3. SYNC-001
4. COMP-001
5. HIST-001
6. SEC-001
7. PROF-001
8. COMP-002
9. AI-001
10. TEST-001

## P0実行計画（2週間）

### Week 1（リリース体験の中核）
- Day 1: `PROJ-001` 要件凍結 + 受け入れ条件確定
- Day 2-3: `HOME-001` 日次記録フロー安定化
- Day 4-5: `SYNC-001` ローカル/Firestore同期整合

### Week 2（信頼性と出荷品質）
- Day 6: `COMP-001` 進化ロジック境界検証
- Day 7: `HIST-001` 履歴一覧/詳細の完成度確認
- Day 8: `SEC-001` Rules/認可の本番前検証
- Day 9-10: P0回帰テスト + バグ修正バッファ

### Day1-10進捗記録フォーマット
| Day | Ticket | Status | Owner | QA結果 | Safety結果 | Notes |
|---|---|---|---|---|---|---|
| Day1 | PROJ-001 | Done | PM Agent | 受け入れ条件確認済み | SNS関連Rules無効化確認済み | README/Rules/運営ドキュメント整合確認 |
| Day2 | HOME-001 | Done | UI Dev Agent | 導線・制御を確認 | 非致命同期通知を確認 | 主要導線の安定化 |
| Day3 | HOME-001 | Done | UI Dev Agent | エラーメッセージ確認 | - | 異常系と文言調整 |
| Day4 | SYNC-001 | Done | Core Dev Agent | 取り込み・マージ確認 | UID整合チェック済み | マージ処理検証 |
| Day5 | SYNC-001 | Done | Core Dev Agent | 失敗時ローカル保持確認 | Rules整合確認 | 失敗時挙動確認 |
| Day6 | COMP-001 | Done | Core Dev Agent | 境界値ケース追加 | - | 境界値テスト |
| Day7 | HIST-001 | Done | UI Dev Agent | 月別/詳細/空状態確認 | - | 履歴導線確認 |
| Day8 | SEC-001 | Done | Safety Agent | 認可動作を確認 | Firestore/Storage制限確認 | Rules検証ログ取得 |
| Day9 | P0 Regression | Done | QA/Test Agent | テストファイル追加 | - | 回帰テスト整備 |
| Day10 | Buffer/Release Prep | Done | Release Agent | チェックリスト作成 | 課金検証方針文書化 | 出荷準備完了 |

## HOME-001 Day2実行チェック
- [x] 正常系: 入力 -> AI返答 -> 保存 -> 当日表示更新
- [x] 異常系: API失敗時に赤系メッセージ表示
- [x] 制御: 入力不足時は送信不可
- [x] 制御: 日次上限到達時は送信不可
- [x] 非致命: クラウド同期失敗でもローカル保存継続

## 日次運営テンプレ（Chief主導）

### 朝会（15分）
- 昨日完了:
- 今日着手:
- ブロッカー:
- Chief判断が必要な点:

### 夕会（10分）
- チケット進捗（Done/In Progress/Blocked）:
- QA結果:
- Safetyチェック結果:
- 明日の最優先:

## P0運営開始チェックリスト
- [x] P0各チケットの受け入れ条件を記載
- [x] 各チケットの担当（Core/UI/QA/Safety）を割当
- [x] Day1-10の暫定スケジュールを確定
- [x] 直前安定コミットIDの記録方法を決定
- [x] ドキュメント更新担当を固定

## 運用記録ルール（固定）

### 直前安定コミットIDの管理
- 保管先: `release-stable-baseline`（Gitタグ）または週次ノート
- 更新タイミング: P0チケット完了時のみ
- 更新担当: Release Agent

### ドキュメント更新担当
- 実装に紐づく更新: 各実装Owner
- 受け入れ条件と進捗表更新: PM Agent
- 監査ログ追記（Rules/認可）: Safety Agent
