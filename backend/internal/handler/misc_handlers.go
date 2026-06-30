package handler

import (
	"net/http"
	"strconv"
	"time"

	"github.com/google/uuid"

	"github.com/anuyatra/backend/internal/model"
)

// --- Saved profiles ---

func handleSaveProfile(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	var body struct {
		ProfileID string `json:"profileId"`
	}
	if err := decodeJSON(r, &body); err != nil || body.ProfileID == "" {
		writeError(w, http.StatusBadRequest, model.ValidationError("profileId is required"))
		return
	}
	sp := &model.SavedProfile{
		ID:        uuid.NewString(),
		UserID:    claims.UserID,
		ProfileID: body.ProfileID,
		SavedAt:   time.Now(),
	}
	if err := svc.SavedProfiles.Save(r.Context(), sp); err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, sp)
}

func handleUnsaveProfile(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	if err := svc.SavedProfiles.Delete(r.Context(), claims.UserID, r.PathValue("profileId")); err != nil {
		writeRepoError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func handleListSavedProfiles(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	data, total, err := svc.SavedProfiles.ListByUser(r.Context(), claims.UserID, parsePagination(r))
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, paginatedResponse(data, total))
}

func handleCheckSaved(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	saved, err := svc.SavedProfiles.IsSaved(r.Context(), claims.UserID, r.PathValue("profileId"))
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]bool{"saved": saved})
}

// --- Viewed profiles ---

func handleRecordView(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	var body struct {
		ProfileID string `json:"profileId"`
	}
	if err := decodeJSON(r, &body); err != nil || body.ProfileID == "" {
		writeError(w, http.StatusBadRequest, model.ValidationError("profileId is required"))
		return
	}
	vp := &model.ViewedProfile{
		ID:        uuid.NewString(),
		UserID:    claims.UserID,
		ProfileID: body.ProfileID,
		ViewedAt:  time.Now(),
	}
	if err := svc.ViewedProfiles.RecordView(r.Context(), vp); err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, vp)
}

func handleListViews(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	limit := 50
	if v := r.URL.Query().Get("limit"); v != "" {
		if n, err := strconv.Atoi(v); err == nil && n > 0 {
			limit = n
		}
	}
	data, err := svc.ViewedProfiles.ListByUser(r.Context(), claims.UserID, limit)
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"data": data})
}

func handleClearViews(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	if err := svc.ViewedProfiles.ClearHistory(r.Context(), claims.UserID); err != nil {
		writeRepoError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// --- Notes ---

func handleListParentNotes(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	notes, err := svc.Notes.ListParentNotes(r.Context(), claims.UserID)
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"data": notes})
}

func handleDeleteParentNote(w http.ResponseWriter, r *http.Request) {
	if _, ok := requireClaims(w, r); !ok {
		return
	}
	if err := svc.Notes.DeleteParentNote(r.Context(), r.PathValue("id")); err != nil {
		writeRepoError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func handleGetParentNote(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	profileID := r.URL.Query().Get("profileId")
	if profileID == "" {
		writeError(w, http.StatusBadRequest, model.ValidationError("profileId is required"))
		return
	}
	note, err := svc.Notes.GetParentNote(r.Context(), claims.UserID, profileID)
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, note)
}

func handleUpsertParentNote(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	var note model.ParentNote
	if err := decodeJSON(r, &note); err != nil {
		writeError(w, http.StatusBadRequest, model.ValidationError("invalid JSON body"))
		return
	}
	note.ID = uuid.NewString()
	note.ParentUserID = claims.UserID
	note.UpdatedAt = time.Now()
	if err := svc.Notes.UpsertParentNote(r.Context(), &note); err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, &note)
}

func handleGetBrokerNote(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	profileID := r.URL.Query().Get("profileId")
	forParentID := r.URL.Query().Get("forParentId")
	if profileID == "" || forParentID == "" {
		writeError(w, http.StatusBadRequest, model.ValidationError("profileId and forParentId are required"))
		return
	}
	note, err := svc.Notes.GetBrokerNote(r.Context(), claims.UserID, profileID, forParentID)
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, note)
}

func handleUpsertBrokerNote(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	var note model.BrokerNote
	if err := decodeJSON(r, &note); err != nil {
		writeError(w, http.StatusBadRequest, model.ValidationError("invalid JSON body"))
		return
	}
	note.ID = uuid.NewString()
	note.BrokerUserID = claims.UserID
	note.UpdatedAt = time.Now()
	if err := svc.Notes.UpsertBrokerNote(r.Context(), &note); err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, &note)
}

// --- Meetings ---

func handleGetMeeting(w http.ResponseWriter, r *http.Request) {
	if _, ok := requireClaims(w, r); !ok {
		return
	}
	m, err := svc.Meetings.GetByID(r.Context(), r.PathValue("id"))
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, m)
}

