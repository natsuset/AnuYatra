package repository

import (
	"context"

	"github.com/anuyatra/backend/internal/model"
)

type Pagination struct {
	Limit  int
	Offset int
}

func DefaultPagination() Pagination {
	return Pagination{Limit: 20, Offset: 0}
}

// UserRepository handles user CRUD and session management.
type UserRepository interface {
	Create(ctx context.Context, user *model.AppUser) error
	GetByID(ctx context.Context, id string) (*model.AppUser, error)
	GetByPhone(ctx context.Context, phone string) (*model.AppUser, error)
	Update(ctx context.Context, user *model.AppUser) error
	List(ctx context.Context, p Pagination) ([]*model.AppUser, int, error)
}

// AuthRepository handles OTP send/verify.
type AuthRepository interface {
	SendOTP(ctx context.Context, phone string, role model.UserRole) (sessionID string, err error)
	VerifyOTP(ctx context.Context, sessionID, phone, code string) (bool, error)
}

// ParentProfileRepository handles parent profile CRUD.
type ParentProfileRepository interface {
	Save(ctx context.Context, profile *model.ParentProfile) error
	GetByUserID(ctx context.Context, userID string) (*model.ParentProfile, error)
	List(ctx context.Context, p Pagination) ([]*model.ParentProfile, int, error)
}

// BrokerProfileRepository handles broker profile CRUD, search, and stats.
type BrokerProfileRepository interface {
	Save(ctx context.Context, profile *model.BrokerProfile) error
	GetByUserID(ctx context.Context, userID string) (*model.BrokerProfile, error)
	List(ctx context.Context, p Pagination) ([]*model.BrokerProfile, int, error)
	ListByAgency(ctx context.Context, agencyID string, p Pagination) ([]*model.BrokerProfile, int, error)
	Search(ctx context.Context, query, city *string, minRating *float64, p Pagination) ([]*model.BrokerProfile, int, error)
	GetStats(ctx context.Context, brokerUserID string) (*model.BrokerStats, error)
	GetAgencyStats(ctx context.Context, agencyID string) (*model.AgencyStats, error)
}

// CandidateProfileRepository handles candidate profile CRUD and search.
type CandidateProfileRepository interface {
	Create(ctx context.Context, profile *model.CandidateProfile) error
	GetByID(ctx context.Context, id string) (*model.CandidateProfile, error)
	Update(ctx context.Context, profile *model.CandidateProfile) error
	Delete(ctx context.Context, id string) error
	List(ctx context.Context, p Pagination) ([]*model.CandidateProfile, int, error)
	ListByBroker(ctx context.Context, brokerUserID string, p Pagination) ([]*model.CandidateProfile, int, error)
	Search(ctx context.Context, filters CandidateSearchFilters, p Pagination) ([]*model.CandidateProfile, int, error)
}

type CandidateSearchFilters struct {
	Query     *string
	BrokerID  *string
	Gender    *model.Gender
	City      *string
	Religion  *string
	MinAge    *int
	MaxAge    *int
}

// AgencyRepository handles agency CRUD and search.
type AgencyRepository interface {
	Create(ctx context.Context, agency *model.Agency) error
	GetByID(ctx context.Context, id string) (*model.Agency, error)
	Update(ctx context.Context, agency *model.Agency) error
	List(ctx context.Context, p Pagination) ([]*model.Agency, int, error)
	Search(ctx context.Context, query, city *string, minRating *float64, p Pagination) ([]*model.Agency, int, error)
}

// LinkRequestRepository handles link request lifecycle.
type LinkRequestRepository interface {
	Create(ctx context.Context, req *model.LinkRequest) error
	GetByID(ctx context.Context, id string) (*model.LinkRequest, error)
	Update(ctx context.Context, req *model.LinkRequest) error
	ListReceived(ctx context.Context, userID string, status *model.LinkRequestStatus, reqType *model.LinkRequestType, p Pagination) ([]*model.LinkRequest, int, error)
	ListSent(ctx context.Context, userID string, status *model.LinkRequestStatus, reqType *model.LinkRequestType, p Pagination) ([]*model.LinkRequest, int, error)
	ListConnections(ctx context.Context, userID string) ([]*model.LinkRequest, error)
	FindDuplicate(ctx context.Context, fromID, toID string, reqType model.LinkRequestType) (*model.LinkRequest, error)
	GetConnectedBrokerIDs(ctx context.Context, parentUserID string) ([]string, error)
	GetConnectedParentIDs(ctx context.Context, brokerUserID string) ([]string, error)
	GetLinkedChildIDs(ctx context.Context, parentUserID string) ([]string, error)
	GetLinkedParentID(ctx context.Context, childUserID string) (*string, error)
}

