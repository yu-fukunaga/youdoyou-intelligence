---
id: "0024"
status: "done"
priority: "medium"
assignee: null
epic: "🍀 機能追加・改善"
dueDate: null
created: "2026-08-07T16:13:19.000Z"
modified: "2026-08-11T11:06:01.559Z"
completedAt: "2026-08-11T11:06:01.560Z"
labels: ["client"]
order: "Zx"
---
# Homeタブ

## Overview

現在のタブ構成(WorkLogs(旧Activities) / Domains / Reports)を見直し、新たに「Home」タブを追加する。Home一つで今日・今週の作業状況を把握でき、そこから記録を開始できるようにする。WorkLog一覧とDomain一覧はタブから外し、Homeからのリンク遷移として提供する。

---

## Details

### Homeタブの構成(上から2エリア)
- アクティビティ: タイトル + 右端にWorkLog一覧への遷移リンク。今日の作業時間合計と時間帯別グラフ
- 記録する: タイトルのみ(遷移リンクなし)。最近記録したTopicを横並びで表示し、右端の「すべて」ボタンでTopic選択画面(Topics)を開く

### タブ構成の変更
WorkLog一覧・Topic選択画面はタブから外れ、Homeからのリンクで遷移する形にする
