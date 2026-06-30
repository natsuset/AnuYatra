package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/anuyatra/backend/internal/config"
	"github.com/anuyatra/backend/internal/handler"
	"github.com/anuyatra/backend/internal/inmem"
	"github.com/anuyatra/backend/internal/middleware"
)

func main() {
	cfg := config.Load()

	// DI: swap inmem.NewContainer for a postgres/mongo module when ready.
	container := inmem.NewContainer(cfg.JWTSecret, cfg.IsDev())

	mux := http.NewServeMux()

	mux.HandleFunc("GET /api/v1/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(`{"status":"ok"}`))
	})

	handler.RegisterRoutes(mux, container)

	stack := middleware.Chain(
		middleware.Logger,
		middleware.CORS(cfg.AllowedOrigins),
		middleware.Recoverer,
	)

	srv := &http.Server{
		Addr:         fmt.Sprintf(":%d", cfg.Port),
		Handler:      stack(mux),
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	go func() {
		log.Printf("Anuyatra API server starting on :%d (storage=in-memory)", cfg.Port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("server error: %v", err)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down server...")
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("forced shutdown: %v", err)
	}
	log.Println("Server stopped")
}
