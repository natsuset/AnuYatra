package config

import (
	"os"
	"strconv"
	"strings"
)

type Config struct {
	Port           int
	DatabaseURL    string
	JWTSecret      string
	AllowedOrigins []string

	// OTP provider config (pluggable — Firebase, Twilio, MSG91, or mock)
	OTPProvider string // "mock" | "twilio" | "firebase" | "msg91"

	// File storage config (pluggable — S3, GCS, Firebase Storage, local)
	StorageProvider string // "local" | "s3" | "gcs" | "firebase"
	StorageBucket   string

	// Environment
	Env string // "development" | "staging" | "production"
}

func Load() *Config {
	return &Config{
		Port:           envInt("PORT", 8080),
		DatabaseURL:    envStr("DATABASE_URL", "postgres://localhost:5432/anuyatra?sslmode=disable"),
		JWTSecret:      envStr("JWT_SECRET", "dev-secret-change-in-production"),
		AllowedOrigins: strings.Split(envStr("ALLOWED_ORIGINS", "*"), ","),
		OTPProvider:    envStr("OTP_PROVIDER", "mock"),
		StorageProvider: envStr("STORAGE_PROVIDER", "local"),
		StorageBucket:   envStr("STORAGE_BUCKET", "anuyatra-uploads"),
		Env:            envStr("ENV", "development"),
	}
}

func (c *Config) IsDev() bool {
	return c.Env == "development"
}

func envStr(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func envInt(key string, fallback int) int {
	if v := os.Getenv(key); v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			return n
		}
	}
	return fallback
}
