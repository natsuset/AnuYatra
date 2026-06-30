package inmem

import (
	"github.com/anuyatra/backend/internal/service"
)

// NewContainer builds a fully-wired in-memory Container for local/dev use.
func NewContainer(jwtSecret string, isDev bool) *service.Container {
	return &service.Container{
		Users:             NewUserRepo(),
		Auth:              NewAuthRepo(isDev),
		ParentProfiles:    NewParentProfileRepo(),
		BrokerProfiles:    NewBrokerProfileRepo(),
		CandidateProfiles: NewCandidateProfileRepo(),
		Agencies:          NewAgencyRepo(),
		LinkRequests:      NewLinkRequestRepo(),
		SharedProfiles:    NewSharedProfileRepo(),
		Messaging:         NewMessagingRepo(),
		SavedProfiles:     NewSavedProfileRepo(),
		ViewedProfiles:    NewViewedProfileRepo(),
		Activity:          NewActivityRepo(),
		Notes:             NewNoteRepo(),
		Meetings:          NewMeetingRepo(),
		Engagements:       NewClientEngagementRepo(),
		FollowUps:         NewBrokerFollowUpRepo(),
		JWTSecret:         jwtSecret,
		JWTAccessExpiry:   service.DefaultAccessExpiry,
		JWTRefreshExpiry:  service.DefaultRefreshExpiry,
		IsDev:             isDev,
	}
}
