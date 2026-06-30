package inmem

import (
	"context"
	"sync"

	"github.com/anuyatra/backend/internal/model"
	"github.com/anuyatra/backend/internal/repository"
)

type UserRepo struct {
	mu     sync.RWMutex
	byID   map[string]*model.AppUser
	byPhone map[string]string
}

func NewUserRepo() *UserRepo {
	return &UserRepo{
		byID:    make(map[string]*model.AppUser),
		byPhone: make(map[string]string),
	}
}

func (r *UserRepo) Create(_ context.Context, user *model.AppUser) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if _, ok := r.byID[user.UID]; ok {
		return model.ConflictError("user already exists")
	}
	if uid, ok := r.byPhone[user.PhoneNumber]; ok && uid != user.UID {
		return model.ConflictError("phone number already registered")
	}
	cp := *user
	r.byID[user.UID] = &cp
	r.byPhone[user.PhoneNumber] = user.UID
	return nil
}

func (r *UserRepo) GetByID(_ context.Context, id string) (*model.AppUser, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	u, ok := r.byID[id]
	if !ok {
		return nil, model.NotFoundError("User", id)
	}
	cp := *u
	return &cp, nil
}

func (r *UserRepo) GetByPhone(_ context.Context, phone string) (*model.AppUser, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	uid, ok := r.byPhone[phone]
	if !ok {
		return nil, model.NotFoundError("User", phone)
	}
	cp := *r.byID[uid]
	return &cp, nil
}

func (r *UserRepo) Update(_ context.Context, user *model.AppUser) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if _, ok := r.byID[user.UID]; !ok {
		return model.NotFoundError("User", user.UID)
	}
	cp := *user
	r.byID[user.UID] = &cp
	r.byPhone[user.PhoneNumber] = user.UID
	return nil
}

func (r *UserRepo) List(_ context.Context, p repository.Pagination) ([]*model.AppUser, int, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	all := make([]*model.AppUser, 0, len(r.byID))
	for _, u := range r.byID {
		cp := *u
		all = append(all, &cp)
	}
	page, total := paginate(all, p)
	return page, total, nil
}
