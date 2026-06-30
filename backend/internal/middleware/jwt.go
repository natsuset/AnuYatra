package middleware

import (
	"context"
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

type UserClaims struct {
	UserID string `json:"uid"`
	Role   string `json:"role"`
}

type contextKey string

const userClaimsKey contextKey = "user_claims"

func WithUserClaims(ctx context.Context, claims *UserClaims) context.Context {
	return context.WithValue(ctx, userClaimsKey, claims)
}

func GetUserClaims(ctx context.Context) (*UserClaims, bool) {
	claims, ok := ctx.Value(userClaimsKey).(*UserClaims)
	return claims, ok
}

func GenerateJWT(userID, role, secret string, expiry time.Duration) (string, error) {
	claims := jwt.MapClaims{
		"uid":  userID,
		"role": role,
		"exp":  time.Now().Add(expiry).Unix(),
		"iat":  time.Now().Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secret))
}

func ValidateJWT(tokenStr, secret string) (*UserClaims, error) {
	token, err := jwt.Parse(tokenStr, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("unexpected signing method")
		}
		return []byte(secret), nil
	})
	if err != nil {
		return nil, err
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok || !token.Valid {
		return nil, errors.New("invalid token claims")
	}

	uid, _ := claims["uid"].(string)
	role, _ := claims["role"].(string)
	if uid == "" {
		return nil, errors.New("missing uid in token")
	}

	return &UserClaims{UserID: uid, Role: role}, nil
}