// SharedProfileRepository handles profile sharing between brokers and parents.
type SharedProfileRepository interface {
	Create(ctx context.Context, sp *model.SharedProfile) error
	GetByID(ctx context.Context, id string) (*model.SharedProfile, error)
	Update(ctx context.Context, sp *model.SharedProfile) error
	ListForUser(ctx context.Context, userID string, response *model.SharedProfileResponse, p Pagination) ([]*model.SharedProfile, int, error)
	ListByBroker(ctx context.Context, brokerUserID string, profileID *string, response *model.SharedProfileResponse, p Pagination) ([]*model.SharedProfile, int, error)
	ListForwarded(ctx context.Context, parentUserID string, p Pagination) ([]*model.SharedProfile, int, error)
	FindDuplicate(ctx context.Context, profileID, sharedWithUserID string) (*model.SharedProfile, error)
}

// MessagingRepository handles conversations and messages.
type MessagingRepository interface {
	GetOrCreateConversation(ctx context.Context, userID1, userID2 string) (*model.Conversation, error)
	GetConversation(ctx context.Context, id string) (*model.Conversation, error)
	ListConversations(ctx context.Context, userID string, p Pagination) ([]*model.Conversation, int, error)
	UpdateConversation(ctx context.Context, conv *model.Conversation) error
	CreateMessage(ctx context.Context, msg *model.ChatMessage) error
	ListMessages(ctx context.Context, conversationID string, p Pagination) ([]*model.ChatMessage, int, error)
	MarkAsRead(ctx context.Context, conversationID, userID string) error
}

// SavedProfileRepository handles bookmarks.
type SavedProfileRepository interface {
	Save(ctx context.Context, sp *model.SavedProfile) error
	Delete(ctx context.Context, userID, profileID string) error
	IsSaved(ctx context.Context, userID, profileID string) (bool, error)
	ListByUser(ctx context.Context, userID string, p Pagination) ([]*model.SavedProfile, int, error)
}

// ViewedProfileRepository tracks profile views.
type ViewedProfileRepository interface {
	RecordView(ctx context.Context, vp *model.ViewedProfile) error
	ListByUser(ctx context.Context, userID string, limit int) ([]*model.ViewedProfile, error)
	ClearHistory(ctx context.Context, userID string) error
}

// ActivityRepository is an append-only event log per candidate profile.
type ActivityRepository interface {
	Record(ctx context.Context, event *model.ProfileActivity) error
	ListByProfile(ctx context.Context, profileID string, limit int) ([]*model.ProfileActivity, error)
}

// NoteRepository handles parent and broker notes.
type NoteRepository interface {
	GetParentNote(ctx context.Context, parentUserID, profileID string) (*model.ParentNote, error)
	UpsertParentNote(ctx context.Context, note *model.ParentNote) error
	ListParentNotes(ctx context.Context, parentUserID string) ([]*model.ParentNote, error)
	DeleteParentNote(ctx context.Context, noteID string) error
	GetBrokerNote(ctx context.Context, brokerUserID, profileID, forParentID string) (*model.BrokerNote, error)
	UpsertBrokerNote(ctx context.Context, note *model.BrokerNote) error
}

// MeetingRepository handles meeting CRUD with visibility filtering.
type MeetingRepository interface {
	Save(ctx context.Context, meeting *model.Meeting) error
	GetByID(ctx context.Context, id string) (*model.Meeting, error)
	ListForPair(ctx context.Context, parentUserID, profileID, viewerUserID string, p Pagination) ([]*model.Meeting, int, error)
	GetNext(ctx context.Context, parentUserID, profileID, viewerUserID string) (*model.Meeting, error)
	Cancel(ctx context.Context, id string) error
}

// ClientEngagementRepository tracks broker-parent commercial relationships.
type ClientEngagementRepository interface {
	Get(ctx context.Context, brokerUserID, parentUserID string) (*model.ClientEngagement, error)
	Upsert(ctx context.Context, engagement *model.ClientEngagement) error
	ListByBroker(ctx context.Context, brokerUserID string) ([]*model.ClientEngagement, error)
}

// BrokerFollowUpRepository manages broker reminder tasks.
type BrokerFollowUpRepository interface {
	Upsert(ctx context.Context, followUp *model.BrokerFollowUp) error
	Delete(ctx context.Context, id string) error
	ListByBroker(ctx context.Context, brokerUserID string) ([]*model.BrokerFollowUp, error)
	ListByClient(ctx context.Context, brokerUserID, clientUserID string) ([]*model.BrokerFollowUp, error)
}
