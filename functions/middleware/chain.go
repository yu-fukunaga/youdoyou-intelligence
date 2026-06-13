package middleware

import (
	"context"
	"net/http"

	"github.com/cloudevents/sdk-go/v2/event"
)

// ─── HTTP Middleware ──────────────────────────────────────

type Middleware func(http.HandlerFunc) http.HandlerFunc

func ChainMiddleware(h http.HandlerFunc, middlewares ...Middleware) http.HandlerFunc {
	for _, middleware := range middlewares {
		h = middleware(h)
	}
	return h
}

// ─── CloudEvent Middleware ────────────────────────────────

type CloudEventHandlerFunc func(ctx context.Context, e event.Event) error

type CloudEventMiddleware func(CloudEventHandlerFunc) CloudEventHandlerFunc

func ChainCloudEventMiddleware(h CloudEventHandlerFunc, middlewares ...CloudEventMiddleware) CloudEventHandlerFunc {
	for _, middleware := range middlewares {
		h = middleware(h)
	}
	return h
}
