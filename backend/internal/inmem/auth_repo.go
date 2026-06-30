package inmem

import (
	"context"
	"crypto/rand"
	"fmt"
	"sync"
	"time"

	"github.com/google/uuid"

	"github.com/anuyatra/backend/internal/model"
)

type otpSession struct {
	phone     string
	role      model.UserRole
	code      string
	expiresAt time.Time
	used      bool
}

type AuthRepo struct {
	mu       sync.RWMutex
	sessions map[string]*otpSession
	isDev    bool
}

func NewAuthRepo(isDev bool) *AuthRepo {
	return &AuthRepo{
		sessions: make(map[string]*otpSession),
		isDev:    isDev,
	}
}

func (r *AuthRepo) SendOTP(_ context.Context, phone string, role model.UserRole) (string, error) {
	code := "123456"
	if !r.isDev {
		code = randomOTP()
	}
	sessionID := uuid.NewString()
	r.mu.Lock()
	defer r.mu.Unlock()
	r.sessions[sessionID] = &otpSession{
		phone:     phone,
		role:      role,
		code:      code,
		expiresAt: time.Now().Add(5 * time.Minute),
	}
	return sessionID, nil
}

func (r *AuthRepo) VerifyOTP(_ context.Context, sessionID, phone, code string) (bool, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	s, ok := r.sessions[sessionID]
	if !ok {
		return false, model.ErrSessionNotFound
	}
	if s.used {
		return false, model.ErrInvalidOTP
	}
	if time.Now().After(s.expiresAt) {
		return false, model.ErrInvalidOTP
	}
	if s.phone != phone || s.code != code {
		return false, nil
	}
	s.used = true
	return true, nil
}

func (r *AuthRepo) DemoOTP() string {
	if r.isDev {
		return "123456"
	}
	return ""
}

func randomOTP() string {
	b := make([]byte, 3)
	_, _ = rand.Read(b)
	n := int(b[0])<<16 | int(b[1])<<8 | int(b[2])
	return fmt.Sprintf("%06d", n%1000000)
}
