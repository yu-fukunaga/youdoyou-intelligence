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
