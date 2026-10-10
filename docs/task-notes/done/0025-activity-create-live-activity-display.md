---
id: "0025"
status: "done"
priority: "medium"
assignee: null
epic: "🍀 機能追加・改善"
dueDate: null
created: "2026-08-11T11:12:23.000Z"
modified: "2026-08-19T13:30:09.000Z"
completedAt: "2026-08-19T13:30:09.000Z"
labels: ["client"]
order: "a0"
---
# WorkLogCreateViewでのLive Activity表示を完成させる

## Overview

作業時間記録中にアプリを閉じていても、計測中であることがわかるようにLiveActivityで経過時間を表示する。

すでに`WorkLogDraftStore.startTimer()`にLive Activity開始処理は追加済み。
ウィジェットUIがXcode生成のプレースホルダーのままで、タイマー停止時にLive Activityを終了する処理もない。作業記録中にLive Activityで実際の作業内容・経過時間を表示し、記録終了時に正しく閉じられるようにする。

---

## Details

- [x] ロック画面・Dynamic Island(展開時/compact/minimal)にアプリアイコン・domain名/topic名・動いてる経過時間(`Text(timerInterval:)`)を表示する
- [x] `stopTimer()` / `reset()`(post成功・破棄の両方で呼ばれる)でLive Activityを終了する
- [x] TimerBannerはそのまま残した
- [x] アプリ起動時の状態復元時、`Activity.activities`が空ならdomain/topicタイトルを使って再requestする(Simulatorの再起動でLive Activityが消えるケースで動作確認済み)
