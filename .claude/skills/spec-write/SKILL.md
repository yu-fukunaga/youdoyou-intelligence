---
name: spec-write
description: 機能・タスクの仕様書をspec/ディレクトリに作成する。
---

# スペック作成

## 目的

タスクの目的・背景と具体的な手順を記録した仕様書を `spec/` に生成する。

---

## ファイル命名規則

```
spec/YYYY-MM-DD-{kebab-case-name}.md
```

- `YYYY-MM-DD`: 今日の日付
- `{kebab-case-name}`: 機能・タスク名をケバブケースで

---

## 作成手順

1. `date -u +"%Y-%m-%dT%H:%M:%S.000Z"` で現在時刻(ISO8601)を取得する。ファイル名の日付部分にはローカル日付（`date +%Y-%m-%d`）を使う
2. ユーザーの指示とコードの文脈から、下記フォーマットに従って front matter + spec 本文を生成する
3. 不明な点はコードを読んで把握する。それでも不明なら確認する

---

## フォーマット

front matter は必須。すべてのspecファイルの先頭に付与する。

````markdown
---
id: "2026-07-06-skill-evaluation-agent"
status: "backlog"
created: "2026-07-07T12:37:57.634Z"
modified: "2026-07-07T12:37:57.634Z"
completedAt: null
order: ""
---

# {機能名}

## 目的・背景

（なぜこれを作るか。どんな問題を解くか。1〜3文）

---

## Task 1: {タスク名}

（何をするか。どのファイル・関数・APIを変えるか。具体的に）

## Task 2: {タスク名}

（同上）

...（タスクの数に上限はない。必要な数だけ追加する）
````

front matter の各フィールド:

- `id`: ファイル名から `.md` を除いたもの（例: `2026-07-06-skill-evaluation-agent`）
- `status`: 新規作成時は常に `"backlog"`
- `created` / `modified`: 手順1で取得したISO8601タイムスタンプを同じ値で設定
- `completedAt`: 新規作成時は常に `null`
- `order`: 新規作成時は常に `""`

---

## 注意事項

- 「なぜ作るか」を中心に書く。実装詳細は書かない
- タスクは具体的な作業単位に分解する
