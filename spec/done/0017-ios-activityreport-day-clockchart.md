---
id: "0017"
status: "done"
created: "2026-07-31T00:50:19.000Z"
modified: "2026-08-01T11:42:05.000Z"
completedAt: "2026-08-01T11:42:05.000Z"
labels: ["client"]
epic: "機能追加・改善"
order: ""
---

# ios: ActivityReport PeriodType再構成(円グラフ廃止 + 名称変更)

## Overview

as is:
- Day (円グラフ)
- Week (棒グラフ)
- 6M (棒)
- 5Y (棒)

to be:
- Day (旧Week)
- Month (旧6M)
- Year (旧5Y)

Day/Month/YearはPeriodTypeの名前を変えるだけ。旧Dayの円グラフは廃止。

Weekly(旧Week相当の新設)は別途検討中でスコープ外。

---

## Details

- `PeriodType`の定義は`ReportViewModel.swift`の1箇所のみ
- Week/6M/5Yの棒グラフは実装を共有しているが、円グラフ(Day)だけ別実装
- Swiftの網羅的switchの制約上、enumリネームは関連する全箇所(ViewModel/View/テスト)に波及する → タスクは分けず1つで実施

---

## Operation

### Task 1: PeriodType再構成 + 円グラフ廃止

`ReportViewModel.swift`の`PeriodType`をリネームする(旧Week→Day、旧6M→Month、旧5Y→Year)。旧Day(円グラフ)は廃止し、`ClockSegment`/`clockSegments`/`dayClockChart`など円グラフ本体のコードも削除する。Swiftの網羅的switchの制約で波及する関連箇所(switch文、View側の分岐、テスト)も合わせて更新する。
