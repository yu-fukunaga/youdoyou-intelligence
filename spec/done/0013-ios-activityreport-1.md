---
id: "0013"
status: "done"
priority: "medium"
assignee: null
epic: "🍀 機能追加・改善"
dueDate: null
created: "2026-07-29T00:29:44.985Z"
modified: "2026-07-30T11:23:29.000Z"
completedAt: "2026-07-30T11:23:29.000Z"
labels: ["client"]
order: "a0"
---
# ios: ActivityReportのバグ調査と修正 #1

## 目的・背景

`ReportView`/`ReportViewModel`(旧`ActivityReport`)にいくつかバグが見つかっている。個別に場当たり的に直すのではなく、一度症状を洗い出して整理してから修正する。

---

## Details

### バグ一覧

- [x] week表示のとき、1日の合計が24時間を超えることがある → 根本原因はActivity作成/編集時に重複する時間帯を許してしまっていること(Report側の集計は正しい)。Activity側の責務なので0013の対象外とし、別specで扱う
- [x] 棒グラフの上にある時間表記が、左右の棒や時間表記と重なってしまう(week=7分割は問題なし、7分割程度が表示できる限界とみられる。quarter/yearは表示期間(分割数)自体の見直しが必要そう)

未着手のバグは[0015](0015-ios-activityreport-followups.md)へ移動。

### 改善案

- [x] day表示: 現状の縦Timelineではなく、24時間の円グラフ(時計と同じ構成)にする案
- [x] ヘッダー: 合計時間表記と表示期間が縦並びになっているが、横並びにしたい
- [x] ヘッダー: 合計時間の表記に「合計」というラベルを付けたい
- [x] 棒グラフ: 同じPeriodType内(期間移動・Domain/Topic切替・リスト選択)で、棒の高さ・ラベルにアニメーションをつけたい。グリッド線は固定表示のまま動かさない
- [x] PeriodType切替時(Week⇄6M⇄5Y、bucket数が変わる場合)、棒グラフの列の増減をアニメーションさせたい

未着手の改善案は[0015](0015-ios-activityreport-followups.md)へ移動。

## Operation

### Task 1: 表示期間の見直し(完了)

目盛りは最大6分割までにしたい(week=7分割は既存のまま許容し、対象外)。QuarterとYearを以下に置き換える。

- Day: 変更なし
- Week(1日単位、月〜日): 変更なし
- 週単位表示: 見送り。月をまたぐ場合の区切り方(暦アンカー)が定まらないため
- 6M(旧Quarter): 半年(上半期/下半期)を月単位で6分割
- 5Y(旧Year): currentDateが属する年を含めた直近5年間(暦年単位、1/1〜12/31)で分割する

選択肢名は表示期間の長さ基準で `Day / Week / 6M / 5Y` に統一する。

ヘッダーの期間表記(Week/6M/5Yのみ、Dayは対象外)は以下のラベルにする。

- Week: 「第◯週 yyyy/mm/dd ~ yyyy/mm/dd」(日付も併記)
- 6M: 「yyyy年前期」「yyyy年後期」
- 5Y: 「直近5年 yyyy - yyyy」

棒グラフ下の目盛ラベルは、6M=「M月」、5Y=「yyyy年」とする。

### Task 2: Domain/Topic積み上げ切り替え + リスト連動(完了)

Domain選択chip(フィルタと表示単位切り替えを兼ねていた)を廃止し、以下に整理した。

- `GroupingUnit`(domain/topic)を追加。棒グラフ・リストはこの単位でグルーピングする(デフォルトはdomain)
- 積み上げ単位の切り替えは、Period Picker(Day/Week/6M/5Y)と並べて専用行にすると同じ見た目の選択肢が2段になり重要度の差が伝わりにくいため、専用行にはしない。「合計」行に埋め込む案も試したが却下し、最終的にヘッダー(合計時間表記)の右端に1つのボタンを置き、タップごとにDomain⇄Topicをトグルする形にした
- リストアイテムをタップすると、棒グラフ・ヘッダー合計はそのDomain/Topicのみの状態になる(`selectedItemId`でフィルタ)
- リストはフィルタの影響を受けず常に全項目を表示する(タップで選択解除しやすくするため)。グレーアウト表示は「選択できないように見える」ため見送り、代わりにリスト先頭に「合計」行を追加し、タップで選択解除できるようにした。この行はスクロール時もリスト内で上部固定(pinned section header)
- `timelineTitle`は`groupingUnit`ベースで、Topic表示時は全Domain横断でTopicIdから検索するように変更済み

### Task 3: 棒グラフの表示エリアの高さを縮小(完了)

`barChart`の`.frame(height:)`を240pt→120pt(半分)に変更した。

### Task 4: ヘッダーのレイアウト変更(完了)

- 合計時間・平均時間を横並びの2ブロックにし、間に縦の区切り線(`Divider()`)を入れた。各ブロックは「ラベル(小さく薄い) + 数字は大きく太字・単位は小さく薄い(`styledDuration`)」の構成
- 平均時間はバケツ(bucket)単位の平均(Week=1日あたり、6M=1ヶ月あたり、5Y=1年あたり)。Dayはバケツ概念がないため1バケツ(=その日)扱いで合計と同値になる(`headerAverageDuration`)
- 期間表記のフォーマットを変更: Week「yyyy年M月d日~M月d日」、5Y「yyyy年~yyyy年」
- Domain/Topic切り替えボタンは、ラベル文字を廃止しアイコンのみに変更。合計時間・平均時間の行の右端に配置
- 時間表記の行と期間表記の行がずれていた(外側VStackのalignmentが未指定でcenterになっていた)ため、`.leading`を明示して修正

