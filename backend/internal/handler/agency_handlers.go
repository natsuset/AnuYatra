package handler

import (
	"net/http"
	"strconv"
	"time"

	"github.com/google/uuid"

	"github.com/anuyatra/backend/internal/model"
)

func handleCreateAgency(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	var agency model.Agency
	if err := decodeJSON(r, &agency); err != nil {
		writeError(w, http.StatusBadRequest, model.ValidationError("invalid JSON body"))
		return
	}
	agency.ID = uuid.NewString()
	agency.AdminUserID = claims.UserID
	agency.CreatedAt = time.Now()
	agency.IsActive = true
	if err := svc.Agencies.Create(r.Context(), &agency); err != nil {
		writeRepoError(w, err)
		return
	}

	user, err := svc.Users.GetByID(r.Context(), claims.UserID)
	if err == nil {
		user.AgencyID = &agency.ID
		_ = svc.Users.Update(r.Context(), user)
	}
	writeJSON(w, http.StatusCreated, &agency)
}

func handleGetAgency(w http.ResponseWriter, r *http.Request) {
	if _, ok := requireClaims(w, r); !ok {
		return
	}
	a, err := svc.Agencies.GetByID(r.Context(), r.PathValue("id"))
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, a)
}

func handleUpdateAgency(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	id := r.PathValue("id")
	existing, err := svc.Agencies.GetByID(r.Context(), id)
	if err != nil {
		writeRepoError(w, err)
		return
	}
	if existing.AdminUserID != claims.UserID {
		writeError(w, http.StatusForbidden, model.ErrForbidden)
		return
	}
	var updated model.Agency
	if err := decodeJSON(r, &updated); err != nil {
		writeError(w, http.StatusBadRequest, model.ValidationError("invalid JSON body"))
		return
	}
	updated.ID = existing.ID
	updated.AdminUserID = existing.AdminUserID
	updated.CreatedAt = existing.CreatedAt
	if err := svc.Agencies.Update(r.Context(), &updated); err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, &updated)
}

func handleListAgencies(w http.ResponseWriter, r *http.Request) {
	if _, ok := requireClaims(w, r); !ok {
		return
	}
	p := parsePagination(r)
	var minRating *float64
	if v := r.URL.Query().Get("minRating"); v != "" {
		if f, err := strconv.ParseFloat(v, 64); err == nil {
			minRating = &f
		}
	}
	data, total, err := svc.Agencies.Search(r.Context(), queryStringPtr(r, "q"), queryStringPtr(r, "city"), minRating, p)
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, paginatedResponse(data, total))
}

func handleGetAgencyStats(w http.ResponseWriter, r *http.Request) {
	if _, ok := requireClaims(w, r); !ok {
		return
	}
	stats, err := svc.BrokerProfiles.GetAgencyStats(r.Context(), r.PathValue("id"))
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, stats)
}

func handleListAgencyBrokers(w http.ResponseWriter, r *http.Request) {
	if _, ok := requireClaims(w, r); !ok {
		return
	}
	data, total, err := svc.BrokerProfiles.ListByAgency(r.Context(), r.PathValue("id"), parsePagination(r))
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, paginatedResponse(data, total))
}
