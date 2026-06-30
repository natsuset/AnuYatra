package inmem

import (
	"context"
	"sync"

	"github.com/anuyatra/backend/internal/model"
	"github.com/anuyatra/backend/internal/repository"
)

type LinkRequestRepo struct {
	mu   sync.RWMutex
	data map[string]*model.LinkRequest
}

func NewLinkRequestRepo() *LinkRequestRepo {
	return &LinkRequestRepo{data: make(map[string]*model.LinkRequest)}
}

func (r *LinkRequestRepo) Create(_ context.Context, req *model.LinkRequest) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	cp := *req
	r.data[req.ID] = &cp
	return nil
}

func (r *LinkRequestRepo) GetByID(_ context.Context, id string) (*model.LinkRequest, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	lr, ok := r.data[id]
	if !ok {
		return nil, model.NotFoundError("LinkRequest", id)
	}
	cp := *lr
	return &cp, nil
}

func (r *LinkRequestRepo) Update(_ context.Context, req *model.LinkRequest) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if _, ok := r.data[req.ID]; !ok {
		return model.NotFoundError("LinkRequest", req.ID)
	}
	cp := *req
	r.data[req.ID] = &cp
	return nil
}

func (r *LinkRequestRepo) filter(userID string, received bool, status *model.LinkRequestStatus, reqType *model.LinkRequestType) []*model.LinkRequest {
	all := make([]*model.LinkRequest, 0)
	for _, v := range r.data {
		if received {
			if v.ToUserID != userID {
				continue
			}
		} else {
			if v.FromUserID != userID {
				continue
			}
		}
		if status != nil && v.Status != *status {
			continue
		}
		if reqType != nil && v.Type != *reqType {
			continue
		}
		cp := *v
		all = append(all, &cp)
	}
	return all
}

func (r *LinkRequestRepo) ListReceived(_ context.Context, userID string, status *model.LinkRequestStatus, reqType *model.LinkRequestType, p repository.Pagination) ([]*model.LinkRequest, int, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	all := r.filter(userID, true, status, reqType)
	page, total := paginate(all, p)
	return page, total, nil
}

func (r *LinkRequestRepo) ListSent(_ context.Context, userID string, status *model.LinkRequestStatus, reqType *model.LinkRequestType, p repository.Pagination) ([]*model.LinkRequest, int, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	all := r.filter(userID, false, status, reqType)
	page, total := paginate(all, p)
	return page, total, nil
}

func (r *LinkRequestRepo) ListConnections(_ context.Context, userID string) ([]*model.LinkRequest, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	all := make([]*model.LinkRequest, 0)
	for _, v := range r.data {
		if v.Status != model.LinkStatusAccepted {
			continue
		}
		if v.FromUserID == userID || v.ToUserID == userID {
			cp := *v
			all = append(all, &cp)
		}
	}
	return all, nil
}

func (r *LinkRequestRepo) FindDuplicate(_ context.Context, fromID, toID string, reqType model.LinkRequestType) (*model.LinkRequest, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	for _, v := range r.data {
		if v.FromUserID == fromID && v.ToUserID == toID && v.Type == reqType && v.Status == model.LinkStatusPending {
			cp := *v
			return &cp, nil
		}
	}
	return nil, nil
}

func (r *LinkRequestRepo) GetConnectedBrokerIDs(_ context.Context, parentUserID string) ([]string, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	ids := make([]string, 0)
	for _, v := range r.data {
		if v.Status == model.LinkStatusAccepted && v.Type == model.LinkParentToBroker && v.FromUserID == parentUserID {
			ids = append(ids, v.ToUserID)
		}
	}
	return ids, nil
}

func (r *LinkRequestRepo) GetConnectedParentIDs(_ context.Context, brokerUserID string) ([]string, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	ids := make([]string, 0)
	for _, v := range r.data {
		if v.Status == model.LinkStatusAccepted && v.Type == model.LinkParentToBroker && v.ToUserID == brokerUserID {
			ids = append(ids, v.FromUserID)
		}
	}
	return ids, nil
}

func (r *LinkRequestRepo) GetLinkedChildIDs(_ context.Context, parentUserID string) ([]string, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	ids := make([]string, 0)
	for _, v := range r.data {
		if v.Status == model.LinkStatusAccepted && v.Type == model.LinkChildToParent && v.ToUserID == parentUserID {
			ids = append(ids, v.FromUserID)
		}
	}
	return ids, nil
}

func (r *LinkRequestRepo) GetLinkedParentID(_ context.Context, childUserID string) (*string, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	for _, v := range r.data {
		if v.Status == model.LinkStatusAccepted && v.Type == model.LinkChildToParent && v.FromUserID == childUserID {
			id := v.ToUserID
			return &id, nil
		}
	}
	return nil, nil
}
