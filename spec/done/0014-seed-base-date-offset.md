---
id: "0014"
status: "done"
priority: "medium"
assignee: null
epic: null
dueDate: null
created: "2026-07-29T02:03:05.000Z"
modified: "2026-07-29T06:56:44.263Z"
completedAt: "2026-07-29T06:56:37.092Z"
labels: ["server"]
order: "Zz"
---
# エミュレーターseedデータの改善

## 目的・背景

現状、seedデータ内の日時はYAMLに記述したRFC3339文字列がそのまま使われるため、実行日から離れるほどデータの日付が古くなり、相対日付を前提とした画面確認がしづらい。seed投入の基準日をデフォルトで実行日(今日)とし、必要に応じて±日数で基準日をずらせるようにしたい。

あわせて、seedデータの内容自体も実態に合わせて整理・拡充する（Domainの数を絞り、Activityの件数と日時のバラつきを増やす）。

---

## Details

### Task 1: seed日時を基準日相対テンプレート化し、`-offset-days`で調整可能にする

設計方針: YAML側の日時を明示的な相対テンプレート（`{{base}}` / `{{base-Nd}}` / `{{base+Nd}}`）で記述する方式を採用。seed実行時にアンカーとなる「基準日」を計算し、テンプレートを解決してから投入する（絶対日時をコード側で暗黙にシフトする方式は不採用）。

- `seed.go` に `baseDate time.Time` パッケージ変数と `setBaseDate(offsetDays int)` を追加。`today`（時刻ゼロ埋め）に `offsetDays` を加算して基準日を確定する
- `{{base}}` / `{{base-Nd}}` / `{{base+Nd}}` を正規表現でマッチさせ、日付部分だけを基準日ベースで再計算し、時刻・タイムゾーン部分（例: `T09:00:00+09:00`）は元の文字列のまま連結して `time.Parse(time.RFC3339, ...)` する `resolveBaseDateTemplate` を実装
- `convertTimestamps` の文字列判定で、まずテンプレートとして解決を試み、マッチしなければ従来通り絶対RFC3339としてパースするフォールバックを残す（後方互換）
- `main.go` に `flag.IntVar(&offsetDays, "offset-days", 0, ...)` を追加。未指定時は今日が基準日になる。`flag.Parse()` 直後に `setBaseDate(offsetDays)` を呼び、確定した基準日をログ出力する
- 既存seed YAML（`activities.yaml` / `domains.yaml` / `threads.yaml`）の絶対日時をテンプレートへ一括移行。全ファイル中の最新日時（`activities.yaml` の `2026-03-30`）をアンカー（`{{base}}` = offset 0d）とし、他の日時は元々の相対日数差分を保ったまま `{{base-Nd}}` / `{{base+Nd}}` に変換（一括変換スクリプトで機械的に実施、時刻・タイムゾーン部分は変更なし）。例: `domains.yaml` の `createdAt: "2025-01-01T00:00:00Z"` → `createdAt: "{{base-453d}}T00:00:00Z"`
- `server/Makefile` の `seed` ターゲットは変更しない（`make seed` は従来通り引数なしで今日基準）。offsetを使いたい場合は `go run ./cmd/seed -dir=... -offset-days=N` を直接叩く
- 動作確認: Firestoreエミュレーターに対して `-offset-days=0` と `-offset-days=-5` で実際にseedし、Firestore REST APIで格納されたタイムスタンプがそれぞれ期待通りシフトしていることを確認済み（例: `activity-001.startedAt` が offset 0 で当日9:00 JST、offset -5 でその5日前になる）

### Task 2: seedデータ（Domain / Activity）の整理・拡充

- `domains.yaml` のDomainを7件から4件に削減（iOSアプリ／バックエンドAPI／デザインシステム／コードジェネレーターを残し、マーケティングサイト／データ基盤／クライアント案件Aとそれぞれのtopicsを削除）
- `activities.yaml` のActivityを15件から194件に大幅増加。`{{base}}`（今日）から`{{base-500d}}`（約1年5ヶ月前）まで遡る期間に分散させ、直近2日は必ず活動が存在するよう保証しつつ、それ以前は確率的に0〜2件/日を生成
- Activityの開始・終了時刻の分を毎回ランダム化（従来は`:00`/`:30`など綺麗な値に偏っていた）
- 動作確認: エミュレーターに再seedし、Domain 4件・Activity 194件が投入されること、削除したDomain/topic IDへの参照が残っていないことを確認済み
