---
id: "0002-makefile-tab-completion"
status: "done"
priority: "medium"
assignee: null
epic: null
dueDate: null
created: "2026-07-25T01:56:51.000Z"
modified: "2026-07-27T00:29:16.448Z"
completedAt: "2026-07-27T00:29:16.448Z"
labels: ["scripts"]
order: "a1"
---
# Makefileのタブ補完対応

## 目的・背景

ルートの`Makefile`は`server/%:`のようなパターンルールで`server/functions/firebase/terraform`配下のMakefileターゲットをルートから呼び出せるようにしている。しかしパターンルール(`%`)はシェルのタブ補完候補として認識されず、`make server/`まで打っても候補が出ない。実際に`make s`+Tabを試すと、makeターゲットではなくカレントディレクトリの`scripts/ server/ spec/`が候補に出てしまう。

タブ補完を効かせるには、パターンルールではなく具体的なターゲット名がファイル中にテキストとして存在する必要がある。動的に`$(shell)`/`$(eval)`でmakeの内部データベース上にのみ実ターゲットを生成する方式も試したが、`Makefile.agg`に`server/dev:`のような具体的なターゲットを直接書いて`include`したところタブ補完に出ることを確認済み(`make`のみでターゲット一覧に`server/dev`が表示された)。この検証結果をもとに、各サブディレクトリのMakefileターゲットを省略せず書き出した`Makefile.agg`を自動生成し、ルートMakefileからincludeする方式を採用する。

---

## Task 1: 生成スクリプトの作成

`scripts/`配下に、`server`/`functions`/`firebase`/`terraform`各ディレクトリの`Makefile`をスキャンし、各ターゲット名を抽出して、`Makefile.agg`に

```makefile
server/build:
	direnv exec server $(MAKE) -C server build
```

のような具体的な転送ルールを1ターゲットずつ書き出すスクリプトを作成する。ファイル冒頭に「自動生成ファイルにつき手動編集禁止」の旨を明記する。

## Task 2: ルートMakefileの修正

現在の`server/%:` `functions/%:` `firebase/%:` `terraform/%:`パターンルール(および対応する`.PHONY`宣言)を削除する。代わりに`Makefile.agg`を`include`する行を追加し、Task 1のスクリプトを実行する`aggregate:`ターゲットを追加する。

## Task 3: 初回生成とコミット

`make aggregate`を実行して`Makefile.agg`を全ターゲット分生成し、内容を確認する。`Makefile.agg`は生成物だがタブ補完を効かせるためにgit管理下に置き、コミットする運用とする。

## Task 4: 動作確認

`make`単体、および`make server/`, `make functions/`, `make firebase/`, `make terraform/`それぞれでタブ補完が実ターゲットを候補として表示することを確認する。あわせて`make server/build`などが従来通り`direnv exec`経由でサブディレクトリのMakefileに転送されることを確認する。

---

## 補足: `include` と `-include` の使い分け

ルートMakefileでは`-include .env`(ハイフンあり)に対し`include Makefile.agg`(ハイフンなし)としている。

- `include`: 対象ファイルが存在しない場合、makeはエラーで停止する
- `-include`: 対象ファイルが存在しなくても無視して続行する

`.env`はgitignoreしていて、ローカルに無いこともある任意ファイルなので`-include`、`Makefile.agg`はgitにコミットされ常に存在するはずの生成物なので、万一欠けていたらすぐ気づけるよう`include`(エラーで停止)を使う、という判断。
