---
id: "0021"
status: "done"
priority: "medium"
assignee: null
epic: "🐤 リファクタリング"
dueDate: null
created: "2026-08-02T10:56:54.000Z"
modified: "2026-08-04T12:17:22.000Z"
completedAt: "2026-08-04T12:17:22.000Z"
labels: ["client"]
order: "Zz"
---
# クライアントのマルチプラットフォーム対応に向けた命名整理

## Overview

将来macOS版アプリを追加する予定があるため、今のうちにXcodeターゲット名・AppCoreパッケージ名を、複数プラットフォーム前提の実態に合った名前へ整理する。


## Details

命名方針: 配布物を作るターゲット(アプリ本体・Widget・将来のMac/Watch)は`YouDoYou`を残す(クラッシュログ/Console.app等、リポジトリ外の文脈で単体表示されても分かるように)。テストターゲットやSwiftPMパッケージ内ターゲットはXcode内部専用なので接頭辞を短縮/省略する。Bundle Identifierの`client`は「サーバーではなくクライアント」を表す独立した情報なので維持する。

### as is -> to be
Xcodeターゲット
- `YouDoYouClient` -> `YouDoYou_iOS`
- `YouDoYouClientUITests` -> `YouDoYou_iOS_UITests`

macOS,watchOS,Wigets追加時は以下のようになる
- `YouDoYou_macOS`
- `YouDoYou_macOS_UITests`
- `YouDoYou_watchOS`
- `YouDoYou_watchOS_UITests`
- `YouDoYou_Widgets`


### やること
ターゲット
- [x] ターゲット名リネーム — Task1, Task4
- [x] ディレクトリ名リネーム — Task2, Task5
- [x] スキーム/テストプランファイルリネーム — Task6

パッケージ
- [x] `AppCore`パッケージを`YouDoYou`パッケージにリネーム — 詳細は`## Operation`のTask8

その他
- [x] `YouDoYouClientTests`を削除する — 詳細は`## Operation`のTask3
- [x] Supported Destinationsから`Mac (Designed for iPad)`と`Apple Vision (Designed for iPad)`を外す — 詳細は`## Operation`のTask7
- [x] Debug/TestのBundle Identifierサフィックスを`.test`→`.dev`に変更 — 詳細は`## Operation`のTask9
  - Widget Extension側のBundle Identifierも追従が必要だが、`feature/live-activity-timer`は未マージのため今回のスコープ外。次回Widget再実装時に`.dev`で作る


### めも
- 将来のmacOS版はBundle IdentifierをiOS版と共有し、App Store ConnectのUniversal Purchaseで1つのアプリとして登録する想定(新規Bundle ID不要)


## Operation

### Task 1
Xcodeで、ターゲット`YouDoYouClient`を`YouDoYou_iOS`にリネーム

一部は手動で修正した

1. `client/YouDoYouClient.xcodeproj/project.pbxproj`
  - productName、remoteInfo(2箇所)
  - `TEST_HOST`3箇所 (YouDoYouClientTestsの設定)
  - `TEST_TARGET_NAME`3箇所(YouDoYouClientUITestsのビルド設定)

2. `client/YouDoYouClient_Test.xctestplan — targetForVariableExpansion.name`

### Task2
Xcodeで、物理フォルダ`client/YouDoYouClient/`を`client/YouDoYou_iOS/`にリネーム。
Xcodeが`PBXFileSystemSynchronizedRootGroup`の`path`は正しく追従したが、以下は追従せず手動で修正した

1. `client/scripts/copy-google-service-Info-plist.sh` — `GoogleService-Info.plist`のコピー元パスが旧フォルダ名のままで、ビルド時に`Command PhaseScriptExecution failed`のエラーになっていた
2. `client/YouDoYouClient.xcodeproj/project.pbxproj`
  - 「Copy GoogleService-Info.plist」ビルドフェーズの`inputPaths`(3箇所)
  - `INFOPLIST_FILE`(3箇所、旧フォルダ名のままだと次のビルドで別エラーになるところだった)

ビルド成功を確認済み

### Task3
Xcodeで、中身が空の`YouDoYouClientTests`ターゲットを削除

`project.pbxproj`側は綺麗に削除されたが、以下に参照が残ったので手動で削除した

