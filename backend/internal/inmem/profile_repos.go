package inmem

import (
	"context"
	"sync"

	"github.com/anuyatra/backend/internal/model"
	"github.com/anuyatra/backend/internal/repository"
)

type ParentProfileRepo struct {
	mu   sync.RWMutex
	data map[string]*model.ParentProfile
}

func NewParentProfileRepo() *ParentProfileRepo {
	return &ParentProfileRepo{data: make(map[string]*model.ParentProfile)}
}

func (r *ParentProfileRepo) Save(_ context.Context, profile *model.ParentProfile) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	cp := *profile
	r.data[profile.UserID] = &cp
	return nil
}

func (r *ParentProfileRepo) GetByUserID(_ context.Context, userID string) (*model.ParentProfile, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	p, ok := r.data[userID]
	if !ok {
		return nil, model.NotFoundError("ParentProfile", userID)
	}
	cp := *p
	return &cp, nil
}

func (r *ParentProfileRepo) List(_ context.Context, p repository.Pagination) ([]*model.ParentProfile, int, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	all := make([]*model.ParentProfile, 0, len(r.data))
	for _, v := range r.data {
		cp := *v
		all = append(all, &cp)
	}
	page, total := paginate(all, p)
	return page, total, nil
}

type BrokerProfileRepo struct {
	mu   sync.RWMutex
	data map[string]*model.BrokerProfile
}

func NewBrokerProfileRepo() *BrokerProfileRepo {
	return &BrokerProfileRepo{data: make(map[string]*model.BrokerProfile)}
}

func (r *BrokerProfileRepo) Save(_ context.Context, profile *model.BrokerProfile) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	cp := *profile
	r.data[profile.UserID] = &cp
	return nil
}

func (r *BrokerProfileRepo) GetByUserID(_ context.Context, userID string) (*model.BrokerProfile, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	p, ok := r.data[userID]
	if !ok {
		return nil, model.NotFoundError("BrokerProfile", userID)
	}
	cp := *p
	return &cp, nil
}

func (r *BrokerProfileRepo) List(_ context.Context, p repository.Pagination) ([]*model.BrokerProfile, int, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	all := make([]*model.BrokerProfile, 0, len(r.data))
	for _, v := range r.data {
		cp := *v
		all = append(all, &cp)
	}
	page, total := paginate(all, p)
	return page, total, nil
}

func (r *BrokerProfileRepo) ListByAgency(_ context.Context, agencyID string, p repository.Pagination) ([]*model.BrokerProfile, int, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	all := make([]*model.BrokerProfile, 0)
	for _, v := range r.data {
		if v.AgencyID != nil && *v.AgencyID == agencyID {
			cp := *v
			all = append(all, &cp)
		}
	}
	page, total := paginate(all, p)
	return page, total, nil
}

func (r *BrokerProfileRepo) Search(_ context.Context, query, city *string, minRating *float64, p repository.Pagination) ([]*model.BrokerProfile, int, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	all := make([]*model.BrokerProfile, 0)
	for _, v := range r.data {
		if query != nil && *query != "" && !containsFold(v.Name, *query) {
			continue
		}
		if city != nil && *city != "" {
			matched := false
			for _, a := range v.AreasServed {
				if containsFold(a, *city) {
					matched = true
					break
				}
			}
			if !matched {
				continue
			}
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

func (r *BrokerProfileRepo) GetStats(_ context.Context, _ string) (*model.BrokerStats, error) {
	return &model.BrokerStats{}, nil
}

func (r *BrokerProfileRepo) GetAgencyStats(_ context.Context, _ string) (*model.AgencyStats, error) {
	return &model.AgencyStats{}, nil
}

type CandidateProfileRepo struct {
	mu   sync.RWMutex
	data map[string]*model.CandidateProfile
}

func NewCandidateProfileRepo() *CandidateProfileRepo {
	return &CandidateProfileRepo{data: make(map[string]*model.CandidateProfile)}
}

func (r *CandidateProfileRepo) Create(_ context.Context, profile *model.CandidateProfile) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	cp := *profile
	r.data[profile.ID] = &cp
	return nil
}

func (r *CandidateProfileRepo) GetByID(_ context.Context, id string) (*model.CandidateProfile, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	p, ok := r.data[id]
	if !ok {
		return nil, model.NotFoundError("CandidateProfile", id)
	}
	cp := *p
	return &cp, nil
}

func (r *CandidateProfileRepo) Update(_ context.Context, profile *model.CandidateProfile) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if _, ok := r.data[profile.ID]; !ok {
		return model.NotFoundError("CandidateProfile", profile.ID)
	}
	cp := *profile
	r.data[profile.ID] = &cp
	return nil
}

func (r *CandidateProfileRepo) Delete(_ context.Context, id string) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if _, ok := r.data[id]; !ok {
		return model.NotFoundError("CandidateProfile", id)
	}
	delete(r.data, id)
	return nil
}

func (r *CandidateProfileRepo) List(_ context.Context, p repository.Pagination) ([]*model.CandidateProfile, int, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	all := make([]*model.CandidateProfile, 0, len(r.data))
	for _, v := range r.data {
		cp := *v
		all = append(all, &cp)
	}
	page, total := paginate(all, p)
	return page, total, nil
}

func (r *CandidateProfileRepo) ListByBroker(_ context.Context, brokerUserID string, p repository.Pagination) ([]*model.CandidateProfile, int, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	all := make([]*model.CandidateProfile, 0)
	for _, v := range r.data {
		if containsStr(v.BrokerIDs, brokerUserID) || v.CreatedByUserID == brokerUserID {
			cp := *v
			all = append(all, &cp)
		}
	}
	page, total := paginate(all, p)
	return page, total, nil
}

func (r *CandidateProfileRepo) Search(_ context.Context, filters repository.CandidateSearchFilters, p repository.Pagination) ([]*model.CandidateProfile, int, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	all := make([]*model.CandidateProfile, 0)
	for _, v := range r.data {
		if filters.Query != nil && *filters.Query != "" && !containsFold(v.Name, *filters.Query) {
			continue
		}
		if filters.BrokerID != nil && !containsStr(v.BrokerIDs, *filters.BrokerID) && v.CreatedByUserID != *filters.BrokerID {
			continue
		}
		if filters.Gender != nil && v.Gender != *filters.Gender {
			continue
		}
		if filters.City != nil && *filters.City != "" && !containsFold(v.City, *filters.City) {
			continue
		}
		if filters.Religion != nil && *filters.Religion != "" && !containsFold(v.Religion, *filters.Religion) {
			continue
		}
		if filters.MinAge != nil && v.Age < *filters.MinAge {
			continue
		}
		if filters.MaxAge != nil && v.Age > *filters.MaxAge {
			continue
		}
		cp := *v
		all = append(all, &cp)
	}
	page, total := paginate(all, p)
	return page, total, nil
}
