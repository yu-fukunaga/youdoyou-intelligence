---
id: "0041"
status: "done"
created: "2026-10-11T15:04:39.000Z"
modified: "2026-10-25T04:48:58.000Z"
completedAt: "2026-10-25T04:48:58.000Z"
labels: ["terraform"]
epic: "🦔 品質基盤整備"
order: ""
---

# メール/パスワードのサインインを無効化する

## Overview

実プロジェクト（dev / prod）ではログイン手段を Google ログインだけにする。メール/パスワードのプロバイダは不要なので無効にする。

---

## Details

- [x] `modules/auth` で無効を明示する — 詳細は `## Operation` の Task 1
- [x] エミュレーターの Test User ログイン（`test@example.com`）への影響 — apply 後もログインできることを確認済み
- client の UI は変更不要。`LoginView` の「Sign In as Test User」ボタンは DEBUG ビルド限定で、エミュレーター接続時だけ有効。

---

## Operation

### Task 1: auth モジュールでメール/パスワードのサインインを無効にする

`modules/auth` の `google_identity_platform_config` に `sign_in` を追加し、`email` と `phone_number` を `enabled = false` にする。モジュール共通なので dev / prod の両方に効く。

- dev は Console で `signIn.email.enabled: true` になっていた。変更前の plan は No changes で、drift はなかった（コードに `sign_in` がないため比較対象がなかっただけ）。
- `email` だけ書いて apply すると、state に残る `phone_number { enabled = false }` が毎回の plan 差分に出る。`phone_number` も明示して差分を消した。
- apply 後、Identity Platform API の `signIn` から `email` が消え、plan は No changes になった。
