---
id: "0032"
status: "done"
priority: "medium"
assignee: null
epic: "🐤 リファクタリング"
dueDate: null
created: "2026-09-26T14:36:36.000Z"
modified: "2026-10-09T02:07:39.000Z"
completedAt: "2026-10-09T02:07:39.000Z"
labels: ["firebase", "gen-go", "client", "server"]
order: "a0"
---
# Domain/Topicの概念をWorkTopicに再構成

## Overview

現在の`Domain`/`Topic`(Domain配下に埋め込みの子要素)というモデルを廃止し、階層を持たない単独概念`WorkTopic`に置き換える。「英語学習」のような大分類の下に教材ごとの`Topic`を作る設計から、教材そのものを独立した`WorkTopic`として扱う設計に変更する。

## Details

- [x] 命名・構造の方針を議論して決定済み(詳細はDetails末尾の決定事項を参照)
- [x] 実装方針を「既存Domain/Topicコードのリネーム」から「新規WorkTopicの並行構築」に変更(理由は決定事項参照)
- [x] `firebase/schema/firestore.yaml`に`WorkTopic`を新規モデルとして追加(既存`Domain`/`Topic`定義には触れない)
- [x] `firebase/generator`で`gen-go/schema/*.go`と`client/Packages/YouDoYou/Sources/AppCore/Generated/*.swift`に`WorkTopic`生成コードを追加
- [x] `server/cmd/seed/`に`work_topics`のseedデータを追加し、投入できるようにする
- [ ] `WorkTopic`の一覧/選択画面(`TopicSelectionView`相当)をデザインから作り直して新規開発する。あわせてRepository/State/ViewModel/UIを用意する
- [ ] `WorkLog`/`GithubPull`の参照を`domainId`+`topicId`から`workTopicId`に切り替え、既存`ReportViewModel`/`ReportView`を単一階層に改修する(`GroupingUnit`トグル廃止)。`server`側(`github_watcher.go`等)も追従
- [ ] `HomeView`配下の各コンポーネント(QuickStart/Stats等)を`WorkTopic`参照に修正する
- [ ] 旧`Domain`/`Topic`(`WorkTheme`)関連コード・Firestoreコレクションを削除する。既存データは破棄または手動で新UIから登録し直す

### 決定事項(2026-09-26)

- `Domain` → `WorkTopic`にリネーム。型名・Firestoreコレクション名などの内部名は`WorkTopic`、UI上の短縮表記は同じ語根の`Topic`/`Topics`を使う
- 旧`Topic`(Domain配下の子要素、embedded array)は廃止。階層を持たない単独概念にする
  - 理由: 「英語学習」のように教材ごとに分けたいケースは、教材自体を独立した`WorkTopic`に昇格させれば階層は不要。「YouDoYou Intelligence開発」のように分ける意味のないケースは元々1つのままでよい
- タグ機能は今回導入しない
  - 検討したが、1つの記録(WorkLog)に複数タグを付けると時間の按分が実質不可能(30分の作業に2タグ付けると集計上は両方30分やった扱いになる)なため、集計目的では意味をなさないと判断し見送り。必要になれば改めて設計する
- 命名の経緯: `Project`案(DDD用語と被るため`Domain`を却下して検討)は、この概念の実態が「取り組むべき対象(積極的に推進するプロジェクト)」ではなく「記録(WorkLog)の都合上の独立した区分」に過ぎないと気づいたため却下。教材1冊のような小さい単位と大きな開発プロジェクトを同列に扱う気持ち悪さは、この本質的なズレの症状の一つ。`WorkTheme`案は、アプリのタブ表示が英語のみで日本語に逃げられず、UIに「Theme」と出すと将来の配色テーマ(ダーク/ライトモード等)設定と紛らわしくなる懸念があったため撤回。型名とUI短縮表記を同じ語根`Topic`に揃えることで解決した
- **実装方針**: schema/生成コードは`WorkTopic`を新規追加した上で、clientは段階的に移行する。まずseedと新しい一覧/選択画面を追加(この間は旧Domain系画面も動く)、次に`WorkLog`/`GithubPull`の参照を`workTopicId`に切り替えつつ既存`ReportViewModel`/`ReportView`を単一階層に改修、最後に旧`Domain`/`Topic`(`WorkTheme`)関連コードとコレクションを削除する
  - 理由: 全UIをゼロから並行構築して最後に1回で切り替えるより、既存Reportを簡約化する形で改修する方が二重実装を避けられる。Reportはフラット化で`GroupingUnit`トグルと二階層集計を削る方向の変更であり、新規設計ではなく既存改修で足りる
  - 個人利用アプリでテストリリース段階のため、既存データ(Domain/Topic、および移行期間中に積み上がる`WorkLog`)は失っても問題ない。残したい場合はFirestoreを見ながら手動で登録し直す

