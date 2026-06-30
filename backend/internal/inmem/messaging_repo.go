package inmem

import (
	"context"
	"sort"
	"sync"

	"github.com/google/uuid"

	"github.com/anuyatra/backend/internal/model"
	"github.com/anuyatra/backend/internal/repository"
)

type MessagingRepo struct {
	mu            sync.RWMutex
	conversations map[string]*model.Conversation
	messages      map[string][]*model.ChatMessage
	byUser        map[string][]string
}

func NewMessagingRepo() *MessagingRepo {
	return &MessagingRepo{
		conversations: make(map[string]*model.Conversation),
		messages:      make(map[string][]*model.ChatMessage),
		byUser:        make(map[string][]string),
	}
}

func (r *MessagingRepo) findBetween(userID1, userID2 string) *model.Conversation {
	for _, cid := range r.byUser[userID1] {
		c := r.conversations[cid]
		if c != nil && len(c.ParticipantIDs) == 2 {
			if (c.ParticipantIDs[0] == userID1 && c.ParticipantIDs[1] == userID2) ||
				(c.ParticipantIDs[0] == userID2 && c.ParticipantIDs[1] == userID1) {
				cp := *c
				return &cp
			}
		}
	}
	return nil
}

func (r *MessagingRepo) GetOrCreateConversation(_ context.Context, userID1, userID2 string) (*model.Conversation, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	if existing := r.findBetween(userID1, userID2); existing != nil {
		return existing, nil
	}
	id := uuid.NewString()
	c := &model.Conversation{
		ID:             id,
		ParticipantIDs: []string{userID1, userID2},
		UnreadCount:    0,
	}
	r.conversations[id] = c
	r.byUser[userID1] = append(r.byUser[userID1], id)
	r.byUser[userID2] = append(r.byUser[userID2], id)
	cp := *c
	return &cp, nil
}

func (r *MessagingRepo) GetConversation(_ context.Context, id string) (*model.Conversation, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	c, ok := r.conversations[id]
	if !ok {
		return nil, model.NotFoundError("Conversation", id)
	}
	cp := *c
	return &cp, nil
}

func (r *MessagingRepo) ListConversations(_ context.Context, userID string, p repository.Pagination) ([]*model.Conversation, int, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	all := make([]*model.Conversation, 0)
	for _, cid := range r.byUser[userID] {
		if c := r.conversations[cid]; c != nil {
			cp := *c
			all = append(all, &cp)
		}
	}
	sort.Slice(all, func(i, j int) bool {
		ti, tj := all[i].LastMessageAt, all[j].LastMessageAt
		if ti == nil {
			return false
		}
		if tj == nil {
			return true
		}
		return ti.After(*tj)
	})
	page, total := paginate(all, p)
	return page, total, nil
}

func (r *MessagingRepo) UpdateConversation(_ context.Context, conv *model.Conversation) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if _, ok := r.conversations[conv.ID]; !ok {
		return model.NotFoundError("Conversation", conv.ID)
	}
	cp := *conv
	r.conversations[conv.ID] = &cp
	return nil
}

func (r *MessagingRepo) CreateMessage(_ context.Context, msg *model.ChatMessage) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	cp := *msg
	r.messages[msg.ConversationID] = append(r.messages[msg.ConversationID], &cp)
	if c := r.conversations[msg.ConversationID]; c != nil {
		preview := msg.Content
		if len(preview) > 100 {
			preview = preview[:100]
		}
		now := msg.Timestamp
		c.LastMessagePreview = &preview
		c.LastMessageAt = &now
	}
	return nil
}

func (r *MessagingRepo) ListMessages(_ context.Context, conversationID string, p repository.Pagination) ([]*model.ChatMessage, int, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	src := r.messages[conversationID]
	all := make([]*model.ChatMessage, len(src))
	copy(all, src)
	sort.Slice(all, func(i, j int) bool {
		return all[i].Timestamp.Before(all[j].Timestamp)
	})
	page, total := paginate(all, p)
	return page, total, nil
}

func (r *MessagingRepo) MarkAsRead(_ context.Context, conversationID, userID string) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	for _, m := range r.messages[conversationID] {
		if m.SenderID != userID {
			m.IsRead = true
		}
	}
	if c := r.conversations[conversationID]; c != nil {
		c.UnreadCount = 0
	}
	return nil
}
