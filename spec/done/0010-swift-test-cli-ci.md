---
id: "0010"
status: "done"
priority: "medium"
assignee: null
epic: "🦔 品質基盤整備"
dueDate: null
created: "2026-07-28T03:58:27.000Z"
modified: "2026-09-26T07:40:09.000Z"
completedAt: "2026-09-26T07:40:09.000Z"
labels: ["client", ".github"]
order: "Zz"
---
# build/testコマンド整備とそのためのリファクタリング

## Overview

VSCode上でのみたくさんのエラーが出ている件を解消する。
VSCode上でもエラーが出ないようにし、さらに、テストやビルドをコマンド実行できるようにもしていく。

## Details

## Operation

### Task1
- client/Packages/YouDoYou/.build/workspace-state.jsonに、client/Packages/AppCore/.build/artifacts/...という存在しない古いパスがキャッシュされているのを削除。

memo:
> .buildは、Xcodeの通常ビルドでは使われません。
Xcodeがこのパッケージをローカル依存としてビルドする時は、独自のビルドシステムを使い、成果物は~/Library/Developer/Xcode/DerivedData/<プロジェクト名>-<ハッシュ>/以下(パッケージのチェックアウトやアーティファクトはDerivedData/.../SourcePackages/)に保存されます。完全に別のキャッシュ領域です。
client/Packages/YouDoYou/.buildが生成・使用されるのは、そのディレクトリで直接:
swift build / swift testをターミナルから実行した時(CLI)
SourceKit-LSPがそのパッケージを(buildServer.json無しで)自力でインデックスしようとする時
の2パターンだけです。


### Task 2
Makefileに build 系コマンドを整備する

### Task 3
- iOS専用、macOS専用のコードを減らす
- Compiler Control Statementsでプラットフォーム別ビルド対象を制御する
- Design Token(Semantic Color、Toolbar関連など)を定義する
- buildを通す

memo:
> Design Tokenは、「デザイン上の意図・役割」と「実際のプラットフォーム固有の値」を切り離すための仕組みです。
具体的に言うと、コードの中に#F2F2F7のような生の値や、UIColor.systemBackgroundのようなプラットフォーム固有の値を直接書くのではなく、「これは背景色です」という意味を持った名前(トークン)を1つ定義して、それを使い回します。実際の値は、その名前の定義の中に閉じ込めておきます。

### Task 4
警告を解消する

| 件数 | 内容 |
|---|---|
| 36 | `Text`の`+`演算子が非推奨(文字列補間を使うべき) |
| 16 | `main actor-isolated property 'field' can not be referenced from a nonisolated context` |
| 8 | `request(attributes:contentState:pushType:)`の戻り値が未使用 |
| 8 | 同メソッドが非推奨(`request(attributes:content:pushType:)`を使うべき) |
| 8 | `end(using:dismissalPolicy:)`が非推奨(`end(content:dismissalPolicy:)`を使うべき) |

memo:
> **`main actor-isolated property 'field' can not be referenced from a nonisolated context`について**
>
> 発生箇所: `DomainFormView.swift`の`TopicFieldRow`(`PhotosPicker`のlabelクロージャ内で`field.imageData`/`field.existingImageUrl`を参照)。
>
> 原因: `PhotosPicker`の該当`init`は`@preconcurrency nonisolated`が付いており、その結果`label`引数の型が`@Sendable () -> Label`(メインスレッドで動く保証のないクロージャ)になっている。一方`TopicFieldRow`は`View`なので`field`は暗黙に`@MainActor`(メインスレッド専用)。「メインスレッド保証のないクロージャ」から「メインスレッド専用のプロパティ」を参照しようとしたため警告になった。`@preconcurrency`が付いているおかげでエラーではなく警告で済んでいる。
>
> 対応: `body`の先頭(メインスレッド上で実行される場所)で`field.imageData`/`field.existingImageUrl`を一度ローカル変数に取り出し、クロージャの中ではそのローカル変数だけを参照するように変更。ローカル変数に取り出した時点でただの値になり、actor isolationの制約を受けなくなる。

memo:
> **`Text`の`+`演算子の非推奨(36件、ReportView.swiftのstyledDuration内、3行のみ)について**
>
> `Text + Text`は完全に非推奨(iOS/macOS/tvOS/watchOS全部)。Appleが提示する代替(文字列補間)は、部分ごとに違うスタイル(数字を太字、単位を控えめな色、など)を表現できないため単純には置き換えられない。
>
> 対応方針: `AttributedString`(1つの文字列の中で部分ごとに違う書式を持たせられる型)を組み立てて、それを`Text(_:)`に渡す形に書き換える。`AttributedString`同士の`+`は非推奨になっていない。SwiftUIをimportすると`.font`/`.foregroundColor`のようなSwiftUI用の属性がAttributedStringに設定できるようになる。
>
> 参考ドキュメント:
> - https://developer.apple.com/documentation/foundation/attributedstring
> - https://developer.apple.com/documentation/foundation/attributed-string-supporting-types

### Task 5
Makefileに test 系コマンドを整備する

### Task 6
- 現在失敗しているテストを修正する
- テストを通す

### Task 7
pre-commitを設定する