func handleCreateMeeting(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	var meeting model.Meeting
	if err := decodeJSON(r, &meeting); err != nil {
		writeError(w, http.StatusBadRequest, model.ValidationError("invalid JSON body"))
		return
	}
	meeting.ID = uuid.NewString()
	meeting.ScheduledByUserID = claims.UserID
	meeting.Status = model.MeetingScheduled
	meeting.CreatedAt = time.Now()
	if err := svc.Meetings.Save(r.Context(), &meeting); err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, &meeting)
}

func handleListMeetings(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	parentID := r.URL.Query().Get("parentUserId")
	profileID := r.URL.Query().Get("profileId")
	if parentID == "" || profileID == "" {
		writeError(w, http.StatusBadRequest, model.ValidationError("parentUserId and profileId are required"))
		return
	}
	data, total, err := svc.Meetings.ListForPair(r.Context(), parentID, profileID, claims.UserID, parsePagination(r))
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, paginatedResponse(data, total))
}

func handleGetNextMeeting(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	parentID := r.URL.Query().Get("parentUserId")
	profileID := r.URL.Query().Get("profileId")
	if parentID == "" || profileID == "" {
		writeError(w, http.StatusBadRequest, model.ValidationError("parentUserId and profileId are required"))
		return
	}
	m, err := svc.Meetings.GetNext(r.Context(), parentID, profileID, claims.UserID)
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, m)
}

func handleCancelMeeting(w http.ResponseWriter, r *http.Request) {
	if _, ok := requireClaims(w, r); !ok {
		return
	}
	if err := svc.Meetings.Cancel(r.Context(), r.PathValue("id")); err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "meeting cancelled"})
}

// --- Client Engagements ---

func handleGetClientEngagement(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	parentID := r.URL.Query().Get("parentUserId")
	if parentID == "" {
		writeError(w, http.StatusBadRequest, model.ValidationError("parentUserId is required"))
		return
	}
	e, err := svc.Engagements.Get(r.Context(), claims.UserID, parentID)
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, e)
}

func handleListClientEngagements(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	data, err := svc.Engagements.ListByBroker(r.Context(), claims.UserID)
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"data": data})
}

func handleUpsertClientEngagement(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	var e model.ClientEngagement
	if err := decodeJSON(r, &e); err != nil {
		writeError(w, http.StatusBadRequest, model.ValidationError("invalid JSON body"))
		return
	}
	e.BrokerUserID = claims.UserID
	if e.ID == "" {
		e.ID = uuid.NewString()
	}
	now := time.Now()
	e.UpdatedAt = now
	if e.CreatedAt.IsZero() {
		e.CreatedAt = now
	}
	if err := svc.Engagements.Upsert(r.Context(), &e); err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, &e)
}

// --- Broker Follow-ups ---

func handleListBrokerFollowUps(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	clientID := r.URL.Query().Get("clientUserId")
	var data []*model.BrokerFollowUp
	var err error
	if clientID != "" {
		data, err = svc.FollowUps.ListByClient(r.Context(), claims.UserID, clientID)
	} else {
		data, err = svc.FollowUps.ListByBroker(r.Context(), claims.UserID)
	}
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"data": data})
}

func handleUpsertBrokerFollowUp(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	var fu model.BrokerFollowUp
	if err := decodeJSON(r, &fu); err != nil {
		writeError(w, http.StatusBadRequest, model.ValidationError("invalid JSON body"))
		return
	}
	fu.BrokerUserID = claims.UserID
	if fu.ID == "" {
		fu.ID = uuid.NewString()
	}
	if fu.CreatedAt.IsZero() {
		fu.CreatedAt = time.Now()
	}
	if err := svc.FollowUps.Upsert(r.Context(), &fu); err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, &fu)
}

func handleDeleteBrokerFollowUp(w http.ResponseWriter, r *http.Request) {
	if _, ok := requireClaims(w, r); !ok {
		return
	}
	if err := svc.FollowUps.Delete(r.Context(), r.PathValue("id")); err != nil {
		writeRepoError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// --- Uploads ---

func handleGetPresignedURL(w http.ResponseWriter, r *http.Request) {
	if _, ok := requireClaims(w, r); !ok {
		return
	}
	var body struct {
		Filename    string `json:"filename"`
		ContentType string `json:"contentType"`
	}
	if err := decodeJSON(r, &body); err != nil {
		writeError(w, http.StatusBadRequest, model.ValidationError("invalid JSON body"))
		return
	}
	if body.Filename == "" {
		writeError(w, http.StatusBadRequest, model.ValidationError("filename is required"))
		return
	}
	key := uuid.NewString() + "_" + body.Filename
	baseURL := "http://localhost:8080"
	if svc.IsDev {
		writeJSON(w, http.StatusOK, map[string]string{
			"uploadUrl": baseURL + "/api/v1/uploads/" + key,
			"publicUrl": baseURL + "/api/v1/uploads/" + key,
			"key":       key,
		})
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{
		"uploadUrl": "https://storage.example.com/upload/" + key,
		"publicUrl": "https://storage.example.com/files/" + key,
		"key":       key,
	})
}
