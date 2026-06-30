.PHONY: run build test lint docker-up docker-down

run:
	go run ./cmd/server

build:
	go build -o bin/anuyatra-api ./cmd/server

test:
	go test ./...

lint:
	golangci-lint run ./...

docker-up:
	docker compose up -d --build

docker-down:
	docker compose down

migrate-up:
	@echo "Run migrations (tool TBD — golang-migrate, goose, or atlas)"

tidy:
	go mod tidy
