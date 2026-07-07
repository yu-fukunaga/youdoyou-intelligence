---
id: "20260705-001"
status: "done"
priority: "medium"
assignee: null
epic: null
dueDate: null
created: "2026-07-07T12:33:57.941Z"
modified: "2026-07-07T12:50:28.243Z"
completedAt: "2026-07-07T12:50:28.243Z"
labels: []
order: "a0"
---
# ローカルLLM開発環境

## 目的・背景

ローカル開発中は現状 Google AI (Gemini) を毎回叩いており、APIコストや通信レイテンシが発生する。Ollamaでローカルにモデルを動かし、ローカル開発時のみGenkitがそちらを向くようにすることで、オフライン・低コストに開発できるようにしたい。

---

## Task 1: Ollamaをインストールし、ローカルでモデルを起動する

Ollamaをローカル環境にインストールし、任意のモデル(例: llama3.2 など)をpullして `ollama serve` で起動できる状態にする。

### 作業ログ

まずはインストール
```
$ brew install ollama
```

起動
```
$ ollama serve
```

バックグラウンドサービスとして常時起動するなら
（コマンドを打ったターミナルを閉じても動く。Mac を再起動しても、自動的に Ollama が勝手に立ち上がる。）
```
$ brew services start ollama
```

デフォルト(推奨サイズ)のGemma 4を取得
```
$ ollama pull gemma4
```

返ってきた。
```
$ curl http://localhost:11434/api/chat -d '{
  "model": "gemma4",
  "messages": [{"role": "user", "content": "こんにちは"}],
  "stream": false,
  "think": false
}' | jq .
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   479  100   355  100   124    572    200 --:--:-- --:--:-- --:--:--   772
{
  "model": "gemma4",
  "created_at": "2026-07-05T05:29:29.218321Z",
  "message": {
    "role": "assistant",
    "content": "こんにちは！何かお困りのことはありますか？😊"
  },
  "done": true,
  "done_reason": "stop",
  "total_duration": 619236500,
  "load_duration": 272919833,
  "prompt_eval_count": 10,
  "prompt_eval_duration": 79318000,
  "eval_count": 12,
  "eval_duration": 265663000
}
```


## Task 2: LLMが応答するエンドポイントを作る(既存のGoogle AIで疎通確認)

`internal/usecase/github_watcher.go` と同じ「interface + private struct + コンストラクタ + Execute」の形で `server/internal/usecase/llm_ping.go` を新規作成する。`main.go` に直接ロジックを書かず、既存のusecase層のパターンに合わせる。

```go
package usecase

import (
    "context"

    "github.com/firebase/genkit/go/ai"
    "github.com/firebase/genkit/go/genkit"
)

type LlmPingUsecase interface {
    Execute(ctx context.Context, input *LlmPingInput) (*LlmPingOutput, error)
}

type LlmPingInput struct {
    Prompt string
}

type LlmPingOutput struct {
    Message string
}

type llmPingUsecase struct {
    g     *genkit.Genkit
    model ai.ModelRef
}

func NewLlmPingUsecase(g *genkit.Genkit, model ai.ModelRef) LlmPingUsecase {
    return &llmPingUsecase{g: g, model: model}
}

func (u *llmPingUsecase) Execute(ctx context.Context, input *LlmPingInput) (*LlmPingOutput, error) {
    opts := []ai.GenerateOption{ai.WithPrompt(input.Prompt)}
    if u.model.Name() != "" {
        opts = append(opts, ai.WithModel(u.model))
    }

    resp, err := genkit.Generate(ctx, u.g, opts...)
    if err != nil {
        return nil, err
    }
    return &LlmPingOutput{Message: resp.Text()}, nil
}
```

`model` はこの時点ではゼロ値の `ai.ModelRef{}` を渡す(まだOllamaが存在しないため、常にデフォルトモデル=Google AIが使われる)。

`main.go` の `// --- 2. Dependency Injection (DI) ---` セクションに追加する。

```go
llmPingUsecase := usecase.NewLlmPingUsecase(g, ai.ModelRef{})
llmPingFlow := genkit.DefineFlow(g, "llmPingFlow", llmPingUsecase.Execute)
```

