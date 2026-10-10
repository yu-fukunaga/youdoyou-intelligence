---
id: "0031"
status: "done"
priority: "medium"
assignee: null
epic: "🐤 リファクタリング"
dueDate: null
created: "2026-09-26T12:12:28.000Z"
modified: "2026-10-03T09:47:06.030Z"
completedAt: "2026-10-03T09:47:06.030Z"
labels: ["client"]
order: "Zw"
---
# AppCoreをターゲット分割してSwiftUI Previewsを使えるようにする

## Overview

`AppCore`がFirebase(特にFirestore)に依存しているため、SwiftUI PreviewsがJITリンクエラーで動作しない。Firebase依存コードとUI/ドメインコードをターゲットレベルで分離し、Previewsを実用的に使えるようにする。

---

## Details

### 調査結果
- [x] 事象: `AppCore`内の任意のファイルをPreviewしようとすると`JITError: Runtime linking failure`(`_OBJC_CLASS_$_FIRFirestore`等のシンボルが解決できない)で失敗する
- [x] ファイル単位ではなくターゲット単位の問題。`WorkLogCard.swift`自体はFirebaseをimportしていないが、`AppCore`という同一ターゲット内にFirebase依存コードがあるため、Preview時にターゲット全体の依存グラフ(Firebase各種の静的ライブラリ)がJITリンクされ失敗する
- [x] `Package.swift`の`AppCore`ライブラリを`type: .dynamic`にする対策を試したが効果なし(Firebase側の依存が引き続きstaticにmergeされる)
- [x] Xcodeの「Legacy Previews Execution」設定は今回のXcodeバージョンに存在せず
- [x] Address Sanitizerは元々無効化されており対象外
- [x] これはfirebase-ios-sdk側で何年も報告され続けている既知の問題(GitHub issue #6375, #8005, #6552, #16467等)。FirestoreのコアがC++実装でObjective-Cブリッジを介しており、SwiftUI PreviewsのJIT実行機構との相性が根本的に悪い。うちの設定固有の問題ではない
- [x] 対策はSwiftPMのターゲット分割で十分(パッケージ分割は不要)。JIT/ビルドのリンク境界はターゲット(モジュール)単位であり、パッケージ単位ではないため
- [x] 生成コード(`Domain`/`WorkLog`等、`firebase/generator`が生成)は`@DocumentID`等のFirestore専用プロパティラッパーを直接持っており、これがFirebase依存の直接原因。DBスキーマとドメインモデルは本来同一である必要はなく、ドメインモデルは手書きにする
- [x] DTO→ドメインの変換コードは`Infrastructure`のrepository実装内に手書きし、スキーマの破壊的変更はその変換コードのコンパイルエラーで検知する(非破壊的変更は自動追従を強制しない、人間判断でよい)
- [x] 想定より広範囲: `AppState`/`AuthState`/`WorkLogDraftStore`(State/Store層)と4つのViewModel(`WorkLogViewModel`等)も直接`import Firebase*`している
  - `ListenerRegistration`(Firebase固有の型)をViewModelがそのままプロパティとして保持している箇所が複数ある → Firebase非依存の購読解除の仕組みに置き換える必要あり
  - `AuthState`はrepository抽象化が無く`Auth.auth()`/`GIDSignIn.sharedInstance`を直接呼び、Firebase純正の`User`型をそのまま公開している → 新規に`AuthRepositoryProtocol`+ドメインレベルのユーザー型が必要
  - 各ViewModel/Stateの初期化子にある`= WorkLogRepository()`等のデフォルト引数も、`AppState`と同様に除去が必要
- [x] ViewModel(`ObservableObject`)とStore(`@Observable`)が混在しているが、ViewModel→Store統一は別軸の話として今回は着手しない(Firebase切り離しの設計はどちらのパターンでも同じなので、先にやる必要はない)。今回は現状のパターンのまま、まとめてFirebase依存を外す

### 決定した設計(4ターゲット構成、`client/Packages/YouDoYou`内)
- [x] `Domain`: 手書きドメインモデル + repositoryプロトコル。Firebase非依存、Foundationのみ
- [x] `Presentation`: Views/ViewModel/State/Store。`Domain`のみに依存、Firebase非依存
- [x] `Infrastructure`: Firestore DTO(`firebase/generator`が生成) + repository実装。`Domain`に依存し、Firebaseをimport
- [x] `AppRoot`(既存`AppCore`ターゲットをリネームして薄いコンポジションルートとして存続): `Presentation`と`Infrastructure`の両方に依存する唯一の場所。`AppState(repository: WorkThemeRepository())`のように実際の実装を組み立て、`RootView`を提供する(Goの`main.go`に相当)。リネームはViews移動後(Task 11)に行う(それまでは実態が伴っていない)。`YouDoYouClient.xcodeproj`がproduct名`AppCore`を参照しているため、リネーム時はXcode側の追従も必要
- [x] `AppState`等のinitからデフォルト値(`= WorkThemeRepository()`)を除去し、必須引数にする(循環依存回避、コンポジションルートでのみ組み立てる)
- [x] アプリターゲット(`YouDoYou_iOS`)は`AppRoot`に加えて、`FirebaseCore`/`GoogleSignIn`を引き続き直接importする(AppDelegateのclientID取得・OAuth URLハンドリングはアプリライフサイクル固有の関心事で、パッケージ構造の変更と無関係)
- [x] `firebase/generator`のコード生成ロジック自体(パース・テンプレート構造)には手を入れない。ただしSwift出力先ディレクトリの変更と、モデル名リネーム(後述)への追従は行う

### DTOとドメインモデルの型名衝突
- [x] 根本原因は「`Domain`ターゲット自身の中に、ターゲット名と全く同じ名前の型`Domain`(手書きドメインモデル)がある」という自己言及的な衝突。Swiftは`import Domain`した時点で型`Domain`を無条件にスコープへ引き込むため、`Infrastructure`側で`Domain.WorkLog`のように書いても、`Domain`という識別子が「モジュール」ではなく「型`Domain`」だと解釈されてしまい、`.WorkLog`が見つからずエラーになる(`Topic`/`WorkLog`自体が独立して衝突しているわけではない。)
- [x] SwiftPMのmoduleAliasesは同一パッケージ内のターゲット間依存には使えない(外部パッケージの`.product(...)`専用)ため不採用
- [x] `Domain`ターゲット名自体を変える案も検討したが、ターゲット名`Domain`は維持したい意向のため不採用
- [x] 最終的に、手書きドメインモデルの型名を`Domain`→`WorkTheme`にリネームすることで、ターゲット名`Domain`と型名の自己衝突を解消する方針に決定。あわせてFirestoreスキーマ(`firebase/schema/firestore.yaml`)側のモデル名も`Domain`→`WorkTheme`にリネームし、DTOと手書きモデルの呼び名を揃える。Firestoreのコレクション名(`domains`)自体は変えない
- [x] `Topic`/`WorkLog`はどちらの型名もリネーム不要(元々衝突の原因ではなかったため)
- [x] `firebase/generator`のコード生成ロジック自体(命名ロジック)は変更せず、スキーマ側のモデル名をそのまま反映するだけ
- [x] このリネームはGo側の生成コード(`gen-go/schema/*.go`)にも波及し、`server/cmd/seed/main.go`(唯一のGo側消費コード)の追従が必要

---

## Operation

### Task 1: スキーマの`Domain`モデル名を`WorkTheme`にリネーム
- `firebase/schema/firestore.yaml`のモデル名を`Domain`→`WorkTheme`にリネーム(コレクション名`domains`は変えない)。`Topic`/`WorkLog`はリネームしない
- 生成structを参照している既存`AppCore`配下の全ファイル(Repository・State・Store・ViewModel・Views・テスト)の型参照を新しいDTO名に追従。

### Task 2: `Domain`ターゲットを空で新設
- `Package.swift`に`Domain`ターゲットを追加(依存はFoundationのみ)

### Task 3: リスナー抽象化プロトコルを`Domain`ターゲットに追加
- `ListenerRegistration`の代替となる、Firebase非依存の`remove()`のみ持つプロトコルを新設

### Task 4: 手書きドメインモデルを`Domain`ターゲットに追加
- `WorkTheme`/`Topic`/`WorkLog`を、Firebaseの`@DocumentID`/`@ServerTimestamp`を持たないプレーンな`Codable, Identifiable, Sendable`として追加
- 対象はUI/State/ViewModelから実際に参照されているモデルのみ(`Member`/`Thread`/`GithubPull`はclient未使用のため対象外)

### Task 5: repositoryプロトコルを`Domain`ターゲットに追加
- `WorkThemeRepositoryProtocol`/`WorkLogRepositoryProtocol`を、Task 4の手書きモデルとTask 3のリスナー抽象化を使うシグネチャで追加
- 設計方針: DDDのRepositoryパターンに寄せ、生成ロジック(ID採番等)はエンティティ側に持たせ、Repositoryは`add`/`update`で完成済みエンティティを受け取るだけにする(個別フィールド版の`create(title:description:...)`は廃止し、`add`/`update`を対称にする)
  - ID採番をFirestoreのDocument自動採番からクライアント側生成(UUIDv7)に変更。`WorkTheme`/`WorkLog`の`init`で`id`にUUIDv7のデフォルト値を持たせる
  - UUIDv7はFoundation標準にないため、外部パッケージを追加せず`Domain`ターゲット内に自前実装する

### Task 6: `Presentation`/`Infrastructure`ターゲットを空で新設
- `Package.swift`に両ターゲットを追加。`Presentation`は`Domain`のみに依存、`Infrastructure`は`Domain`+Firebase各種に依存
- ほぼ空の状態でのリネームなので、以降のタスクは最初からこの名前で書く

### Task 7: 生成DTO(`Generated/*.swift`)を`Infrastructure`へ移動
- `firebase/generator/cmd/gen/main.go`のSwift出力先を`AppCore/Generated`から`Infrastructure/Generated`に変更
- `make gen/swift`を実行してDTO(`WorkTheme`/`Topic`/`WorkLog`/`Member`/`Thread`/`GithubPull`)を新しい場所に生成し直す(内容は変更しない)
- 旧場所(`AppCore/Generated/*.swift`)を削除

### Task 8: `WorkThemeRepository`/`WorkLogRepository`の実装を`Infrastructure`に追加
- `Domain`ターゲットのプロトコルに準拠する実装を新規に書く(既存`AppCore/Repositories/`の実装はまだ削除しない)
- DTO⇔手書きモデルの変換コードをここに書く

### Task 9: `User`型と`AuthRepositoryProtocol`を`Domain`ターゲットに追加
- `User`型(プレーンな`Identifiable, Sendable`)と、`AuthRepositoryProtocol`を`Domain`ターゲットに追加

### Task 10: `AuthRepository`を`Infrastructure`に追加
- `Infrastructure`に`FirebaseAuth`/`GoogleSignIn`をラップする`AuthRepository`を追加(既存`AuthState`はまだ変更しない)

### Task 11: UI層(State/Store/ViewModel/Views)を`Presentation`へ移動し旧ファイルを削除
- State/Store/ViewModel/Viewsを`AppCore`から`Presentation`へ移動(新規作成と同時に旧ファイルを削除。並行コピーで重複を残さない)
- `import Firebase*`を除去し、protocol・手書きモデル・`ListenerHandle`経由に書き換える。DTOの型(`WorkTheme`等)はドメインモデル(`Domain.WorkTheme`等)に置き換える
- 初期化子のデフォルト値(`= WorkThemeRepository()`等)を除去し必須引数にする
- State/ViewModel/Viewは相互参照しており、型がDTO→ドメインモデルに変わるため分割できない。1コミットでまとめて移行し、各コミットがビルド・動作する状態を保つ
- コンポジションルート(`AppCore/AppCore.swift`の`RootView`)の配線も同コミットで更新する

### Task 12: `AppCore`を`AppRoot`にリネーム
- この時点で`AppCore`は薄いコンポジションルートの実態になっているため、名前を実態に合わせる
- `Package.swift`のターゲット名・product名変更に加え、`YouDoYouClient.xcodeproj`側がproduct名`AppCore`を参照しているため、Xcodeプロジェクト側の追従も必要

### Task 13: ビルド・テスト・Preview動作確認
