package handler

import (
	"net/http"
	"time"

	"github.com/google/uuid"

	"github.com/anuyatra/backend/internal/model"
)

func handleShareProfile(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	var body struct {
		ProfileID        string  `json:"profileId"`
		SharedWithUserID string  `json:"sharedWithUserId"`
		ParentNote       *string `json:"parentNote"`
	}
	if err := decodeJSON(r, &body); err != nil {
		writeError(w, http.StatusBadRequest, model.ValidationError("invalid JSON body"))
		return
	}
	if _, err := svc.CandidateProfiles.GetByID(r.Context(), body.ProfileID); err != nil {
		writeRepoError(w, err)
		return
	}
	dup, err := svc.SharedProfiles.FindDuplicate(r.Context(), body.ProfileID, body.SharedWithUserID)
	if err != nil {
		writeRepoError(w, err)
		return
	}
	if dup != nil {
		writeError(w, http.StatusConflict, model.ConflictError("profile already shared with this user"))
		return
	}

	sp := &model.SharedProfile{
		ID:               uuid.NewString(),
		ProfileID:        body.ProfileID,
		SharedByUserID:   claims.UserID,
		SharedWithUserID: body.SharedWithUserID,
		SharedAt:         time.Now(),
		ParentResponse:   model.ResponsePending,
		ParentNote:       body.ParentNote,
	}
	if err := svc.SharedProfiles.Create(r.Context(), sp); err != nil {
		writeRepoError(w, err)
		return
	}
	recordActivity(r, body.ProfileID, claims.UserID, model.ActivityBrokerShared, nil)
	writeJSON(w, http.StatusCreated, sp)
}

func handleGetSharedProfilesForMe(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	data, total, err := svc.SharedProfiles.ListForUser(r.Context(), claims.UserID, sharedResponsePtr(r), parsePagination(r))
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, paginatedResponse(data, total))
}

func handleGetSharedProfilesByMe(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	data, total, err := svc.SharedProfiles.ListByBroker(r.Context(), claims.UserID, queryStringPtr(r, "profileId"), sharedResponsePtr(r), parsePagination(r))
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, paginatedResponse(data, total))
}

func handleGetForwardedProfiles(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	data, total, err := svc.SharedProfiles.ListForwarded(r.Context(), claims.UserID, parsePagination(r))
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, paginatedResponse(data, total))
}

func handleRespondToSharedProfile(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	sp, err := svc.SharedProfiles.GetByID(r.Context(), r.PathValue("id"))
	if err != nil {
		writeRepoError(w, err)
		return
	}
	if sp.SharedWithUserID != claims.UserID {
		writeError(w, http.StatusForbidden, model.ErrForbidden)
		return
	}
	var body struct {
		Response   model.SharedProfileResponse `json:"response"`
		ParentNote *string                     `json:"parentNote"`
	}
	if err := decodeJSON(r, &body); err != nil {
		writeError(w, http.StatusBadRequest, model.ValidationError("invalid JSON body"))
		return
	}
	sp.ParentResponse = body.Response
	if body.ParentNote != nil {
		sp.ParentNote = body.ParentNote
	}
	if err := svc.SharedProfiles.Update(r.Context(), sp); err != nil {
		writeRepoError(w, err)
		return
	}
	kind := model.ActivityParentPass
	if body.Response == model.ResponseInterested {
		kind = model.ActivityParentInterested
	}
	recordActivity(r, sp.ProfileID, claims.UserID, kind, nil)
	writeJSON(w, http.StatusOK, sp)
}

func handleForwardProfile(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	sp, err := svc.SharedProfiles.GetByID(r.Context(), r.PathValue("id"))
	if err != nil {
		writeRepoError(w, err)
		return
	}
	if sp.SharedWithUserID != claims.UserID {
		writeError(w, http.StatusForbidden, model.ErrForbidden)
		return
	}
	sp.ForwardedToChild = true
	if err := svc.SharedProfiles.Update(r.Context(), sp); err != nil {
		writeRepoError(w, err)
		return
	}
	recordActivity(r, sp.ProfileID, claims.UserID, model.ActivityParentForwarded, nil)
	writeJSON(w, http.StatusOK, sp)
}

func sharedResponsePtr(r *http.Request) *model.SharedProfileResponse {
	v := r.URL.Query().Get("response")
	if v == "" {
		return nil
	}
	resp := model.SharedProfileResponse(v)
	return &resp
}

func recordActivity(r *http.Request, profileID string, actorID string, kind model.ProfileActivityKind, meta map[string]any) {
	actorName := ""
	if user, err := svc.Users.GetByID(r.Context(), actorID); err == nil {
		actorName = user.DisplayName
	}
	_ = svc.Activity.Record(r.Context(), &model.ProfileActivity{
		ID:          uuid.NewString(),
		ProfileID:   profileID,
		ActorUserID: &actorID,
		ActorName:   &actorName,
		Kind:        kind,
		At:          time.Now(),
		Meta:        meta,
	})
}
