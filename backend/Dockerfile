FROM golang:1.23-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /anuyatra-api ./cmd/server

FROM alpine:3.20
RUN apk --no-cache add ca-certificates
COPY --from=builder /anuyatra-api /anuyatra-api
EXPOSE 8080
ENTRYPOINT ["/anuyatra-api"]
