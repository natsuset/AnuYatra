package service

import (
	"time"

	"github.com/anuyatra/backend/internal/repository"
)

const (
	DefaultAccessExpiry  = 15 * time.Minute
	DefaultRefreshExpiry = 7 * 24 * time.Hour
)

// Container is the dependency injection root. Handlers depend on repository
// interfaces only — swap implementations by building a different Container.
type Container struct {
	Users             repository.UserRepository
	Auth              repository.AuthRepository
	ParentProfiles    repository.ParentProfileRepository
	BrokerProfiles    repository.BrokerProfileRepository
	CandidateProfiles repository.CandidateProfileRepository
	Agencies          repository.AgencyRepository
	LinkRequests      repository.LinkRequestRepository
	SharedProfiles    repository.SharedProfileRepository
	Messaging         repository.MessagingRepository
	SavedProfiles     repository.SavedProfileRepository
	ViewedProfiles    repository.ViewedProfileRepository
	Activity          repository.ActivityRepository
	Notes             repository.NoteRepository
	Meetings          repository.MeetingRepository
	Engagements       repository.ClientEngagementRepository
	FollowUps         repository.BrokerFollowUpRepository

	JWTSecret        string
	JWTAccessExpiry  time.Duration
	JWTRefreshExpiry time.Duration
	IsDev            bool
}
