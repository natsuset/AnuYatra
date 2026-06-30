package model

import "fmt"

// APIError is the standard error envelope returned to clients.
type APIError struct {
	Code    string `json:"code"`
	Message string `json:"message"`
}

func (e *APIError) Error() string {
	return fmt.Sprintf("%s: %s", e.Code, e.Message)
}

var (
	ErrNotFound        = &APIError{Code: "NOT_FOUND", Message: "resource not found"}
	ErrUnauthorized    = &APIError{Code: "UNAUTHORIZED", Message: "authentication required"}
	ErrForbidden       = &APIError{Code: "FORBIDDEN", Message: "insufficient permissions"}
	ErrConflict        = &APIError{Code: "CONFLICT", Message: "resource already exists"}
	ErrValidation      = &APIError{Code: "VALIDATION_ERROR", Message: "invalid request"}
	ErrRateLimited     = &APIError{Code: "RATE_LIMITED", Message: "too many requests"}
	ErrInternal        = &APIError{Code: "INTERNAL_ERROR", Message: "internal server error"}
	ErrInvalidOTP      = &APIError{Code: "INVALID_OTP", Message: "invalid or expired OTP"}
	ErrSessionNotFound = &APIError{Code: "SESSION_NOT_FOUND", Message: "session not found"}
)

func NotFoundError(entityType, id string) *APIError {
	return &APIError{
		Code:    "NOT_FOUND",
		Message: fmt.Sprintf("%s %s not found", entityType, id),
	}
}

func ConflictError(msg string) *APIError {
	return &APIError{
		Code:    "CONFLICT",
		Message: msg,
	}
}

func ValidationError(msg string) *APIError {
	return &APIError{
		Code:    "VALIDATION_ERROR",
		Message: msg,
	}
}
