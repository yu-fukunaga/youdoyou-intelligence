---
id: "0030"
status: "done"
priority: "medium"
assignee: null
epic: "🦔 品質基盤整備"
dueDate: null
created: "2026-09-26T01:30:23.000Z"
modified: "2026-09-26T06:58:15.000Z"
completedAt: "2026-09-26T06:58:15.000Z"
labels: ["server", "firebase", "functions", "client", "terraform", "homepage"]
order: "Zy"
---
# Go toolchainバージョンの固定

## Overview

ローカルのGoバージョンが`go.mod`の宣言(`go 1.26.6`)より新しい場合、golangci-lintが対象コードのstdlibを解析できずpanicする。開発者ごとのローカルGoバージョンに依らず、プロジェクトが宣言するバージョンに固定することで、この種の環境差異による不具合を防ぐ。

---

## Details

### 調査結果
- [x] 事象: ローカルGoが1.27.0、`server/go.mod`等は`go 1.26.6`。golangci-lint v2.12.2(go1.26.2ビルド)が1.27.0のstdlibソースを解析しようとして`panic: file requires newer Go version go1.27 (application built with go1.26)`
- [x] `go.mod`の`toolchain`行は下限を指定するだけで、ローカルの方が新しい場合は無視される(実機検証済み: `toolchain go1.26.6`を書いても実際に使われるコンパイラはローカルの1.27.0のまま)
- [x] 環境変数`GOTOOLCHAIN=go1.26.6`(`+auto`なしの厳密指定)にすると、ローカルが新しくても指定バージョンをダウンロードして使用する(実機検証済み)
- [x] この`GOTOOLCHAIN`厳密指定だけで、golangci-lintをv2.14.0に上げなくてもv2.12.2のままpanicが解消することを確認済み(`GOTOOLCHAIN=go1.26.6 ./bin/golangci-lint run --enable=gosec` → `0 issues`)
- [x] mise/asdf等のバージョンマネージャは新規ツール依存になるため不採用
- [x] Makefileで`go.mod`から動的に読んでexportする案(A)と、`.envrc`に動的に書く案(B)を比較。`.envrc`はコミットしても秘密が混じらない(direnv公式wikiにも載っている一般的パターン)ので、`.envrc`(案B)を採用
- [x] `.envrc`を採用する場合、`.gitignore`から`.envrc`を除外する必要がある(`.env`は引き続き無視)
- [x] `server`/`functions`の`.envrc`は`source_up`で親(root)の`.envrc`を継承済み。`firebase`だけ`.envrc`自体が存在しないため新規作成が必要
- [x] ルートから`make server/lint`のように`Makefile.agg`経由で叩いた場合も、`direnv exec server ...`でラップされているためcwdに関係なく`.envrc`が正しく読み込まれることを実機検証済み
- [x] しかし`.pre-commit-config.yaml`の既存フックは`bash -c 'cd server && make lint'`という素の`cd`形式で、direnvのシェルフック(`~/.zshrc`の`direnv hook zsh`)を経由しない。実機検証の結果、この形式では`.envrc`の環境変数が一切反映されないことを確認(`~/.bashrc`にはdirenvフック自体が未設定なのも一因)
- [x] 対策として、precommitの全フックを`bash -c 'cd DIR && make TARGET'`から、`Makefile.agg`経由の`make DIR/TARGET`形式に統一する。これは`direnv exec`を明示的に呼ぶので、シェルフックに依存せず動作する。コマンドライン変数(`SKIP_GITLEAKS=1`等)も`$(MAKE)`の再帰伝播で正しく渡ることを実機検証済み
- [x] この`cd DIR && make TARGET`問題はGo系(server/functions)だけでなくclient/terraform/homepageの全フックに共通する。ユーザー指示により、今回のタスクとして全フックまとめて書き換える(切り出さない)
- [x] goplsなどエディタのGo拡張はdirenv経由の環境変数を必ずしも拾わないため、この対応の範囲外(既知の限界として許容。`.vscode/settings.json`の`go.toolsEnvVars`で対応する手もあるが今回は見送り)
- [x] `.env.example`が存在せず、`.env`に何のキーが必要か新規参加者が把握できない状態だった。今回`.envrc`を整備するタイミングで合わせて整備する
- [x] `.envrc`はコミットしても`direnv allow`し忘れると静かに無効化される(正しさに関わる値がopt-inステップの裏に隠れるリスク)。緩和策として`make setup`に`direnv allow`を含め、golangci-lintのビルドGoバージョンとローカルGoバージョンを比較して警告するコマンドも用意する
- [x] precommitの各フックは元々`files: ^server/`等で対象ディレクトリの変更がある時だけ実行される仕組みが既にある(`pre-commit run --files spec/....md`で実機検証、無関係フックは`Skipped`になることを確認済み)。追加対応不要

### 対応方針
- [x] golangci-lint自体のバージョンアップ(v2.14.0)は本 task note の対応範囲外。別途「golangci-lintの新バージョン検知」task note で扱う

---

## Operation

### Task 1: server-secureをブロックしていたgrpc脆弱性(GO-2026-6348)の解消
- 本 task note の対象(GOTOOLCHAIN/precommit)とは無関係だが、`server/.envrc`が`files: ^server/`にマッチし`server-secure`(govulncheck)を必ず誘発するため、Task 2のコミットが通らずブロッカーとして先に対応
- 原因はコード変更ではなく脆弱性DB(vuln.go.dev)側が2026-09-15に`GO-2026-6348`を新規公開したこと。`google.golang.org/grpc`は2026-08-24時点のバージョン(v1.82.1)のまま
- `go get google.golang.org/grpc@v1.83.1 && go mod tidy`で解消、`govulncheck`で0件を確認済み
- 他モジュール(firebase/functions/gen-go)にはこの依存が無いことを確認済み
- 他のTaskとはコミットを分ける

### Task 2: `.envrc`にGOTOOLCHAINを動的に設定 + precommitフックをMakefile.agg経由に統一
- 各モジュールの`.envrc`に`go.mod`から動的に読む`GOTOOLCHAIN`を設定し、git追跡対象にする
- `.envrc`単体では`functions-secure`(gosec)のパニックが直らない(precommitがdirenvのシェルフックを経由しないため)ため、precommitフックをMakefile.agg経由(`make DIR/TARGET`)に統一する対応とセットで実施
- ついでに`.env`/`.env.example`を実際の利用箇所ベースで整理・新規作成

### Task 3: `direnv allow`の自動化とバージョン整合性チェック
- `server`/`firebase`/`functions`の`make setup`に`direnv allow .`を追加
- `scripts/check_golangci_lint_go_version.sh`を新規作成し、各Makefileの`lint`(functionsは`gosec`も)から呼ぶ。実機検証済み: バージョン一致時は無警告、`GOTOOLCHAIN=local`で意図的にズレさせると警告が出ることを確認
- `make aggregate`でMakefile.aggを再生成
