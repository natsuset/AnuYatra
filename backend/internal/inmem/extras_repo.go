package inmem

import (
	"context"
	"sort"
	"sync"
	"time"

	"github.com/anuyatra/backend/internal/model"
	"github.com/anuyatra/backend/internal/repository"
)

type SavedProfileRepo struct {
	mu   sync.RWMutex
	data map[string]*model.SavedProfile
}

func NewSavedProfileRepo() *SavedProfileRepo {
	return &SavedProfileRepo{data: make(map[string]*model.SavedProfile)}
}

func savedKey(userID, profileID string) string { return userID + ":" + profileID }

func (r *SavedProfileRepo) Save(_ context.Context, sp *model.SavedProfile) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	cp := *sp
	r.data[savedKey(sp.UserID, sp.ProfileID)] = &cp
	return nil
}

func (r *SavedProfileRepo) Delete(_ context.Context, userID, profileID string) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	delete(r.data, savedKey(userID, profileID))
	return nil
}

func (r *SavedProfileRepo) IsSaved(_ context.Context, userID, profileID string) (bool, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	_, ok := r.data[savedKey(userID, profileID)]
	return ok, nil
}

func (r *SavedProfileRepo) ListByUser(_ context.Context, userID string, p repository.Pagination) ([]*model.SavedProfile, int, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	all := make([]*model.SavedProfile, 0)
	for _, v := range r.data {
		if v.UserID == userID {
			cp := *v
			all = append(all, &cp)
		}
	}
	page, total := paginate(all, p)
	return page, total, nil
}

type ViewedProfileRepo struct {
	mu      sync.RWMutex
	byUser  map[string][]*model.ViewedProfile
}

func NewViewedProfileRepo() *ViewedProfileRepo {
	return &ViewedProfileRepo{byUser: make(map[string][]*model.ViewedProfile)}
}

func (r *ViewedProfileRepo) RecordView(_ context.Context, vp *model.ViewedProfile) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	cp := *vp
	r.byUser[vp.UserID] = append(r.byUser[vp.UserID], &cp)
	return nil
}

func (r *ViewedProfileRepo) ListByUser(_ context.Context, userID string, limit int) ([]*model.ViewedProfile, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	src := r.byUser[userID]
	all := make([]*model.ViewedProfile, len(src))
	copy(all, src)
	sort.Slice(all, func(i, j int) bool { return all[i].ViewedAt.After(all[j].ViewedAt) })
	if limit > 0 && len(all) > limit {
		all = all[:limit]
	}
	return all, nil
}

func (r *ViewedProfileRepo) ClearHistory(_ context.Context, userID string) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	delete(r.byUser, userID)
	return nil
}

type ActivityRepo struct {
	mu   sync.RWMutex
	data map[string][]*model.ProfileActivity
}

func NewActivityRepo() *ActivityRepo {
	return &ActivityRepo{data: make(map[string][]*model.ProfileActivity)}
}

func (r *ActivityRepo) Record(_ context.Context, event *model.ProfileActivity) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	cp := *event
	r.data[event.ProfileID] = append(r.data[event.ProfileID], &cp)
	return nil
}

func (r *ActivityRepo) ListByProfile(_ context.Context, profileID string, limit int) ([]*model.ProfileActivity, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	src := r.data[profileID]
	all := make([]*model.ProfileActivity, len(src))
	copy(all, src)
	sort.Slice(all, func(i, j int) bool { return all[i].At.After(all[j].At) })
	if limit > 0 && len(all) > limit {
		all = all[:limit]
	}
	return all, nil
}

type NoteRepo struct {
	mu          sync.RWMutex
	parentNotes map[string]*model.ParentNote
	brokerNotes map[string]*model.BrokerNote
}

func NewNoteRepo() *NoteRepo {
	return &NoteRepo{
		parentNotes: make(map[string]*model.ParentNote),
		brokerNotes: make(map[string]*model.BrokerNote),
	}
}

