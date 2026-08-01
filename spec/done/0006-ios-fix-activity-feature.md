---
id: "0006"
status: "done"
priority: "medium"
assignee: null
epic: "🦔 品質基盤整備"
dueDate: null
created: "2026-07-25T00:37:18.993Z"
modified: "2026-07-28T05:51:35.792Z"
completedAt: "2026-07-28T05:51:35.792Z"
labels: ["client"]
order: "a2"
---
# iOS: 作業データ集計画面テスト追加と修正

## Overview

client アプリの Activity 集計表示画面(Report画面, `ReportViewModel` が集計ロジックを担う)について、テストコード追加(`client/Packages/AppCore/Tests`)を行う。

`ReportViewModel` には `dateInterval` / `dateRangeText` / `buckets` のテストは存在するが、`chartBars` / `summaryRows` / `totalDuration` / `groupByCurrentLevel` / `clampedDuration` など集計ロジック本体は未テスト。`MockActivityRepository.query(from:to:)` が常に空配列を返す固定実装のため、任意の `Activity` データを注入したテストが書けない状態になっている。

---

## Details

### Task 1: 構造体全体についている@MainActorを、テスト関数に付け直す
- テスト対象のViewModelはメインスレッド専用（@MainActor）である。そのためTestも@MainActorで実行する必要がある。
- しかし、構造体全体に `@MainActor` をつけてしまうと、テストを実行するバックグランドのスレッドから、データにアクセスできなくなり、nonisolatedをつけていたよう。
- 構造体全体ではなく、テスト関数にのみ`@MainActor`をつけるほうが適切だと思う

### Task 2: MockActivityRepository の拡張

`query(from:to:)` および `observe(onChange:)` が任意の `Activity` 配列(`stubbedActivities`)を返せるようにする。集計ロジックのテストを書くための前提となる。

### Task 3: loadIfNeeded テスト追加
### Task 4: reload テスト追加
### Task 5: bucketLabel テスト追加
### Task 6: movePeriod テスト追加
### Task 7: selectDomain テスト追加
### Task 8: toggleTopic テスト追加
### Task 9: totalDuration テスト追加
### Task 10: dayActivities テスト追加
### Task 11: dayScrollStart テスト追加
### Task 12: chartBars テスト追加
### Task 13: summaryRows テスト追加
### Task 14: resolveTitle テスト追加
### Task 15: colorForActivity テスト追加