### Task 5: Day表示を24時間の円グラフに変更(完了)

- 縦スクロールのTimeline(`RectangleMark`)を廃止し、`SectorMark`ベースの円グラフに置き換えた
- 1日を「活動 + 空白」の連続セグメントに分解し、時系列順に`SectorMark`へ渡すことで実時刻の位置と一致させる(`ClockSegment`/`clockSegments(domains:)`)。空白時間帯は薄いグレー(`Color(.systemFill)`)
- 内側をドーナツ状にくり抜き(`innerRadius: .ratio(0.72)`)、中心に合計時間を表示
- 外周に`Canvas`で0〜23の時刻数字を配置(時計の目盛りのイメージ)。ラベル用Canvasの余白が足りず0/12が見切れていたため、フレームを+28pt→+40ptに拡大して解消
- グラフサイズは画面幅いっぱいだと大きすぎたため200×200ptに固定
- Dayのヘッダーは、円グラフ横並び案も検討したが「期間テキスト+ボタンだけになる」ため見送り、縦並び(ヘッダー行→円グラフ)のまま維持。合計時間・平均時間の数値表示は円グラフ中心と重複するため、Dayのヘッダー行(`dayHeader`)には出さず期間テキストとDomain/Topic切り替えボタンのみにした
- スワイプでの前後の日移動は円グラフ行に付与(画面幅いっぱい)
- 不要になった`timelineScrollStart`を削除し、`clockSegments`のテスト(空白時間の算出、活動が重複する場合は後発を先発の終了時刻でクランプする挙動)を追加

### Task 6: 棒グラフのアニメーション対応(完了)

Swift Charts(`Chart`/`BarMark`)は「軸とマークが同じアニメーショントランザクションを共有する」設計で、`.animation`を付けると軸のグリッド線まで再描画アニメーション(内側から広がる等)がかかってしまい、細かい制御ができなかった。棒グラフをSwift Chartsなしの自前実装(`Rectangle`+`Path`)に置き換えて対応した。

- 背景(グリッド線・目盛りラベル)は`GeometryReader`+`Path`で、常に最新の`bars`から即座に計算・描画。アニメーションは一切付けない
- 各バー列(`barColumn`)は`.animation(.easeInOut.delay(0.3), value: bar.total)`で個別にアニメーションする。ラベル(合計時間・期間ラベル)は`.contentTransition(.opacity)` + `.animation(.easeInOut.delay(0.1), value:)`でバーより少し早くクロスフェードする
- `BarChartColumn.id`を日付ベースから位置(バケツindex)ベースに変更し、`ForEach`が期間移動をまたいでも「同じ列の値が変わった」と認識できるようにした(でないと全部作り直し扱いになりフェード表示になってしまう)
- `barChartColumns`は、そのbucketに活動がないDomain/Topicも常に0秒として含めるようにした(セグメントの構成を固定し、新規に増える項目もフェードではなく高さ0からのアニメーションになるようにするため)。これに伴い`BarChartSegment`の「empty」プレースホルダーは廃止
- レイアウトの学び: `Spacer`をバー(Rectangle群)専用の内側VStackに入れると、そのVStackが常に固定の残りスペースを埋めてしまい、上に乗せたラベルの位置がバーの実際の高さに追従しなくなる。`Spacer`はラベル+バーのグループ全体の外側(最上部)に置く必要がある
- 棒の間隔を4→10に拡大、バー自体は左右4ptのpaddingで列より少し細くした
- 棒上の合計時間ラベルは「3h35m」形式(この表示のみ、他の`reportText`表示は日本語表記のまま)
- PeriodType切替時(6M⇄5Yなど)は、bucket数自体がPeriodTypeごとに異なる(Week=7, 6M=6, 5Y=5)ため、列の増減が発生し`ForEach`が挿入/削除として扱ってしまい、該当列だけアニメーションせず即座に表示が切り替わる問題があった。`ReportViewModel.maxBarSlots`(=7、Weekの最大値)まで列を常にパディングし、実データを持たない列は`label`が空文字の「プレースホルダー列」として扱うことで解決した(`BarChartColumn.isPlaceholder`は`label.isEmpty`から導出する計算プロパティ)。表示側(`ReportView`)では`GeometryReader`で実列数から幅を計算し、プレースホルダー列は幅0にすることで見た目に隙間を作らずに済ませている
- バグ: ラベル行の`HStack`を包む`VStack`のalignmentが未指定(デフォルト`.center`)だったため、バー行(`ZStack`は明示的に`.topLeading`で左寄せ)よりラベル行が右にずれて表示されていた。`VStack(alignment: .leading)`を明示して解消
- 改善: バー列の間に区切りとして縦の点線グリッドを追加(`barChartGridlines`に`columnWidth`/`realCount`を渡し、実バーの間隔の中心に描画。列幅の変化にはバーと同じdelay/durationでアニメーションを付けている)