func parentNoteKey(parentUserID, profileID string) string { return parentUserID + ":" + profileID }
func brokerNoteKey(brokerUserID, profileID, forParentID string) string {
	return brokerUserID + ":" + profileID + ":" + forParentID
}

func (r *NoteRepo) GetParentNote(_ context.Context, parentUserID, profileID string) (*model.ParentNote, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	n, ok := r.parentNotes[parentNoteKey(parentUserID, profileID)]
	if !ok {
		return nil, model.NotFoundError("ParentNote", profileID)
	}
	cp := *n
	return &cp, nil
}

func (r *NoteRepo) UpsertParentNote(_ context.Context, note *model.ParentNote) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	cp := *note
	r.parentNotes[parentNoteKey(note.ParentUserID, note.CandidateProfileID)] = &cp
	return nil
}

func (r *NoteRepo) ListParentNotes(_ context.Context, parentUserID string) ([]*model.ParentNote, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	var result []*model.ParentNote
	for _, n := range r.parentNotes {
		if n.ParentUserID == parentUserID {
			cp := *n
			result = append(result, &cp)
		}
	}
	sort.Slice(result, func(i, j int) bool { return result[i].UpdatedAt.After(result[j].UpdatedAt) })
	return result, nil
}

func (r *NoteRepo) DeleteParentNote(_ context.Context, noteID string) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	for k, n := range r.parentNotes {
		if n.ID == noteID {
			delete(r.parentNotes, k)
			return nil
		}
	}
	return model.NotFoundError("ParentNote", noteID)
}

func (r *NoteRepo) GetBrokerNote(_ context.Context, brokerUserID, profileID, forParentID string) (*model.BrokerNote, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	n, ok := r.brokerNotes[brokerNoteKey(brokerUserID, profileID, forParentID)]
	if !ok {
		return nil, model.NotFoundError("BrokerNote", profileID)
	}
	cp := *n
	return &cp, nil
}

func (r *NoteRepo) UpsertBrokerNote(_ context.Context, note *model.BrokerNote) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	cp := *note
	r.brokerNotes[brokerNoteKey(note.BrokerUserID, note.CandidateProfileID, note.ForParentUserID)] = &cp
	return nil
}

// ── Client Engagements ──────────────────────────────────────────────

type ClientEngagementRepo struct {
	mu   sync.RWMutex
	data map[string]*model.ClientEngagement
}

func NewClientEngagementRepo() *ClientEngagementRepo {
	return &ClientEngagementRepo{data: make(map[string]*model.ClientEngagement)}
}

func engagementKey(brokerUserID, parentUserID string) string {
	return brokerUserID + ":" + parentUserID
}

func (r *ClientEngagementRepo) Get(_ context.Context, brokerUserID, parentUserID string) (*model.ClientEngagement, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	e, ok := r.data[engagementKey(brokerUserID, parentUserID)]
	if !ok {
		return nil, model.NotFoundError("ClientEngagement", parentUserID)
	}
	cp := *e
	return &cp, nil
}

func (r *ClientEngagementRepo) Upsert(_ context.Context, engagement *model.ClientEngagement) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	cp := *engagement
	r.data[engagementKey(engagement.BrokerUserID, engagement.ParentUserID)] = &cp
	return nil
}

func (r *ClientEngagementRepo) ListByBroker(_ context.Context, brokerUserID string) ([]*model.ClientEngagement, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	var result []*model.ClientEngagement
	for _, e := range r.data {
		if e.BrokerUserID == brokerUserID {
			cp := *e
			result = append(result, &cp)
		}
	}
	sort.Slice(result, func(i, j int) bool { return result[i].UpdatedAt.After(result[j].UpdatedAt) })
	return result, nil
}

// ── Broker Follow-ups ───────────────────────────────────────────────

type BrokerFollowUpRepo struct {
	mu   sync.RWMutex
	data map[string]*model.BrokerFollowUp
}

func NewBrokerFollowUpRepo() *BrokerFollowUpRepo {
	return &BrokerFollowUpRepo{data: make(map[string]*model.BrokerFollowUp)}
}

