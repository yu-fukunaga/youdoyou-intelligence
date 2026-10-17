---
id: "0023"
status: "done"
created: "2026-08-02T11:43:15.000Z"
modified: "2026-08-02T14:35:32.000Z"
completedAt: "2026-10-17T06:57:30.000Z"
labels: ["client"]
epic: "🍀 機能追加・改善"
order: ""
---

# 環境別のビルド設定を整理する: Bundle ID・表示名・アイコン・配信・機密管理

## Overview

ホーム画面のアプリ表示名が、`YouDoYou_iOS`になっている。`YouDoYou` に変えたい。

また、配信(Release/Test/Debug)ごとにアプリアイコン画像を変えたい。

---

## Details

### BundleID整理

| 端末・配信 | 構成 | 接続先 | Bundle ID | plist |
|---|---|---|---|---|
| シミュレータ | Debug(Run) | エミュレーター | jp.co.youdoyou.client.local | emu |
| 有線実機 | Debug(Run、MAC_IP あり) | エミュレーター | jp.co.youdoyou.client.local | emu |
| TestFlight(dev) | Test(Archive) | dev | jp.co.youdoyou.client.dev | dev |
| TestFlight(prod) | Release(Archive) | prod | jp.co.youdoyou.client | prod(0038 まで dev の複製) |

- Debug の Bundle Identifier を jp.co.youdoyou.client.local に変えることで、有線の実機ビルドと、テストフライト配信のアプリが上書きし合わないようにできる。
- しかし、それにより、有線の実機からはdev環境接続でOAuth認証ができなくなる。
- そのため、有線の実機はエミュレーター環境専用とし、MAC_IP_ADDRESSの設定が必須となる。

### ウィジェットの Bundle ID

ウィジェットの Bundle ID は、同じ構成のアプリの Bundle ID で始まる必要がある。

| 構成 | アプリの Bundle ID | ウィジェットの Bundle ID |
|---|---|---|
| Debug | jp.co.youdoyou.client.local | jp.co.youdoyou.client.local.youdoyou-widgets |
| Test | jp.co.youdoyou.client.dev | jp.co.youdoyou.client.dev.youdoyou-widgets |
| Release | jp.co.youdoyou.client | jp.co.youdoyou.client.youdoyou-widgets |


### ビルド番号

- `CFBundleVersion` は数字とドットのみ。`local` や英字を含む値、コミットハッシュは使えない。
- 形式は `YYYYMMDDHHMM`(日時)に統一する。ローカル・CI で同じ形式を使う。
- ローカルと CI の区別は番号に持たせない。必要なら Makefile の出力や TestFlight の説明欄で示す。

### アプリ表示名/アイコン
- 端末に表示されるアプリ名は CFBundleDisplayName で設定する
- アプリアイコンは`ASSETCATALOG_COMPILER_APPICON_NAME`で設定する。

### 配信方針(dev / prod)
- dev(Test): ローカルの make コマンドからも配信できるようにする。

### 機密・設定値の管理
- 準機密(`GoogleService-Info-*.plist`)は 1Password を正とし、リポジトリには入れない。ローカルは make で取得する。emuは対象外。
- MAC_IP_ADDRESS は実機の Debug 用のローカル値なので、CI には不要。


## Operation

### Task1: 表示名を設定する
- Xcode で表示名を設定し、Info.plist の一部キーをビルド設定(`INFOPLIST_KEY_*`)へ移した

### Task2: Debug の Bundle ID を .local に変える
- Debug の Bundle Identifier を jp.co.youdoyou.client.local に変える
- emu の plist の BUNDLE_ID は `.local` に合わせる
- ウィジェットのバンドルIDも変更。

Memo: 有線実機でTestUser Loginが NetworkError(-1009)になった。
- 試したこと1: 最近 `brew upgrade` を実行した。node が更新されていたかどうかはわからんが、macOS ファイアウォールで、一つのnode が「着信接続を許可」になってなかった。おそらくそれが最新の node で、それの許可が必要だったのかと思う。
- 試したこと2: それでも変わらずNetworkErrorであった。今度はiPhoneのローカルネットワークの許可設定を確認した。YouDoYouアプリは許可されていたが、バンドルIDを変える前にビルドしたYouDoYouアプリと重複していたためか、新しいバンドルIDの方には許可されてなかったし、許可するかのダイアログも出てなかった。古いバンドルIDのビルドも含めアプリを全て削除してから、 `.local` のアプリをビルドしなおした。そしたら解消した。

### Task3: アプリ表示名とアイコンを設定する
- アイコンを設定する

### Task4: DEVELOPMENT_TEAM を xcconfig から削除
- Debug / Test / Release の xcconfig から `DEVELOPMENT_TEAM` を削除する
- pbxproj に設定がなかったアプリの Debug / Release に `DEVELOPMENT_TEAM` を追加する
- `xcconfig.example` を `Debug.xcconfig.example` に改名し、`MAC_IP_ADDRESS` だけにする

### Task5: env の配置を移動
- `YouDoYou_iOS/env/` を `client/env/` に移す(plists は共有、xcconfigs は `ios/` 配下)
- pbxproj に `env` グループと xcconfig のファイル参照を追加し、Debug / Release / Test の「Based on」をそれに切り替える
- pbxproj のビルドフェーズ入力とコピースクリプトの plist パスを直す
