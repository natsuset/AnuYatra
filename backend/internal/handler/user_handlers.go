package handler

import (
	"net/http"
	"time"

	"github.com/google/uuid"

	"github.com/anuyatra/backend/internal/model"
)

func handleGetMe(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	user, err := svc.Users.GetByID(r.Context(), claims.UserID)
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, user)
}

func handleUpdateMe(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	user, err := svc.Users.GetByID(r.Context(), claims.UserID)
	if err != nil {
		writeRepoError(w, err)
		return
	}

	var body struct {
		DisplayName *string `json:"displayName"`
		PhotoURL    *string `json:"photoUrl"`
	}
	if err := decodeJSON(r, &body); err != nil {
		writeError(w, http.StatusBadRequest, model.ValidationError("invalid JSON body"))
		return
	}
	if body.DisplayName != nil {
		user.DisplayName = *body.DisplayName
	}
	if body.PhotoURL != nil {
		user.PhotoURL = body.PhotoURL
	}
	if err := svc.Users.Update(r.Context(), user); err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, user)
}

func handleSetupProfile(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	user, err := svc.Users.GetByID(r.Context(), claims.UserID)
	if err != nil {
		writeRepoError(w, err)
		return
	}

	var body struct {
		DisplayName string         `json:"displayName"`
		RoleData    map[string]any `json:"roleData"`
	}
	if err := decodeJSON(r, &body); err != nil {
		writeError(w, http.StatusBadRequest, model.ValidationError("invalid JSON body"))
		return
	}
	if body.DisplayName != "" {
		user.DisplayName = body.DisplayName
	}

	now := time.Now()
	switch user.Role {
	case model.RoleAgencyAdmin:
		agency := &model.Agency{
			ID:          uuid.NewString(),
			AdminUserID: user.UID,
			Name:        strField(body.RoleData, "agencyName", user.DisplayName+"'s Agency"),
			City:        strField(body.RoleData, "city", ""),
			State:       strField(body.RoleData, "state", ""),
			Description: strField(body.RoleData, "description", ""),
			IsActive:    true,
			CreatedAt:   now,
		}
		if err := svc.Agencies.Create(r.Context(), agency); err != nil {
			writeRepoError(w, err)
			return
		}
		user.AgencyID = &agency.ID

	case model.RoleBroker:
		bp := &model.BrokerProfile{
			UserID:      user.UID,
			Name:        user.DisplayName,
			PhoneNumber: user.PhoneNumber,
			Bio:         strField(body.RoleData, "bio", ""),
			LastSeen:    now,
			CreatedAt:   now,
		}
		if err := svc.BrokerProfiles.Save(r.Context(), bp); err != nil {
			writeRepoError(w, err)
			return
		}

	case model.RoleParent:
		looking := model.LookingForGroom
		if strField(body.RoleData, "lookingFor", "groom") == "bride" {
			looking = model.LookingForBride
		}
		pp := &model.ParentProfile{
			UserID:     user.UID,
			Name:       user.DisplayName,
			LookingFor: looking,
			City:       strField(body.RoleData, "city", ""),
			State:      strField(body.RoleData, "state", ""),
			CreatedAt:  now,
		}
		if err := svc.ParentProfiles.Save(r.Context(), pp); err != nil {
			writeRepoError(w, err)
			return
		}

	case model.RoleCandidate:
	}

	if err := svc.Users.Update(r.Context(), user); err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, user)
}

func handleGetUser(w http.ResponseWriter, r *http.Request) {
	if _, ok := requireClaims(w, r); !ok {
		return
	}
	id := r.PathValue("id")
	user, err := svc.Users.GetByID(r.Context(), id)
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, user)
}

func handleListUsers(w http.ResponseWriter, r *http.Request) {
	if _, ok := requireClaims(w, r); !ok {
		return
	}
	phone := r.URL.Query().Get("phone")
	if phone != "" {
		user, err := svc.Users.GetByPhone(r.Context(), phone)
		if err != nil {
			writeRepoError(w, err)
			return
		}
		writeJSON(w, http.StatusOK, user)
		return
	}
	data, total, err := svc.Users.List(r.Context(), parsePagination(r))
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, paginatedResponse(data, total))
}

func strField(m map[string]any, key, fallback string) string {
	if m == nil {
		return fallback
	}
	if v, ok := m[key].(string); ok && v != "" {
		return v
	}
	return fallback
}
