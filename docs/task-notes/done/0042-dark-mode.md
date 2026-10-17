---
id: "0042"
status: "done"
priority: "medium"
assignee: null
epic: "🍀 機能追加・改善"
dueDate: null
created: "2026-10-11T15:12:51.000Z"
modified: "2026-10-17T07:43:00.000Z"
completedAt: "2026-10-17T07:43:00.000Z"
labels: ["client"]
order: "a0"
---
# ダークモード対策

## Overview

iosのダークモード発動時に、デザインが崩れてしまっている。
ダークモードに対応するか、もしくは、端末のモードによらずライトモードで表示するか、どちらかの対応が必須。

---

## Details

- 現状、カラースキームを指定している箇所はない（`preferredColorScheme` / `UIUserInterfaceStyle` とも未使用）。
- `Color.white` / `Color.black` などの色の直書きが Sources 内に 5 箇所ある。ダークモードで見えなくなる箇所がないか確認する。

---

## Operation

今回は、端末のモードによらずライトモード固定とする。
いずれダークモード対応にする。

### Task 1: アプリ本体をライトモード固定にする

`YouDoYou_iOS/Info.plist` に `UIUserInterfaceStyle = Light` を追加する。
