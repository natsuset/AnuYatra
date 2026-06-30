package inmem

import (
	"context"
	"sync"

	"github.com/anuyatra/backend/internal/model"
	"github.com/anuyatra/backend/internal/repository"
)

type SharedProfileRepo struct {
	mu   sync.RWMutex
	data map[string]*model.SharedProfile
}

func NewSharedProfileRepo() *SharedProfileRepo {
	return &SharedProfileRepo{data: make(map[string]*model.SharedProfile)}
}

func (r *SharedProfileRepo) Create(_ context.Context, sp *model.SharedProfile) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	cp := *sp
	r.data[sp.ID] = &cp
	return nil
}

func (r *SharedProfileRepo) GetByID(_ context.Context, id string) (*model.SharedProfile, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	sp, ok := r.data[id]
	if !ok {
		return nil, model.NotFoundError("SharedProfile", id)
	}
	cp := *sp
	return &cp, nil
}

func (r *SharedProfileRepo) Update(_ context.Context, sp *model.SharedProfile) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if _, ok := r.data[sp.ID]; !ok {
		return model.NotFoundError("SharedProfile", sp.ID)
	}
	cp := *sp
	r.data[sp.ID] = &cp
	return nil
}

func (r *SharedProfileRepo) ListForUser(_ context.Context, userID string, response *model.SharedProfileResponse, p repository.Pagination) ([]*model.SharedProfile, int, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	all := make([]*model.SharedProfile, 0)
	for _, v := range r.data {
		if v.SharedWithUserID != userID {
			continue
		}
		if response != nil && v.ParentResponse != *response {
			continue
		}
		cp := *v
		all = append(all, &cp)
	}
	page, total := paginate(all, p)
	return page, total, nil
}

func (r *SharedProfileRepo) ListByBroker(_ context.Context, brokerUserID string, profileID *string, response *model.SharedProfileResponse, p repository.Pagination) ([]*model.SharedProfile, int, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	all := make([]*model.SharedProfile, 0)
	for _, v := range r.data {
		if v.SharedByUserID != brokerUserID {
			continue
		}
		if profileID != nil && v.ProfileID != *profileID {
			continue
		}
		if response != nil && v.ParentResponse != *response {
			continue
		}
		cp := *v
		all = append(all, &cp)
	}
	page, total := paginate(all, p)
	return page, total, nil
}

func (r *SharedProfileRepo) ListForwarded(_ context.Context, parentUserID string, p repository.Pagination) ([]*model.SharedProfile, int, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	all := make([]*model.SharedProfile, 0)
	for _, v := range r.data {
		if v.SharedWithUserID == parentUserID && v.ForwardedToChild {
			cp := *v
			all = append(all, &cp)
		}
	}
	page, total := paginate(all, p)
	return page, total, nil
}

func (r *SharedProfileRepo) FindDuplicate(_ context.Context, profileID, sharedWithUserID string) (*model.SharedProfile, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	for _, v := range r.data {
		if v.ProfileID == profileID && v.SharedWithUserID == sharedWithUserID {
			cp := *v
			return &cp, nil
		}
	}
	return nil, nil
}
