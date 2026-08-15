---
id: "0027"
status: "done"
created: "2026-08-15T04:50:18.000Z"
modified: "2026-08-15T08:46:09.000Z"
completedAt: "2026-08-15T08:46:09.000Z"
labels: ["client", "firebase", "gen-go", "server"]
epic: "🐤 リファクタリング"
order: ""
---

# ドメイン概念「Activity」を「WorkLog」にリネームする

## Overview

作業記録を表すドメイン概念の名前を「Activity」から「WorkLog」に変更する。schemaが唯一の定義元(single source of truth)になっているため、`firebase/schema/firestore.yaml`から変更し、生成コードを再生成する形で進める。本番Firestoreにはまだデータが存在しないため、データ移行は不要。

---

## Details

- schemaが起点: `firebase/schema/firestore.yaml`の`Activity`モデル・`activities`コレクション定義を変更し、`gen-go/schema/activity.go`と`client/.../Generated/Activity.swift`を再生成する
- 手書きコードの影響範囲: client(Swift)側は`ActivityRepository`/`ActivityState`/`ActivityViewModel`系5つ/`Views/Activity/`配下5ファイル/`Views/Home/`の2ファイル/`TimerBanner`/`DomainItem`/`NavigationState`/`AppCore`/`ReportViewModel`/テスト2ファイル。server側は`server/cmd/seed/main.go`のみ(APIルート等は無し)。`functions/`はActivity関連の参照なし
- **重要な区別**: `TimerLiveActivityAttributes`等のApple ActivityKit(Live Activity機能)は今回のリネーム対象外の別概念。混同して変更しないこと
- spec側: `spec/MEMO.md`、`spec/0025`(Live Activity機能の話と混在してるので要注意)、`spec/done/0020`(同様に要注意)、`spec/done/0006`など、Activityに言及してる過去specファイルもWorkLogに置き換える(gitignore対象で未追跡のものも含む)
- terraform配下にActivity関連の記述は無し。変更不要

---

## Operation

### Task 1: schemaの変更とコード再生成

`firebase/schema/firestore.yaml`の`Activity`モデル定義・`activities`コレクションパスを`WorkLog`/`worklogs`に変更し、generatorを実行して`gen-go/schema/`と`client/.../Generated/`配下を再生成する。

### Task 2: serverの手書きコード修正

`server/cmd/seed/main.go`の`schema.CollectionActivities`等の参照を新しい生成後のシンボル名に合わせて修正する。

### Task 3: clientの手書きコード修正

Repository/State/ViewModel/View/テストの各ファイルで、型名・変数名・ファイル名を`Activity`→`WorkLog`に一括リネームする。

### Task 4: specファイルの用語更新

`spec/`配下(`done/`含む、未追跡ファイル含む)で、ドメイン概念としての「Activity」への言及を「WorkLog」に置き換える。Apple ActivityKit(Live Activity)への言及は変更しない。
