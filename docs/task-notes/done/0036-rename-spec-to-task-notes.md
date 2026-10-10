---
id: "0036"
status: "done"
priority: "medium"
assignee: null
epic: "🦔 品質基盤整備"
dueDate: null
created: "2026-10-11T04:00:00.000Z"
modified: "2026-10-10T17:57:57.631Z"
completedAt: "2026-10-10T17:57:57.631Z"
labels: [".github"]
order: "Zv"
---
# spec/ を docs/task-notes/ にリネーム

## Overview

作業記録ファイル群を `spec/` から `docs/task-notes/`、呼称を「spec」から「task note」に変更する。実態（方針をざっくり決めて、やりながら育てるメモ）と「spec＝確定した正しい仕様」という語感がズレており、名前が実態を誤認させるため。

---

## Details

### 呼称を task note にする理由

- このファイルの実態は、着手前に方針を少し書き、やりながら追記し、完了後は記録になる「暫定の作業ドキュメント」。状態で見え方は変わる（着手前＝計画メモ、進行中＝ログ、done＝記録）が、全状態を貫く不変項は「正しさ・完結を主張しない作業メモ」であること。
- `spec`（＝仕様書）はこの不変項を裏切る。「常に正しい仕様を表すもの」に見える。これは個人の手元の記録であって、そうした枠組みに乗せるものではないため、連想させる名前を避けたい。

### 却下した候補

- `ticket` / `issue`: 「発行してキューに積み、後で着手する」含意。実態（やりながら書く）と矛盾する。AIによるチケット駆動開発を連想させる名称も避けたい。（成果重視の仕事ではなく、学習目的の取り組みであるので、AIによるループエンジニアリングは行ってない。）
- `spec`: 上記のとおり「確定仕様」の語感と spec-driven development の連想。
- `task`: Operation 内の `Task`（1 Task = 1 コミット）と語がぶつかる。ticketやissueに近い感じもする。積まれているものを処理していく感がある。
- `work` / `worknote`: `work` は単位が漠然。`worknote` は英語ネイティブには非単語でタイポっぽい。
- `working-notes`: 自然な英語だが長い。
- `ADR`: 非トレンドでクラフト感は合うが、Architecture Decision Record＝設計判断の記録という限定された意味があり、実装タスク中心の中身には合わない（語の誤用になる）。

### ディレクトリ名と呼称の区別

- ディレクトリは `docs/task-notes/`、`docs/task-notes/done/`。ルート直下に非技術ディレクトリを増やさないため、唯一の非技術ルートである `docs/` の配下に置く。
- 概念語・散文中の呼称は `task note`。
- 置換は機械的な `s/spec/.../g` を避け、`specific` / `specification` / `respect` / `aspect` / `inspect` 等の部分一致を壊さないよう、概念語・パス・識別子として現れる `spec` のみを対象にする。
- `done/` サブフォルダ名は拡張機能 `LachyFS.kanban-markdown` のハードコードで変更不可。受け入れる。

---

## Operation

### Task 1: spec/ を docs/task-notes/ にリネームし全参照を置換

- ディレクトリ `spec/` → `docs/task-notes/`（`spec/done/` → `docs/task-notes/done/`）。
- VSCode global 設定 `kanban-markdown.featuresDirectory: "spec"` → `"docs/task-notes"`。
- `.gitignore`: `spec/*.md` → `docs/task-notes/*.md`、`!spec/README.md` → `!docs/task-notes/README.md`、`!spec/done/` → `!docs/task-notes/done/`、skill 許可行 `spec-write` → `task-note-write`。
- skill `.claude/skills/spec-write/` → `task-note-write/`（ディレクトリ名・`name:`・`description:`・本文中の参照）。
- `docs/task-notes/README.md` 本文の呼称・パスを task note へ。
- `scripts/check_golangci_lint_go_version.sh` の参照パス `spec/done/0030` → `docs/task-notes/done/0030`。
- 過去 done 本文の概念語・パス参照も task note / `docs/task-notes/` へ置換（当時のコマンド出力・シェル挙動の引用2箇所は事実保持のため据え置き）。
- floating な未コミットファイル（`AGENTS.md`・`docs/makefile.md`・`docs/tools.md`・`README.md`・`terraform/README.md`）は単語のみ修正し、ステージ・コミットはしない（未コミットのまま据え置き）。
- リネーム対象の tracked 分だけをステージしてコミット → PR → main へ merge。

### Task 2: pr-policy-check を rebase し CI を task note に合わせる

- `chore/pr-policy-check` を更新後の main に rebase。
- job `spec-check` / opt-out ラベル `allow: no-spec` / marker `pr-policy:spec` の改名（具体名は着手時に決める）。
- diff 判定の grep `^spec/done/` → `^docs/task-notes/done/`。
- `::error` ・コメント本文の文言を task note / `docs/task-notes/done/` へ。