ルーティングに追加: `r.Route("/v1", ...)` 内、`r.Get("/ping", ...)` の下に

```go
r.Post("/llm-ping", genkit.Handler(llmPingFlow))
```

### 動作確認

```
$ curl -X POST http://localhost:8081/v1/llm-ping -H "Content-Type: application/json" -d '{"data": {"Prompt": "こんにちは"}}'
```

でGoogle AI経由の応答が返ることを確認する。

## Task 3: Genkitでローカル実行時だけOllamaを使うようにする

`ollama.Ollama` は `github.com/firebase/genkit/go/plugins/ollama` で提供されており、`googlegenai.GoogleAI{}` と違って `genkit.WithDefaultModel(string)` にモデル名を渡すだけでは使えない。`Init` 後に `g` を渡して `ollamaPlugin.DefineModel(...)` を呼び、返ってきた `ai.Model` を明示的に参照する必要がある(`go doc` で確認済み)。

`server/internal/config/config.go` の `Config` に `IsDev() bool` メソッドを追加する(`Env == "development"` を判定)。呼び出し側で生の文字列比較をしなくて済むようにする。

Ollamaのサーバーアドレスとモデル名はハードコードせず、`Config` に環境変数として追加する。

```go
OllamaServerAddress string `envconfig:"OLLAMA_SERVER_ADDRESS" default:"http://127.0.0.1:11434"`
OllamaModel          string `envconfig:"OLLAMA_MODEL" default:"gemma4"`
```

`server/cmd/server/main.go` の `// --- 1. Init Plugins & Clients ---` セクションを次のように変更する。

```go
var g *genkit.Genkit
var localModel ai.ModelRef

if cfg.IsDev() {
    ollamaPlugin := &ollama.Ollama{ServerAddress: cfg.OllamaServerAddress}
    g = genkit.Init(ctx, genkit.WithPlugins(ollamaPlugin))

    model := ollamaPlugin.DefineModel(g,
        ollama.ModelDefinition{Name: cfg.OllamaModel, Type: "chat"},
        &ai.ModelOptions{Supports: &ai.ModelSupports{Multiturn: true}},
    )
    localModel = ai.NewModelRef(model.Name(), nil)
} else {
    g = genkit.Init(ctx,
        genkit.WithPlugins(&googlegenai.GoogleAI{}),
        genkit.WithDefaultModel("googleai/gemini-3.5-flash"),
    )
}
```

- `cfg.Env`(envconfigキー `ENV`)は現状コード上どこからも参照されておらず、`IsDev()` 経由で初めて分岐に使う。
- `localModel` はゼロ値(`Name()` が空文字)のままなら「ローカルモデル未設定」を表す。
- `OLLAMA_SERVER_ADDRESS` / `OLLAMA_MODEL` は未設定ならデフォルト値(`http://127.0.0.1:11434` / `gemma4`)が使われる。

Task 2で `usecase.NewLlmPingUsecase(g, ai.ModelRef{})` に渡していた第2引数を `localModel` に差し替える。`llmPingUsecase.Execute` 側(`internal/usecase/llm_ping.go`)は既に `u.model.Name() != ""` で分岐する実装になっているため、`llm_ping.go` 自体の変更は不要。

```go
llmPingUsecase := usecase.NewLlmPingUsecase(g, localModel)
llmPingFlow := genkit.DefineFlow(g, "llmPingFlow", llmPingUsecase.Execute)
```

- import追加: `"github.com/firebase/genkit/go/ai"`, `"github.com/firebase/genkit/go/plugins/ollama"`。どちらも `github.com/firebase/genkit/go` モジュールのサブパッケージなので `go.mod` への追加は不要。

`server/Makefile` の `dev-server` ターゲット(`GENKIT_ENV=dev GCP_PROJECT_ID=... go tool air`)に `ENV=development` を追加し、ローカル起動時のみ上記分岐に入るようにする。

### 動作確認

Task 2と同じcurlコマンドで、今度はOllama経由のローカルLLM(`gemma4`)からの応答が返ることを確認する。