func (r *BrokerFollowUpRepo) Upsert(_ context.Context, followUp *model.BrokerFollowUp) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	cp := *followUp
	r.data[followUp.ID] = &cp
	return nil
}

func (r *BrokerFollowUpRepo) Delete(_ context.Context, id string) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if _, ok := r.data[id]; !ok {
		return model.NotFoundError("BrokerFollowUp", id)
	}
	delete(r.data, id)
	return nil
}

func (r *BrokerFollowUpRepo) ListByBroker(_ context.Context, brokerUserID string) ([]*model.BrokerFollowUp, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	var result []*model.BrokerFollowUp
	for _, f := range r.data {
		if f.BrokerUserID == brokerUserID {
			cp := *f
			result = append(result, &cp)
		}
	}
	sort.Slice(result, func(i, j int) bool { return result[i].DueAt.Before(result[j].DueAt) })
	return result, nil
}

func (r *BrokerFollowUpRepo) ListByClient(_ context.Context, brokerUserID, clientUserID string) ([]*model.BrokerFollowUp, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	var result []*model.BrokerFollowUp
	for _, f := range r.data {
		if f.BrokerUserID == brokerUserID && f.ClientUserID != nil && *f.ClientUserID == clientUserID {
			cp := *f
			result = append(result, &cp)
		}
	}
	sort.Slice(result, func(i, j int) bool { return result[i].DueAt.Before(result[j].DueAt) })
	return result, nil
}

// ── Meetings ────────────────────────────────────────────────────────

type MeetingRepo struct {
	mu   sync.RWMutex
	data map[string]*model.Meeting
}

func NewMeetingRepo() *MeetingRepo {
	return &MeetingRepo{data: make(map[string]*model.Meeting)}
}

func (r *MeetingRepo) Save(_ context.Context, meeting *model.Meeting) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	cp := *meeting
	r.data[meeting.ID] = &cp
	return nil
}

func (r *MeetingRepo) GetByID(_ context.Context, id string) (*model.Meeting, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	m, ok := r.data[id]
	if !ok {
		return nil, model.NotFoundError("Meeting", id)
	}
	cp := *m
	return &cp, nil
}

func (r *MeetingRepo) ListForPair(_ context.Context, parentUserID, profileID, viewerUserID string, p repository.Pagination) ([]*model.Meeting, int, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	all := make([]*model.Meeting, 0)
	for _, m := range r.data {
		if m.ParentUserID != parentUserID || m.CandidateProfileID != profileID {
			continue
		}
		if viewerUserID == m.BrokerUserID && !m.BrokerVisible {
			continue
		}
		if viewerUserID == m.ParentUserID && !m.ParentPartyVisible {
			continue
		}
		cp := *m
		all = append(all, &cp)
	}
	sort.Slice(all, func(i, j int) bool { return all[i].When.Before(all[j].When) })
	page, total := paginate(all, p)
	return page, total, nil
}

func (r *MeetingRepo) GetNext(_ context.Context, parentUserID, profileID, viewerUserID string) (*model.Meeting, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	var next *model.Meeting
	now := time.Now()
	for _, m := range r.data {
		if m.ParentUserID != parentUserID || m.CandidateProfileID != profileID {
			continue
		}
		if m.Status != model.MeetingScheduled || m.When.Before(now) {
			continue
		}
		if viewerUserID == m.BrokerUserID && !m.BrokerVisible {
			continue
		}
		if viewerUserID == m.ParentUserID && !m.ParentPartyVisible {
			continue
		}
		if next == nil || m.When.Before(next.When) {
			cp := *m
			next = &cp
		}
	}
	if next == nil {
		return nil, model.NotFoundError("Meeting", "next")
	}
	return next, nil
}

func (r *MeetingRepo) Cancel(_ context.Context, id string) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	m, ok := r.data[id]
	if !ok {
		return model.NotFoundError("Meeting", id)
	}
	m.Status = model.MeetingCancelled
	return nil
}
