package handler

import (
	"net/http"
	"strconv"
	"time"

	"github.com/google/uuid"

	"github.com/anuyatra/backend/internal/model"
	"github.com/anuyatra/backend/internal/repository"
)

// --- Parent profiles ---

func handleGetMyParentProfile(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	p, err := svc.ParentProfiles.GetByUserID(r.Context(), claims.UserID)
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, p)
}

func handleUpdateMyParentProfile(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	existing, err := svc.ParentProfiles.GetByUserID(r.Context(), claims.UserID)
	if err != nil {
		writeRepoError(w, err)
		return
	}
	var updated model.ParentProfile
	if err := decodeJSON(r, &updated); err != nil {
		writeError(w, http.StatusBadRequest, model.ValidationError("invalid JSON body"))
		return
	}
	updated.UserID = existing.UserID
	updated.CreatedAt = existing.CreatedAt
	if err := svc.ParentProfiles.Save(r.Context(), &updated); err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, &updated)
}

func handleGetParentProfile(w http.ResponseWriter, r *http.Request) {
	if _, ok := requireClaims(w, r); !ok {
		return
	}
	p, err := svc.ParentProfiles.GetByUserID(r.Context(), r.PathValue("userId"))
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, p)
}

func handleListParentProfiles(w http.ResponseWriter, r *http.Request) {
	if _, ok := requireClaims(w, r); !ok {
		return
	}
	data, total, err := svc.ParentProfiles.List(r.Context(), parsePagination(r))
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, paginatedResponse(data, total))
}

// --- Broker profiles ---

func handleGetMyBrokerProfile(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	p, err := svc.BrokerProfiles.GetByUserID(r.Context(), claims.UserID)
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, p)
}

func handleUpdateMyBrokerProfile(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	existing, err := svc.BrokerProfiles.GetByUserID(r.Context(), claims.UserID)
	if err != nil {
		writeRepoError(w, err)
		return
	}
	var updated model.BrokerProfile
	if err := decodeJSON(r, &updated); err != nil {
		writeError(w, http.StatusBadRequest, model.ValidationError("invalid JSON body"))
		return
	}
	updated.UserID = existing.UserID
	updated.CreatedAt = existing.CreatedAt
	if err := svc.BrokerProfiles.Save(r.Context(), &updated); err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, &updated)
}

func handleGetBrokerProfile(w http.ResponseWriter, r *http.Request) {
	if _, ok := requireClaims(w, r); !ok {
		return
	}
	p, err := svc.BrokerProfiles.GetByUserID(r.Context(), r.PathValue("userId"))
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, p)
}

func handleListBrokerProfiles(w http.ResponseWriter, r *http.Request) {
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
	data, total, err := svc.BrokerProfiles.Search(r.Context(), queryStringPtr(r, "q"), queryStringPtr(r, "city"), minRating, p)
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, paginatedResponse(data, total))
}

func handleGetBrokerStats(w http.ResponseWriter, r *http.Request) {
	if _, ok := requireClaims(w, r); !ok {
		return
	}
	stats, err := svc.BrokerProfiles.GetStats(r.Context(), r.PathValue("userId"))
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, stats)
}

// --- Candidate profiles ---

func handleCreateCandidateProfile(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	var profile model.CandidateProfile
	if err := decodeJSON(r, &profile); err != nil {
		writeError(w, http.StatusBadRequest, model.ValidationError("invalid JSON body"))
		return
	}
	now := time.Now()
	profile.ID = uuid.NewString()
	profile.CreatedByUserID = claims.UserID
	profile.CreatedAt = now
	profile.UpdatedAt = now
	if len(profile.BrokerIDs) == 0 {
		profile.BrokerIDs = []string{claims.UserID}
	}
	if err := svc.CandidateProfiles.Create(r.Context(), &profile); err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, &profile)
}

func handleGetCandidateProfile(w http.ResponseWriter, r *http.Request) {
	if _, ok := requireClaims(w, r); !ok {
		return
	}
	p, err := svc.CandidateProfiles.GetByID(r.Context(), r.PathValue("id"))
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, p)
}

func handleUpdateCandidateProfile(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	id := r.PathValue("id")
	existing, err := svc.CandidateProfiles.GetByID(r.Context(), id)
	if err != nil {
		writeRepoError(w, err)
		return
	}
	if !canManageProfile(claims.UserID, existing) {
		writeError(w, http.StatusForbidden, model.ErrForbidden)
		return
	}
	var updated model.CandidateProfile
	if err := decodeJSON(r, &updated); err != nil {
		writeError(w, http.StatusBadRequest, model.ValidationError("invalid JSON body"))
		return
	}
	updated.ID = existing.ID
	updated.CreatedByUserID = existing.CreatedByUserID
	updated.CreatedAt = existing.CreatedAt
	updated.UpdatedAt = time.Now()
	if err := svc.CandidateProfiles.Update(r.Context(), &updated); err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, &updated)
}

func handleDeleteCandidateProfile(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	id := r.PathValue("id")
	existing, err := svc.CandidateProfiles.GetByID(r.Context(), id)
	if err != nil {
		writeRepoError(w, err)
		return
	}
	if !canManageProfile(claims.UserID, existing) {
		writeError(w, http.StatusForbidden, model.ErrForbidden)
		return
	}
	if err := svc.CandidateProfiles.Delete(r.Context(), id); err != nil {
		writeRepoError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func handleListCandidateProfiles(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	p := parsePagination(r)
	brokerID := queryStringPtr(r, "brokerId")
	if brokerID != nil && *brokerID == claims.UserID {
		data, total, err := svc.CandidateProfiles.ListByBroker(r.Context(), claims.UserID, p)
		if err != nil {
			writeRepoError(w, err)
			return
		}
		writeJSON(w, http.StatusOK, paginatedResponse(data, total))
		return
	}

	filters := repository.CandidateSearchFilters{
		Query:    queryStringPtr(r, "q"),
		BrokerID: brokerID,
		City:     queryStringPtr(r, "city"),
		Religion: queryStringPtr(r, "religion"),
	}
	if g := r.URL.Query().Get("gender"); g != "" {
		gender := model.Gender(g)
		filters.Gender = &gender
	}
	if v := r.URL.Query().Get("minAge"); v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			filters.MinAge = &n
		}
	}
	if v := r.URL.Query().Get("maxAge"); v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			filters.MaxAge = &n
		}
	}
	data, total, err := svc.CandidateProfiles.Search(r.Context(), filters, p)
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, paginatedResponse(data, total))
}

func handleGetProfileActivity(w http.ResponseWriter, r *http.Request) {
	if _, ok := requireClaims(w, r); !ok {
		return
	}
	limit := 50
	if v := r.URL.Query().Get("limit"); v != "" {
		if n, err := strconv.Atoi(v); err == nil && n > 0 {
			limit = n
		}
	}
	events, err := svc.Activity.ListByProfile(r.Context(), r.PathValue("id"), limit)
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"data": events})
}

func canManageProfile(userID string, p *model.CandidateProfile) bool {
	if p.CreatedByUserID == userID {
		return true
	}
	for _, id := range p.BrokerIDs {
		if id == userID {
			return true
		}
	}
	return false
}
