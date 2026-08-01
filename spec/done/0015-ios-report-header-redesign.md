---
id: "0015"
status: "done"
priority: "medium"
assignee: null
epic: null
dueDate: null
created: "2026-07-30T11:23:29.000Z"
modified: "2026-08-01T09:13:42.000Z"
completedAt: "2026-08-01T09:13:42.000Z"
labels: ["client"]
order: "a0"
---
# ios: ActivityReportのバグ調査と修正 #2

## 目的・背景

[0013](done/0013-ios-activityreport-1.md)で洗い出したバグ・改善案のうち、未着手のまま残ったもの。0013をPRとして区切るため、続きをこちらに切り出す。

---

## Details

### バグ一覧

- [x] 棒グラフの縦軸ラベルの値がおかしい(例: 1,0,0,0,0のように重複する)。小さい値の時に`Int()`で丸めているのが原因とみられる。そもそもグリッド線は5本(下端含む)もいらないかもしれない、3本で十分かも — グリッド線は既に3本、ラベル重複はTask16の`niceMaxHours`で解消

### 改善案

- [x] Topic表示リストを、Domainごとにセクション化して表示したい — 詳細は`## Operation`のTask10
- [x] ヘッダー/リストのレイアウト再設計(Week/6M/5Y、Dayは対象外・現状維持) — 詳細は`## Operation`のTask1〜6
- [x] 棒グラフのバー選択機能(新規、上記レイアウト再設計とセット) — 詳細は`## Operation`のTask7〜9
- [x] movePeriod: 各グラフ共通で、現在時刻を含む期間より未来には進めないようにしたい。あわせて2020/1/1より過去にも進めないようにした
- [x] 見た目調整 Task14〜17

## Operation

配置調整(改善案「ヘッダー/リストのレイアウト再設計」)を、以下の粒度で進める。バー選択機能は別タスクとして扱い、ここでは触らない。

### Task1: dateRangeHeaderの再設計

`dateRangeHeader`から合計時間・平均時間の表示を削除する。期間テキストの左右に矢印(chevron)ボタンを配置し、タップで`movePeriod`を呼ぶ。`groupingUnitButton`は右端にそのまま残す。

### Task2: barChartのドラッグジェスチャーを削除

Task1の矢印ボタンに置き換わるため、`barChart`に付いている`DragGesture`(`movePeriod`呼び出し)を削除する。

### Task3: 「今日」ボタンをヘッダー左端に追加

表示中の基準日(`currentDate`)を今日に戻すボタンを、`dateRangeHeader`の左端に配置する。表示中の期間が今日を含んでいる場合はこのボタンを表示しない。

### Task4: 合計/平均の新エリアを追加

グラフの下・リストの上に、合計時間/平均時間を表示する新エリアを追加する。

### Task5: リストの「合計」行を削除

`summaryList`の先頭に固定表示されている「合計」行(`totalRowView`)を削除する。

### Task6: 新エリアとリストエリアに角丸四角の背景を適用

Task4の新エリアと、リストエリア全体それぞれに、角丸四角の背景を適用する。

---

棒グラフのバー選択機能を、以下の粒度で進める。

### Task7: ViewModelにバー選択状態を追加し、タップで選択できるようにする

`selectedBarIndex: Int?`を追加し、トグルする関数を用意する。Domain/Topicの`selectedItemId`とは独立した軸として扱う。`movePeriod`実行時と`periodType`変更時にはバケットの意味が変わるためリセットする。各バーにタップジェスチャーを追加し、`selectedBarIndex`をトグルする。選択中のバーは、そのバケットの範囲でグラフ上辺まで縦に背景色をつけて視覚的にわかるようにする。

### Task8: 選択中は合計/平均エリアを切り替える

`selectedBarIndex`が設定されている間、Task4の新エリアの表示を「{選択中バーのラベル}の合計」+「平均の代わりに{選択中バーのラベル}までの累計」に切り替える。ラベルは基本的に棒グラフのバー自体のラベル(6Mなら月、5Yなら年)。ただしWeekは曜日1文字だけだと読みにくいため、`m月d日(aaa)`形式の詳細な日付表記にする。

### Task9: 選択中はリストをそのバケットの内訳に絞り込む

`selectedBarIndex`が設定されている間、リストの各行の表示値を、そのバケット(`ListRow.bucketDurations`)の値に切り替える。

---

Topicリストのセクション化を、以下の粒度で進める。

### Task10: ViewModelにセクション化されたデータ構造を追加し、リスト表示をTopicモード時はセクション表示に切り替える

`ListSection`(セクションタイトル+`[ListRow]`)を追加し、Topicモード時にDomain登録順でセクション化し、セクション内はTopic合計の降順でソートする関数を用意する。`summaryList`をTopicモード時はこのセクションを使った表示に切り替える。セクションヘッダーにDomain名を表示するので、行内の重複する`subtitle`表示は削除する。

---

見た目調整4件を、以下の粒度で進める。

### Task14: dateRangeHeaderの上下余白を広げる

`dateRangeHeader`の`.padding(.vertical)`を広げる。

### Task15: 「今日」ボタンをボタンらしい見た目にする

現状はただのテキストの`todayButton`に、背景や枠線などボタンとわかる見た目をつける。

### Task16: 棒グラフの縦軸最大値を1.15倍→1.2倍にする

`barChart`の`maxHours`計算の係数を`1.15`から`1.2`に変更する。

### Task17: 棒グラフと合計/平均エリアの間に余白を追加する

`barChart`と`totalsArea`の間に余白を追加する。
