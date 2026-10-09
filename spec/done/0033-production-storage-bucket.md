---
id: "0033"
status: "done"
priority: "medium"
assignee: null
epic: "🍀 機能追加・改善"
dueDate: null
created: "2026-10-09T08:58:52.000Z"
modified: "2026-10-09T16:25:55.000Z"
completedAt: "2026-10-09T16:25:55.000Z"
labels: ["firebase", "terraform"]
order: "a0"
---
# 本番 Firebase Storage バケットの用意

## Overview

本番 Firebase Storage バケットを用意し、画像アップロードを本番で使えるようにする。

---

## Details

- バケットは Firebase デフォルトバケット `youdoyou-intelligence-dev.firebasestorage.app`（dev/prod 両 plist の `STORAGE_BUCKET` と一致）。名前が一致するので plist 改修は不要。
- デフォルトバケットは `projects.defaultBucket.create` API 経由でのみ作成でき、terraform プロバイダは未対応（Sept 2024 の仕様変更。旧 App Engine 経由も廃止）。`google_storage_bucket` で `.firebasestorage.app` を直接作ると、ドメイン所有権エラー（403）になる。→ Firebase Console で作成し、terraform 管理外とする。
- location は `us-east1`。Storage の無料枠は `us-central1` / `us-west1` / `us-east1` のみで、`asia-northeast1` は無料枠なし（Firestore とは独立。Firestore 無料枠にリージョン制限はない）。
- terraform 側の変更は `firebasestorage.googleapis.com` の有効化のみ（`modules/services`）。
- ルールは Firebase Console で直書きする（Firestore ルールと同じ運用）。repo 管理・再現デプロイは今回スコープ外。

---

## Operation

### Task 0: project_id を env 直書きに修正

- `projects/dev/provider.tf` の `project_id` が `basename(path.cwd)` 依存で、`make`（`-chdir`）経由だと環境名が `terraform` に解決され、別プロジェクトとして全リソース再作成の plan が出る不具合を修正。
- 環境名を `basename(abspath(path.module))`（ファイルのあるディレクトリ名）から取り、起動ディレクトリ非依存にする。

### Task 1: firebasestorage API を有効化

- `modules/services` の有効化 API に `firebasestorage.googleapis.com` を追加。

### 非コード作業（コミット不要・手動）

- Firebase Console でデフォルトバケットを作成（location `us-east1`、本番モード）。
- Firebase Console で Storage ルールを直書き。
