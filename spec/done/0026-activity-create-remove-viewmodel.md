---
id: "0026"
status: "done"
priority: "medium"
assignee: null
epic: "🐤 リファクタリング"
dueDate: null
created: "2026-08-15T02:27:04.000Z"
modified: "2026-08-17T15:54:45.000Z"
completedAt: "2026-08-17T15:54:45.000Z"
labels: ["client"]
order: "a0"
---
# WorkLogCreateViewからViewModelを廃止しSwiftUIネイティブな設計にする

## Overview

WorkLogCreateViewModelを廃止し、WorkLogCreateViewが`WorkLogDraftStore`(Repositoryを注入した`@Observable`クラス)を直接操作する構成に変更する。

SwiftUIの標準的な設計(WWDC2023 "Data essentials in SwiftUI"が示す、Viewの`body`自体がViewModelの役割を果たすという方向性)を試すことが目的。

---

## Details

- [x] `startTimer()`/`stopTimer()`/`post()`(ActivityKit呼び出し・Firestore保存含む)を`WorkLogDraftStore`に移植し、`isLoading`/`error`/`domain`/`topic`はViewのローカル`@State`/計算プロパティに置き換えた。`WorkLogCreateViewModel`は削除済み
- [x] `WorkLogCreateView`内の表示も`WorkLogState`から`WorkLogDraftStore`に切り替え済み
- [x] `TimerBanner`/`AppCore.swift`/`DomainItem.swift`も`WorkLogDraftStore`に切り替え、`WorkLogState`は削除した