1. `client/YouDoYouClient.xcodeproj/xcshareddata/xcschemes/YouDoYouClient_Test.xcscheme` — `TestableReference`ブロック
2. `client/YouDoYouClient_Test.xctestplan` — `testTargets`内のエントリ

ビルド成功を確認済み

### Task4
Xcodeで、ターゲット`YouDoYouClientUITests`を`YouDoYou_iOS_UITests`にリネーム

一部は手動で修正した

1. `client/YouDoYouClient.xcodeproj/project.pbxproj`
  - productName
  - `PRODUCT_BUNDLE_IDENTIFIER`(3箇所、`jp.co.youdoyou.YouDoYouClientUITests`のままだった)
2. `client/YouDoYouClient_Test.xctestplan` — `testTargets`内の`name`
3. `client/YouDoYouClient.xcodeproj/xcshareddata/xcschemes/YouDoYouClient_Test.xcscheme` — Task3で削除したはずの`YouDoYouClientTests`の`TestableReference`が復活していたので再度削除(Xcodeのローカルキャッシュが原因と思われる)

### Task5
Xcodeで、物理フォルダ`client/YouDoYouClientUITests/`を`client/YouDoYou_iOS_UITests/`にリネーム。今回は見落とし無く、`project.pbxproj`側も綺麗に更新された

ビルド成功を確認済み

### Task6
スキーム/テストプランファイルを`YouDoYou_iOS_Test`にリネーム

1. `client/YouDoYouClient_Test.xctestplan` → `client/YouDoYou_iOS_Test.xctestplan`
2. `client/YouDoYouClient.xcodeproj/xcshareddata/xcschemes/YouDoYouClient_Test.xcscheme` → `.../YouDoYou_iOS_Test.xcscheme`

参照元(`project.pbxproj`、スキーム内の`TestPlanReference`、`xcuserdata`内の`xcschememanagement.plist`)も合わせて更新

ビルド成功を確認済み

### Task7
Xcodeで、`YouDoYou_iOS`と`YouDoYou_iOS_UITests`両ターゲットのSupported Destinationsから、`Mac (Designed for iPad)`と`Apple Vision (Designed for iPad)`を削除(iPhone/iPadは維持)。

`SUPPORTED_PLATFORMS`、`SUPPORTS_MACCATALYST`、`SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD`、`SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD`が両ターゲットの全ビルド構成に追加された

ビルド成功を確認済み

### Task8
`AppCore`パッケージを`YouDoYou`パッケージにリネーム。

`AppCore`はXcodeのローカルパッケージ参照(`XCLocalSwiftPackageReference`)としては登録されておらず、`Packages`という同期フォルダの中身をXcodeが自動スキャンして見つけてるだけだった。ターゲットのような「Rename」機能は無いため、直接操作した

1. `git mv client/Packages/AppCore client/Packages/YouDoYou` — フォルダ移動(パス参照が他に無いため安全)
2. `client/Packages/YouDoYou/Package.swift` — `Package(name: "AppCore", ...)` → `Package(name: "YouDoYou", ...)`(ターゲット名`AppCore`・製品名`AppCore`・既存の`import AppCore`は変更なし)
3. `client/YouDoYouClient.xcodeproj/project.pbxproj` — 「Packages」フォルダの`membershipExceptions`内の`AppCore`を`YouDoYou`に変更
4. `client/YouDoYou_iOS_Test.xctestplan` — `AppCoreTests`の`containerPath`(`container:Packages/AppCore`→`container:Packages/YouDoYou`)

ビルド成功を確認済み

### Task9
Debug/TestのBundle Identifierを`jp.co.youdoyou.client.test`から`jp.co.youdoyou.client.dev`に変更(`project.pbxproj`の`PRODUCT_BUNDLE_IDENTIFIER`)。Release(`jp.co.youdoyou.client`)は変更なし

Firebaseコンソールで新Bundle ID(`jp.co.youdoyou.client.dev`)用のiOSアプリを登録し、新しい`GoogleService-Info.plist`を取得。`client/YouDoYou_iOS/env/plists/GoogleService-Info-dev.plist`(gitignore対象、ローカルのみ)を差し替え

ビルド成功を確認済み
