---
id: "20260705-001"
status: "done"
priority: "medium"
created: "2026-07-07T12:33:57.941Z"
modified: "2026-07-07T12:33:57.941Z"
completedAt: null
labels: []
order: "a0"
---

# 週次レポート機能

## 目的・背景

Firestoreのactivityデータを直近1週間分取得し、定量的な集計とLLMによる要約・定性コメントを生成して、結果をFirestoreに蓄積する。蓄積したレポートはhomepageのビルド時に参照し、最新レポートをページに組み込んで表示する。

---

## Task 1: ActivityRepositoryとFirestore実装を追加する

`server/internal/usecase/interface.go` に以下を追加する。

```go
type ActivityRepository interface {
    ListByDateRange(ctx context.Context, start, end time.Time) ([]schema.Activity, error)
}
```

`server/internal/repository/firestore_activity_repo.go` を新規作成し、`activities`コレクションを`startedAt`でレンジクエリ(`>= start`, `< end`)して実装する。

## Task 2: Report/ReportStatスキーマを追加する

`firebase/schema/firestore.yaml` に以下を追加する。

- `ReportStat`(集計用サブモデル): `domainId`, `activityCount`(integer)
- `Report`: `id`, `periodStart`(timestamp), `periodEnd`(timestamp), `activityCount`(integer, 合計), `stats`(array, item_model: ReportStat), `summary`(string, 活動サマリ), `comment`(string, 定性コメント), `createdAt`(server_timestamp)
- コレクション `reports`: path `reports/{reportID}`, model `Report`。ドキュメントIDは`periodStart`の日付文字列(`YYYY-MM-DD`)とする。

追加後、`make firebase/gen`(`go run ./generator/cmd/gen/main.go -target=go -schema=./schema/firestore.yaml`)を実行し、`server/gen/schema`配下のGoコードを再生成する。

## Task 3: ReportRepositoryを実装する

`server/internal/repository/firestore_report_repo.go` を新規作成し、`reports`コレクションへの`Save(ctx, report schema.Report) (string, error)`を実装する(ドキュメントIDは`report.ID`)。

## Task 4: ReportGeneratorUsecaseを実装する

`server/internal/usecase/report_generator.go` を新規作成する。

- 期間: 実行時点を基準に過去7日間(`periodEnd = now`, `periodStart = now.AddDate(0, 0, -7)`)
- `ActivityRepository.ListByDateRange`で該当期間のactivityを取得し、`domainId`ごとに件数・内容を集計する
- 集計結果とサンプルとなるactivity内容をプロンプトに組み込み、`genkit.GenerateData[ReportLLMOutput]`(`ReportLLMOutput{Summary, Comment}`)で活動サマリと定性コメントを生成する
- `ReportRepository.Save`で`schema.Report`を保存し、`reportID`を返す

## Task 5: reportGenerateFlowを定義してmain.goに組み込む

`server/cmd/server/main.go` に依存関係(ActivityRepository, ReportRepository, ReportGeneratorUsecase)を配線し、`reportGenerateFlow`を`genkit.DefineFlow`で定義する。エンドポイント `POST /v1/report/generate` を追加する。

## Task 6: Cloud SchedulerをTerraformに追加する

`terraform/modules/scheduler`を新規作成し、`google_cloud_scheduler_job`で週次(例: 毎週月曜9:00 JST)に`POST /v1/report/generate`を呼び出すジョブを定義する。OIDC認証には既存の`app_runner`サービスアカウント(`module.iam.app_runner_sa_email`)を使い、Cloud Run(`INGRESS_TRAFFIC_INTERNAL_ONLY`)を呼び出せることを確認する。`terraform/projects/dev/main.tf`にモジュールを追加する。

## Task 7: 最新レポート取得エンドポイントをserverに追加する

`ReportRepository`に`GetLatest(ctx context.Context) (*schema.Report, error)`(`reports`コレクションを`periodStart`降順で1件取得)を追加する。`server/internal/usecase/report_generator.go`または新規usecaseで参照し、`GET /v1/report/latest`エンドポイントを`main.go`に追加する(レポートが存在しない場合は404)。

## Task 8: 公開プロキシをfunctionsに追加する

`functions/handlers/github_webhook.go`と同じ構成(内部Cloud Runへメタデータサーバー経由のIDトークン付きでプロキシする)で、`functions/handlers/report.go`を新規作成する。`GET /report/latest`を公開エンドポイントとして受け、内部の`GET /v1/report/latest`にフォワードしてレスポンスをそのまま返す。認証不要の読み取り専用データのため、署名検証は行わない。`functions/init.go`に`functions.HTTP("ReportLatest", ...)`を登録する。

## Task 9: homepageで最新レポートを表示する

`homepage/content/_index.md`のfrontmatterに`report_feed`(Task 8で公開したFunctionsのURL)を追加する。`homepage/layouts/home.html`に、既存のBlogセクション(`resources.GetRemote` + `transform.Unmarshal`)と同じ手法で新しいセクションを追加し、ビルド時に`report_feed`を取得して直近レポートの`summary`・`comment`・`activityCount`等を表示する。取得に失敗した場合(未生成時など)はセクションを非表示にする。