### 調査メモ

- [x] 過去の`Activity`→`WorkLog`リネーム(spec/done/0027)の手順を確認。schema変更→generator再生成→server手書き修正→client手書き修正→過去specファイルの用語置換、という順で進めていた。**Task 4として過去specファイルの文言も書き換えていた**(spec/MEMO.md、当時のspec/0025・spec/done/0020・spec/done/0006など)
  - 今回は単純なリネームではなく構造変更(階層廃止)を伴うため、過去specの文言をそのまま`WorkTopic`に置換するのが適切とは限らない。過去specの扱いは着手前に方針を決める(旧`Domain`/`Topic`という語が指していた構造自体が変わるため、置換すると当時の文脈が不正確になる箇所がありうる)
- [x] client側のDomain/Topic関連ファイルを洗い出し、二階層構造への依存箇所を特定。特に以下が単純リネームでは済まない箇所
  - `DomainFormView.swift`: Domain単位(title/description/color)の入力に加えて、`TopicField`配列(title/imageUrl、画像アップロード付き)を動的に追加/削除するUIを持つ。フラット化後は1つの`WorkTopic`が持つフィールド(title/description/color/imageUrl)を統合する必要があり、「複数Topicをまとめて作る」UIそのものが不要になる
  - `DomainsView`/`DomainDetailView`/`DomainItem`/`TopicSelectionView`: いずれも「Domain一覧→各Domain内のTopicカード/行」という二階層の表示構造。フラット化すると単一階層の`WorkTopic`一覧表示に置き換わり、`TopicCard`/`DomainDetailTopicRow`のような子要素固有のコンポーネントは統合または削除が必要
  - `WorkLogDraftStore`: `activeDomainId`/`activeTopicId`の2つ、UserDefaultsキーも`timerDomainId`/`timerTopicId`の2つを個別管理。`workTopicId`1つに統合できる
  - `WorkLogDetailViewModel`/`WorkLogDetailView`/`TimerBanner`/`WorkLogCreateView`: いずれも`appState.domains.first{ id == domainId }`→`domain?.topics.first{ id == topicId }`という二段引きの解決ロジック。フラット化で1回のlookupに単純化される
  - `WorkLogQuickStartViewModel.recentTopics`: `domains.flatMap { $0.topics }`で二階層を手動でフラット化している処理。`appState`側が最初からフラットな`[WorkTopic]`になれば不要になる
- [x] **Report機能(`ReportViewModel`/`ReportView`)への影響が最も大きい。** `GroupingUnit`が`.domain`/`.topic`の2値を持ち、UIにトグルボタンがある。`.topic`モード時は`listSections`が「Domain登録順のセクション、各セクション内はTopicごとの行」という二階層の集計・表示ロジックになっている(`ReportViewModel.swift` L12-15, L48-55, L400-410付近)。フラット化するとこの「Domain単位/Topic単位で集計粒度を切り替える」というトグル自体の存在意義がなくなるため、単純な名前置換では対応できない
  - 並行構築方針により、この再設計を先に固める必要はなくなった。新しい`WorkTopic`用のReport相当画面をゼロから作る中で設計する(既存`ReportViewModel`は変更しない)

## Operation

### Task 1: schemaに`WorkTopic`を追加してコード再生成

`WorkTopic`モデルと`work_topics`コレクションをschemaに追加し、Go/Swiftの生成コードを作る。

### Task 2: `work_topics`のseedデータを追加

