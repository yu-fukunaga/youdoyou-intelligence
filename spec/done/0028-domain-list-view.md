---
id: "0028"
status: "done"
priority: "medium"
assignee: null
epic: "🍀 機能追加・改善"
dueDate: null
created: "2026-08-19T13:47:59.000Z"
modified: "2026-08-22T17:09:35.000Z"
completedAt: "2026-08-22T17:09:35.000Z"
labels: ["client"]
order: "a0"
---
# Domain一覧画面

## Overview

Domain(作業の管理単位)を一覧できる画面を作る。

---

## Details

- 新しいタブとして追加する(`RootView.swift`の`TabView`にHome/Reportsに続く3つ目のタブとして追加)
- 一覧はカード型のレイアウト
- カードをタップするとDomain詳細画面(既存の`DomainDetailView.swift`)に遷移する

## Operation

### Task1
- Domain: iconUrl廃止、colorを追加

###　Task2
Firebase Emulator関連
- starage emurator設定追加

### Task3
- DomainCreateViewをDomainFormViewにリネーム
- TopicSelectionViewからDomainFormViewへのボタン削除
- DomainsViewに移植

### Task4
DomainCreateViewModelを廃止する

### Task5
DomainFormViewを改良
- CreateView: ICONプレースホルダーをColorPicker(44x44)に置き換え
- Topics: 最低1件必須をやめ0件可に、初期表示も空(Add Topicで追加)に変更
- Create/Editで画面を共有するため`DomainFormMode`(`.create`/`.edit(Domain)`)を導入
- `TopicField`のidはEdit時に既存Topicの参照を保つため、行が生成された時点(Add Topic押下 or 既存Topicからのシード)で確定させる方式にした

### Task6
Topicへの画像登録
- Topic画像は固定パス`topics/{topicId}/icon`にアップロード(Domain単位のネストなし、Topic idがUUIDで一意なため不要と判断)
- アップロードタイミングは保存ボタン押下時。全Topic分アップロード完了後にFirestoreへ1回だけ書き込む(StorageとFirestore間の厳密なトランザクションはできないため、この順序で孤児ファイルのリスクを実務上許容範囲まで抑える方針とした)
- Topic行のUIを`PhotosPicker`に差し替え(`TopicFieldRow`として切り出し)、`DomainRepository`に`uploadTopicImage`を追加
