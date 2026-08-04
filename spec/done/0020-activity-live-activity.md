---
id: "0020"
status: "done"
priority: "medium"
assignee: null
epic: "🍀 機能追加・改善"
dueDate: null
created: "2026-08-01T11:54:01.000Z"
modified: "2026-08-04T15:45:56.373Z"
completedAt: "2026-08-04T15:45:56.373Z"
labels: ["client"]
order: "Zy"
---
# Live Activities導入

## Overview

作業時間記録中にLive Activityを表示したい。そのためにまずLive Activityが使える状態にする。

---

## Details

- [x] Widget Extensionターゲット追加 — 詳細は`## Operation`のTask1
- [x] 不要な雛形の削除 — 詳細は`## Operation`のTask2
- [x] 共有ターゲット新設・Widget側コード分離 — 詳細は`## Operation`のTask3
- [x] タイマー開始時にLive Activityを開始・表示確認 — 詳細は`## Operation`のTask4

---

## Operation

### Task 1: Widget Extensionターゲットとコード共有基盤のセットアップ

- Xcodeで`YouDoYouClient.xcodeproj`にWidget Extensionターゲット`YouDoYou_Widgets`(Product Name: `YouDoYou_Widgets`、#61の命名パターンに合わせる)を追加。「Include Live Activity」のみ有効化し、「Include Control」「Include Configuration App Intent」は無効化


### Task 2: 不要な雛形の削除

- Widget Extension作成時に生成された、ホーム画面用の汎用ウィジェット雛形を削除する


### Task 3: Live Activity用共有ターゲットの新設とWidget側コードの分離

- `YouDoYou`パッケージ内に2ターゲットを新設し、`products`にも公開する
  - `TimerLiveActivityAttributes`: Live Activityが持つデータのみを置く。
  - `TimerLiveActivityCore`: Widget側のUIを置く。`TimerLiveActivityAttributes`に依存
  - AppCoreとTimerLiveActivityCoreに`TimerLiveActivityAttributes`を追加
- Widget Extension内に雛形として生成されていたAttributesとLiveActivityを、それぞれ上記2ターゲットに分離・移動する(`public`化、`public init`を明示的に追加)
- Xcodeで依存を追加する: Widget ExtensionのXcodeターゲットに`TimerLiveActivityCore`をパッケージ依存として追加(本体アプリは既存の`AppCore`依存経由で`TimerLiveActivityAttributes`を利用できるため追加不要)
- Widget ExtensionのBundle Identifierを、本体アプリのビルド構成ごとのBundle Identifierと前方一致するよう修正(#61でDebug/Test構成のサフィックスが`.dev`に変更済みなのでそれに追従。Debug/Test: `jp.co.youdoyou.client.dev.youdoyou-widgets`、Release: `jp.co.youdoyou.client.youdoyou-widgets`。末尾はXcodeの自動生成に合わせて小文字・ハイフン区切り)
- `client/YouDoYou_iOS/Info.plist`に`NSSupportsLiveActivities = YES`を追加する


### Task 4: タイマー開始時にLive Activityを開始する

`ActivityCreateViewModel.startTimer()`に`ActivityKit.Activity<TimerLiveActivityAttributes>.request()`を追加する

注意: `AppCore`には既存のドメインモデル`Activity`(Firestoreに保存する作業記録)が存在し、`ActivityKit.Activity`と型名が衝突する。`ActivityKit.Activity<...>`とモジュール名を明示して回避する

注意: `request()`は`throws`(非async)なので`do/catch`で囲む
