package handler

import (
	"errors"
	"net/http"

	"github.com/anuyatra/backend/internal/middleware"
	"github.com/anuyatra/backend/internal/model"
	"github.com/anuyatra/backend/internal/service"
)

var svc *service.Container

func requireClaims(w http.ResponseWriter, r *http.Request) (*middleware.UserClaims, bool) {
	claims, ok := middleware.GetUserClaims(r.Context())
	if !ok {
		writeError(w, http.StatusUnauthorized, model.ErrUnauthorized)
		return nil, false
	}
	return claims, true
}

func writeRepoError(w http.ResponseWriter, err error) {
	if err == nil {
		return
	}
	var apiErr *model.APIError
	if errors.As(err, &apiErr) {
		status := http.StatusInternalServerError
		switch apiErr.Code {
		case "NOT_FOUND":
			status = http.StatusNotFound
		case "UNAUTHORIZED":
			status = http.StatusUnauthorized
		case "FORBIDDEN":
			status = http.StatusForbidden
		case "CONFLICT":
			status = http.StatusConflict
		case "VALIDATION_ERROR":
			status = http.StatusBadRequest
		case "INVALID_OTP", "SESSION_NOT_FOUND":
			status = http.StatusUnauthorized
		}
		writeError(w, status, apiErr)
		return
	}
	writeError(w, http.StatusInternalServerError, model.ErrInternal)
}

func paginatedResponse(data any, total int) map[string]any {
	return map[string]any{"data": data, "total": total}
}
