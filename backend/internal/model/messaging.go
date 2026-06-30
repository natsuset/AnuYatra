package model

import "time"

type ChatMessageType string

const (
	MessageText         ChatMessageType = "text"
	MessageProfileShare ChatMessageType = "profileShare"
	MessageImage        ChatMessageType = "image"
	MessageSystem       ChatMessageType = "system"
)

type ChatMessage struct {
	ID             string          `json:"id"`
	ConversationID string          `json:"conversationId"`
	SenderID       string          `json:"senderId"`
	RecipientID    string          `json:"recipientId"`
	Content        string          `json:"content"`
	Type           ChatMessageType `json:"type"`
	Timestamp      time.Time       `json:"timestamp"`
	IsRead         bool            `json:"isRead"`
	ProfileID      *string         `json:"profileId,omitempty"`
	AttachmentURL  *string         `json:"attachmentUrl,omitempty"`
}

type Conversation struct {
	ID                 string    `json:"id"`
	ParticipantIDs     []string  `json:"participantIds"`
	LastMessagePreview *string   `json:"lastMessagePreview"`
	LastMessageAt      *time.Time `json:"lastMessageAt"`
	UnreadCount        int       `json:"unreadCount"`
}
