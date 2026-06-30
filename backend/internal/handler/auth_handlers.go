package handler

import (
	"errors"
	"net/http"
	"time"

	"github.com/google/uuid"

	"github.com/anuyatra/backend/internal/middleware"
	"github.com/anuyatra/backend/internal/model"
)

func handleSendOTP(w http.ResponseWriter, r *http.Request) {
	var body struct {
		PhoneNumber string         `json:"phoneNumber"`
		Role        model.UserRole `json:"role"`
	}
	if err := decodeJSON(r, &body); err != nil {
		writeError(w, http.StatusBadRequest, model.ValidationError("invalid JSON body"))
		return
	}
	if body.PhoneNumber == "" {
		writeError(w, http.StatusBadRequest, model.ValidationError("phoneNumber is required"))
		return
	}
	if !body.Role.IsValid() {
		writeError(w, http.StatusBadRequest, model.ValidationError("invalid role"))
		return
	}

	sessionID, err := svc.Auth.SendOTP(r.Context(), body.PhoneNumber, body.Role)
	if err != nil {
		writeRepoError(w, err)
		return
	}

	resp := map[string]any{
		"sessionId": sessionID,
		"message":   "OTP sent",
	}
	if svc.IsDev {
		resp["otp"] = "123456"
	}
	writeJSON(w, http.StatusOK, resp)
}

func handleVerifyOTP(w http.ResponseWriter, r *http.Request) {
	var body struct {
		SessionID   string         `json:"sessionId"`
		PhoneNumber string         `json:"phoneNumber"`
		OTP         string         `json:"otp"`
		Role        model.UserRole `json:"role"`
	}
	if err := decodeJSON(r, &body); err != nil {
		writeError(w, http.StatusBadRequest, model.ValidationError("invalid JSON body"))
		return
	}

	ok, err := svc.Auth.VerifyOTP(r.Context(), body.SessionID, body.PhoneNumber, body.OTP)
	if err != nil {
		writeRepoError(w, err)
		return
	}
	if !ok {
		writeError(w, http.StatusUnauthorized, model.ErrInvalidOTP)
		return
	}

	user, err := svc.Users.GetByPhone(r.Context(), body.PhoneNumber)
	needsProfile := false
	if err != nil {
		var apiErr *model.APIError
		if !errors.As(err, &apiErr) || apiErr.Code != "NOT_FOUND" {
			writeRepoError(w, err)
			return
		}
		user = &model.AppUser{
			UID:         uuid.NewString(),
			PhoneNumber: body.PhoneNumber,
			DisplayName: "",
			Role:        body.Role,
			CreatedAt:   time.Now(),
			IsActive:    true,
		}
		if err := svc.Users.Create(r.Context(), user); err != nil {
			writeRepoError(w, err)
			return
		}
		needsProfile = true
	}

	access, err := middleware.GenerateJWT(user.UID, string(user.Role), svc.JWTSecret, svc.JWTAccessExpiry)
	if err != nil {
		writeError(w, http.StatusInternalServerError, model.ErrInternal)
		return
	}
	refresh, err := middleware.GenerateJWT(user.UID, string(user.Role), svc.JWTSecret, svc.JWTRefreshExpiry)
	if err != nil {
		writeError(w, http.StatusInternalServerError, model.ErrInternal)
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"accessToken":       access,
		"refreshToken":      refresh,
		"user":              user,
		"needsProfileSetup": needsProfile,
	})
}

func handleRefreshToken(w http.ResponseWriter, r *http.Request) {
	var body struct {
		RefreshToken string `json:"refreshToken"`
	}
	if err := decodeJSON(r, &body); err != nil || body.RefreshToken == "" {
		writeError(w, http.StatusBadRequest, model.ValidationError("refreshToken is required"))
		return
	}

	claims, err := middleware.ValidateJWT(body.RefreshToken, svc.JWTSecret)
	if err != nil {
		writeError(w, http.StatusUnauthorized, model.ErrUnauthorized)
		return
	}

	access, err := middleware.GenerateJWT(claims.UserID, claims.Role, svc.JWTSecret, svc.JWTAccessExpiry)
	if err != nil {
		writeError(w, http.StatusInternalServerError, model.ErrInternal)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"accessToken": access})
}

func handleLogout(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"message": "logged out"})
}
