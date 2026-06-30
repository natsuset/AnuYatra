package inmem

import (
	"context"
	"sync"

	"github.com/anuyatra/backend/internal/model"
	"github.com/anuyatra/backend/internal/repository"
)

type AgencyRepo struct {
	mu   sync.RWMutex
	data map[string]*model.Agency
}

func NewAgencyRepo() *AgencyRepo {
	return &AgencyRepo{data: make(map[string]*model.Agency)}
}

func (r *AgencyRepo) Create(_ context.Context, agency *model.Agency) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	cp := *agency
	r.data[agency.ID] = &cp
	return nil
}

func (r *AgencyRepo) GetByID(_ context.Context, id string) (*model.Agency, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	a, ok := r.data[id]
	if !ok {
		return nil, model.NotFoundError("Agency", id)
	}
	cp := *a
	return &cp, nil
}

func (r *AgencyRepo) Update(_ context.Context, agency *model.Agency) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if _, ok := r.data[agency.ID]; !ok {
		return model.NotFoundError("Agency", agency.ID)
	}
	cp := *agency
	r.data[agency.ID] = &cp
	return nil
}

func (r *AgencyRepo) List(_ context.Context, p repository.Pagination) ([]*model.Agency, int, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	all := make([]*model.Agency, 0, len(r.data))
	for _, v := range r.data {
		cp := *v
		all = append(all, &cp)
	}
	page, total := paginate(all, p)
	return page, total, nil
}

func (r *AgencyRepo) Search(_ context.Context, query, city *string, minRating *float64, p repository.Pagination) ([]*model.Agency, int, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	all := make([]*model.Agency, 0)
	for _, v := range r.data {
		if query != nil && *query != "" && !containsFold(v.Name, *query) {
			continue
		}
		if city != nil && *city != "" && !containsFold(v.City, *city) {
			continue
		}
		if minRating != nil && v.Rating < *minRating {
			continue
		}
		cp := *v
		all = append(all, &cp)
	}
	page, total := paginate(all, p)
	return page, total, nil
}
