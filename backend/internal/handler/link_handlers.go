package handler

import (
	"net/http"
	"time"

	"github.com/google/uuid"

	"github.com/anuyatra/backend/internal/model"
)

func handleCreateLinkRequest(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	var body struct {
		ToUserID string                `json:"toUserId"`
		Type     model.LinkRequestType `json:"type"`
		Note     *string               `json:"note"`
	}
	if err := decodeJSON(r, &body); err != nil {
		writeError(w, http.StatusBadRequest, model.ValidationError("invalid JSON body"))
		return
	}
	if body.ToUserID == "" {
		writeError(w, http.StatusBadRequest, model.ValidationError("toUserId is required"))
		return
	}
	if body.ToUserID == claims.UserID {
		writeError(w, http.StatusBadRequest, model.ValidationError("cannot link to yourself"))
		return
	}

	dup, err := svc.LinkRequests.FindDuplicate(r.Context(), claims.UserID, body.ToUserID, body.Type)
	if err != nil {
		writeRepoError(w, err)
		return
	}
	if dup != nil {
		writeError(w, http.StatusConflict, model.ConflictError("link request already pending"))
		return
	}

	fromUser, err := svc.Users.GetByID(r.Context(), claims.UserID)
	if err != nil {
		writeRepoError(w, err)
		return
	}
	toUser, err := svc.Users.GetByID(r.Context(), body.ToUserID)
	if err != nil {
		writeRepoError(w, err)
		return
	}

	req := &model.LinkRequest{
		ID:           uuid.NewString(),
		FromUserID:   claims.UserID,
		ToUserID:     body.ToUserID,
		FromUserName: fromUser.DisplayName,
		ToUserName:   toUser.DisplayName,
		Type:         body.Type,
		Status:       model.LinkStatusPending,
		CreatedAt:    time.Now(),
		Note:         body.Note,
	}
	if err := svc.LinkRequests.Create(r.Context(), req); err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, req)
}

func handleAcceptLinkRequest(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	req, err := svc.LinkRequests.GetByID(r.Context(), r.PathValue("id"))
	if err != nil {
		writeRepoError(w, err)
		return
	}
	if req.ToUserID != claims.UserID {
		writeError(w, http.StatusForbidden, model.ErrForbidden)
		return
	}
	if req.Status != model.LinkStatusPending {
		writeError(w, http.StatusBadRequest, model.ValidationError("request is not pending"))
		return
	}
	now := time.Now()
	req.Status = model.LinkStatusAccepted
	req.RespondedAt = &now
	if err := svc.LinkRequests.Update(r.Context(), req); err != nil {
		writeRepoError(w, err)
		return
	}
	if req.Type == model.LinkParentToBroker {
		_, _ = svc.Messaging.GetOrCreateConversation(r.Context(), req.FromUserID, req.ToUserID)
	}
	writeJSON(w, http.StatusOK, req)
}

func handleDeclineLinkRequest(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	req, err := svc.LinkRequests.GetByID(r.Context(), r.PathValue("id"))
	if err != nil {
		writeRepoError(w, err)
		return
	}
	if req.ToUserID != claims.UserID {
		writeError(w, http.StatusForbidden, model.ErrForbidden)
		return
	}
	if req.Status != model.LinkStatusPending {
		writeError(w, http.StatusBadRequest, model.ValidationError("request is not pending"))
		return
	}
	now := time.Now()
	req.Status = model.LinkStatusDeclined
	req.RespondedAt = &now
	if err := svc.LinkRequests.Update(r.Context(), req); err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, req)
}

func handleRevokeLinkRequest(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	req, err := svc.LinkRequests.GetByID(r.Context(), r.PathValue("id"))
	if err != nil {
		writeRepoError(w, err)
		return
	}
	if req.FromUserID != claims.UserID {
		writeError(w, http.StatusForbidden, model.ErrForbidden)
		return
	}
	if req.Status != model.LinkStatusPending {
		writeError(w, http.StatusBadRequest, model.ValidationError("request is not pending"))
		return
	}
	now := time.Now()
	req.Status = model.LinkStatusRevoked
	req.RespondedAt = &now
	if err := svc.LinkRequests.Update(r.Context(), req); err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, req)
}

func handleListReceivedLinkRequests(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	data, total, err := svc.LinkRequests.ListReceived(r.Context(), claims.UserID, linkStatusPtr(r), linkTypePtr(r), parsePagination(r))
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, paginatedResponse(data, total))
}

func handleListSentLinkRequests(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	data, total, err := svc.LinkRequests.ListSent(r.Context(), claims.UserID, linkStatusPtr(r), linkTypePtr(r), parsePagination(r))
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, paginatedResponse(data, total))
}

func handleListConnections(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	data, err := svc.LinkRequests.ListConnections(r.Context(), claims.UserID)
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"data": data})
}

func handleGetConnectedBrokers(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	ids, err := svc.LinkRequests.GetConnectedBrokerIDs(r.Context(), claims.UserID)
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"data": ids})
}

func handleGetConnectedParents(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	ids, err := svc.LinkRequests.GetConnectedParentIDs(r.Context(), claims.UserID)
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"data": ids})
}

func handleGetLinkedChildren(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	ids, err := svc.LinkRequests.GetLinkedChildIDs(r.Context(), claims.UserID)
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"data": ids})
}

func handleGetLinkedParent(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	id, err := svc.LinkRequests.GetLinkedParentID(r.Context(), claims.UserID)
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"data": id})
}

func linkStatusPtr(r *http.Request) *model.LinkRequestStatus {
	v := r.URL.Query().Get("status")
	if v == "" {
		return nil
	}
	s := model.LinkRequestStatus(v)
	return &s
}

func linkTypePtr(r *http.Request) *model.LinkRequestType {
	v := r.URL.Query().Get("type")
	if v == "" {
		return nil
	}
	t := model.LinkRequestType(v)
	return &t
}