`server/cmd/seed/`に`work_topics`のseedを追加して投入できるようにする(案A: 旧domain 4件をフラットなWorkTopicにする)。

### Task 3: WorkTopicのデータ層を作る

`Domain`にWorkTopicモデルとRepositoryプロトコル、`Infrastructure`にRepository実装とConversionを追加する。

### Task 4: AppStateとAppRootにWorkTopicを配線する

`AppState`に`workTopics`を追加してobserveを開始し、`AppRoot`でRepositoryを注入する。既存`domains`は残す。

### Task 5: WorkTopicsViewを作る

WorkTopicを行リスト(サムネイル+タイトル+編集の「…」)で表示する選択画面を新規に作る。タップの枠・編集導線の見た目は用意するが、作業開始・編集の接続はTask 6以降で行う。Preview用にサンプルデータを渡せる形にする。

WorkLogの参照切り替えは、旧`domainId`/`topicId`を残したまま`workTopicId`(必須)を追加して段階的に移行する(各コミットが緑を保てるようにするため。big-bangにすると全読み手が同時に壊れる)。旧データは破棄・seed再投入前提。最後にまとめて旧フィールドと旧UIを削除する。

`workTopicId`は必須(非optional)にする。必須化すると`WorkLogDraftStore.post()`が必ずworkTopicIdを渡す必要があるため、「フィールド追加」と「記録フローの移行」は分離できず1コミットに統合する。

### Task 6: WorkLogを`workTopicId`に移行し、カードから作業開始を接続する

`WorkLog`に必須`workTopicId`を追加(旧`domainId`/`topicId`は残す)し、再生成・Domainモデル・Conversion・seed(`work_logs.yaml`に4トピックを偏り付きで割り当て)を追従。記録フロー(`WorkLogDraftStore`/`WorkLogCreateView`/`TimerBanner`/`AppRoot`)を`workTopicId`ベースに寄せ、`WorkTopicsView`のカードタップで作業開始を接続する。旧Domain UI(`DomainItem`/`DomainDetailView`)の記録導線は除去(殻はTask 10で削除)。

### Task 7: WorkTopicsViewへの導線を接続する

`HomeView`のQuickStartの「すべて」ボタンの遷移先を`TopicSelectionView`から`WorkTopicsView`に差し替える。

### Task 8: Reportを`workTopicId`ベースに移行する

`ReportViewModel`/`ReportView`を`workTopicId`ベースの単一階層に改修する(`GroupingUnit`トグル廃止)。

### Task 9: HomeViewを`workTopicId`ベースに移行する

`HomeView`配下(QuickStart/Stats等)の参照を`workTopicId`に合わせて修正する。

### Task 10: 旧Domain/Topic関連を削除する

旧`domainId`/`topicId`フィールド・旧Domain UI(`DomainsView`等)・Domainsタブ・`WorkTheme`/`WorkThemeRepository`・`AppState.domains`を削除。WorkLog表示系(Detail/Edit)をworkTopic表示に、`TimerLiveActivityAttributes`の`domainTitle`/`topicTitle`を`title`に統一。schema(`WorkTheme`/`Topic`/`domains`/`WorkLog`の旧フィールド)削除＋再生成、server seed追従。GithubPullは触らない(Task 11)。

### Task 11: GitHub webhook機能を削除する

未使用のGitHub webhook機能を丸ごと削除する(`github_watcher`/handler/repo/client/`main`配線・`GithubPull` schema・`github_pulls`コレクション・再生成)。

### Task 12: WorkTopicの作成/編集フォームを作る

`WorkTopicFormView`(create/edit)を新規作成する。入力はtitle/description/imageUrl(画像アップロード)。保存は`workTopicRepository.add/update`、画像は`uploadImage`。詳細画面は作らない。

### Task 13: WorkTopicsViewに作成/編集/削除の導線を配線する

`WorkTopicsView`に＋ボタン(作成フォーム)と行の「…」メニュー(編集/削除)を配線する。削除は確認アラート付きで`workTopicRepository.delete`。
### Task 14: QuickStartの画像タップで作業開始

`HomeView`のQuickStartの最近トピック画像をタップで`WorkLogCreateView`を開けるようにする。
