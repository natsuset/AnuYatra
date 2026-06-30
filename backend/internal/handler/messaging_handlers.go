package handler

import (
	"net/http"
	"time"

	"github.com/google/uuid"

	"github.com/anuyatra/backend/internal/model"
)

func handleGetOrCreateConversation(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	var body struct {
		OtherUserID string `json:"otherUserId"`
	}
	if err := decodeJSON(r, &body); err != nil || body.OtherUserID == "" {
		writeError(w, http.StatusBadRequest, model.ValidationError("otherUserId is required"))
		return
	}
	conv, err := svc.Messaging.GetOrCreateConversation(r.Context(), claims.UserID, body.OtherUserID)
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, conv)
}

func handleGetConversation(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	conv, err := svc.Messaging.GetConversation(r.Context(), r.PathValue("id"))
	if err != nil {
		writeRepoError(w, err)
		return
	}
	for _, pid := range conv.ParticipantIDs {
		if pid == claims.UserID {
			writeJSON(w, http.StatusOK, conv)
			return
		}
	}
	writeError(w, http.StatusForbidden, model.ErrForbidden)
}

func handleListConversations(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	data, total, err := svc.Messaging.ListConversations(r.Context(), claims.UserID, parsePagination(r))
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, paginatedResponse(data, total))
}

func handleListMessages(w http.ResponseWriter, r *http.Request) {
	if _, ok := requireClaims(w, r); !ok {
		return
	}
	data, total, err := svc.Messaging.ListMessages(r.Context(), r.PathValue("id"), parsePagination(r))
	if err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, paginatedResponse(data, total))
}

func handleSendMessage(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	convID := r.PathValue("id")
	conv, err := svc.Messaging.GetConversation(r.Context(), convID)
	if err != nil {
		writeRepoError(w, err)
		return
	}
	var body struct {
		Content       string               `json:"content"`
		Type          model.ChatMessageType `json:"type"`
		RecipientID   string               `json:"recipientId"`
		ProfileID     *string              `json:"profileId"`
		AttachmentURL *string              `json:"attachmentUrl"`
	}
	if err := decodeJSON(r, &body); err != nil {
		writeError(w, http.StatusBadRequest, model.ValidationError("invalid JSON body"))
		return
	}
	if body.Type == "" {
		body.Type = model.MessageText
	}
	msg := &model.ChatMessage{
		ID:             uuid.NewString(),
		ConversationID: convID,
		SenderID:       claims.UserID,
		RecipientID:    body.RecipientID,
		Content:        body.Content,
		Type:           body.Type,
		Timestamp:      time.Now(),
		ProfileID:      body.ProfileID,
		AttachmentURL:  body.AttachmentURL,
	}
	if msg.RecipientID == "" {
		for _, pid := range conv.ParticipantIDs {
			if pid != claims.UserID {
				msg.RecipientID = pid
				break
			}
		}
	}
	if err := svc.Messaging.CreateMessage(r.Context(), msg); err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, msg)
}

func handleMarkAsRead(w http.ResponseWriter, r *http.Request) {
	claims, ok := requireClaims(w, r)
	if !ok {
		return
	}
	if err := svc.Messaging.MarkAsRead(r.Context(), r.PathValue("id"), claims.UserID); err != nil {
		writeRepoError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"message": "marked as read"})
}
