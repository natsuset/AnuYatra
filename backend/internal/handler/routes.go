package handler

import (
	"net/http"

	"github.com/anuyatra/backend/internal/middleware"
	"github.com/anuyatra/backend/internal/service"
)

// RegisterRoutes wires all API v1 routes. Public auth routes skip JWT;
// everything else is wrapped with Auth middleware.
func RegisterRoutes(mux *http.ServeMux, c *service.Container) {
	svc = c
	auth := middleware.Auth(c.JWTSecret)

	// Auth (public)
	mux.HandleFunc("POST /api/v1/auth/send-otp", handleSendOTP)
	mux.HandleFunc("POST /api/v1/auth/verify-otp", handleVerifyOTP)
	mux.HandleFunc("POST /api/v1/auth/refresh", handleRefreshToken)
	mux.HandleFunc("POST /api/v1/auth/logout", handleLogout)

	// Users
	mux.Handle("GET /api/v1/users/me", auth(http.HandlerFunc(handleGetMe)))
	mux.Handle("PUT /api/v1/users/me", auth(http.HandlerFunc(handleUpdateMe)))
	mux.Handle("POST /api/v1/users/setup-profile", auth(http.HandlerFunc(handleSetupProfile)))
	mux.Handle("GET /api/v1/users", auth(http.HandlerFunc(handleListUsers)))
	mux.Handle("GET /api/v1/users/{id}", auth(http.HandlerFunc(handleGetUser)))

	// Parent profiles
	mux.Handle("GET /api/v1/parent-profiles/me", auth(http.HandlerFunc(handleGetMyParentProfile)))
	mux.Handle("PUT /api/v1/parent-profiles/me", auth(http.HandlerFunc(handleUpdateMyParentProfile)))
	mux.Handle("GET /api/v1/parent-profiles", auth(http.HandlerFunc(handleListParentProfiles)))
	mux.Handle("GET /api/v1/parent-profiles/{userId}", auth(http.HandlerFunc(handleGetParentProfile)))

	// Broker profiles
	mux.Handle("GET /api/v1/broker-profiles/me", auth(http.HandlerFunc(handleGetMyBrokerProfile)))
	mux.Handle("PUT /api/v1/broker-profiles/me", auth(http.HandlerFunc(handleUpdateMyBrokerProfile)))
	mux.Handle("GET /api/v1/broker-profiles/{userId}", auth(http.HandlerFunc(handleGetBrokerProfile)))
	mux.Handle("GET /api/v1/broker-profiles", auth(http.HandlerFunc(handleListBrokerProfiles)))
	mux.Handle("GET /api/v1/broker-profiles/{userId}/stats", auth(http.HandlerFunc(handleGetBrokerStats)))

	// Candidate profiles
	mux.Handle("POST /api/v1/candidate-profiles", auth(http.HandlerFunc(handleCreateCandidateProfile)))
	mux.Handle("GET /api/v1/candidate-profiles/{id}", auth(http.HandlerFunc(handleGetCandidateProfile)))
	mux.Handle("PUT /api/v1/candidate-profiles/{id}", auth(http.HandlerFunc(handleUpdateCandidateProfile)))
	mux.Handle("DELETE /api/v1/candidate-profiles/{id}", auth(http.HandlerFunc(handleDeleteCandidateProfile)))
	mux.Handle("GET /api/v1/candidate-profiles", auth(http.HandlerFunc(handleListCandidateProfiles)))
	mux.Handle("GET /api/v1/candidate-profiles/{id}/activity", auth(http.HandlerFunc(handleGetProfileActivity)))

	// Agencies
	mux.Handle("POST /api/v1/agencies", auth(http.HandlerFunc(handleCreateAgency)))
	mux.Handle("GET /api/v1/agencies/{id}", auth(http.HandlerFunc(handleGetAgency)))
	mux.Handle("PUT /api/v1/agencies/{id}", auth(http.HandlerFunc(handleUpdateAgency)))
	mux.Handle("GET /api/v1/agencies", auth(http.HandlerFunc(handleListAgencies)))
	mux.Handle("GET /api/v1/agencies/{id}/stats", auth(http.HandlerFunc(handleGetAgencyStats)))
	mux.Handle("GET /api/v1/agencies/{id}/brokers", auth(http.HandlerFunc(handleListAgencyBrokers)))

	// Link requests
	mux.Handle("POST /api/v1/link-requests", auth(http.HandlerFunc(handleCreateLinkRequest)))
	mux.Handle("POST /api/v1/link-requests/{id}/accept", auth(http.HandlerFunc(handleAcceptLinkRequest)))
	mux.Handle("POST /api/v1/link-requests/{id}/decline", auth(http.HandlerFunc(handleDeclineLinkRequest)))
	mux.Handle("POST /api/v1/link-requests/{id}/revoke", auth(http.HandlerFunc(handleRevokeLinkRequest)))
	mux.Handle("GET /api/v1/link-requests/received", auth(http.HandlerFunc(handleListReceivedLinkRequests)))
	mux.Handle("GET /api/v1/link-requests/sent", auth(http.HandlerFunc(handleListSentLinkRequests)))
	mux.Handle("GET /api/v1/link-requests/connections", auth(http.HandlerFunc(handleListConnections)))
	mux.Handle("GET /api/v1/link-requests/connected-brokers", auth(http.HandlerFunc(handleGetConnectedBrokers)))
	mux.Handle("GET /api/v1/link-requests/connected-parents", auth(http.HandlerFunc(handleGetConnectedParents)))
	mux.Handle("GET /api/v1/link-requests/linked-children", auth(http.HandlerFunc(handleGetLinkedChildren)))
	mux.Handle("GET /api/v1/link-requests/linked-parent", auth(http.HandlerFunc(handleGetLinkedParent)))

	// Shared profiles
	mux.Handle("POST /api/v1/shared-profiles", auth(http.HandlerFunc(handleShareProfile)))
	mux.Handle("GET /api/v1/shared-profiles/for-me", auth(http.HandlerFunc(handleGetSharedProfilesForMe)))
	mux.Handle("GET /api/v1/shared-profiles/by-me", auth(http.HandlerFunc(handleGetSharedProfilesByMe)))
	mux.Handle("GET /api/v1/shared-profiles/forwarded", auth(http.HandlerFunc(handleGetForwardedProfiles)))
	mux.Handle("PUT /api/v1/shared-profiles/{id}/respond", auth(http.HandlerFunc(handleRespondToSharedProfile)))
	mux.Handle("POST /api/v1/shared-profiles/{id}/forward", auth(http.HandlerFunc(handleForwardProfile)))

	// Conversations & messaging
	mux.Handle("POST /api/v1/conversations", auth(http.HandlerFunc(handleGetOrCreateConversation)))
	mux.Handle("GET /api/v1/conversations", auth(http.HandlerFunc(handleListConversations)))
	mux.Handle("GET /api/v1/conversations/{id}/messages", auth(http.HandlerFunc(handleListMessages)))
	mux.Handle("POST /api/v1/conversations/{id}/messages", auth(http.HandlerFunc(handleSendMessage)))
	mux.Handle("POST /api/v1/conversations/{id}/read", auth(http.HandlerFunc(handleMarkAsRead)))

	// Saved profiles
	mux.Handle("POST /api/v1/saved-profiles", auth(http.HandlerFunc(handleSaveProfile)))
	mux.Handle("DELETE /api/v1/saved-profiles/{profileId}", auth(http.HandlerFunc(handleUnsaveProfile)))
	mux.Handle("GET /api/v1/saved-profiles", auth(http.HandlerFunc(handleListSavedProfiles)))
	mux.Handle("GET /api/v1/saved-profiles/check/{profileId}", auth(http.HandlerFunc(handleCheckSaved)))

	// Viewed profiles
	mux.Handle("POST /api/v1/viewed-profiles", auth(http.HandlerFunc(handleRecordView)))
	mux.Handle("GET /api/v1/viewed-profiles", auth(http.HandlerFunc(handleListViews)))
	mux.Handle("DELETE /api/v1/viewed-profiles", auth(http.HandlerFunc(handleClearViews)))

	// Notes
	mux.Handle("GET /api/v1/notes/parent", auth(http.HandlerFunc(handleGetParentNote)))
	mux.Handle("GET /api/v1/notes/parent/all", auth(http.HandlerFunc(handleListParentNotes)))
	mux.Handle("PUT /api/v1/notes/parent", auth(http.HandlerFunc(handleUpsertParentNote)))
	mux.Handle("DELETE /api/v1/notes/parent/{id}", auth(http.HandlerFunc(handleDeleteParentNote)))
	mux.Handle("GET /api/v1/notes/broker", auth(http.HandlerFunc(handleGetBrokerNote)))
	mux.Handle("PUT /api/v1/notes/broker", auth(http.HandlerFunc(handleUpsertBrokerNote)))

	// Meetings
	mux.Handle("POST /api/v1/meetings", auth(http.HandlerFunc(handleCreateMeeting)))
	mux.Handle("GET /api/v1/meetings/{id}", auth(http.HandlerFunc(handleGetMeeting)))
	mux.Handle("GET /api/v1/meetings", auth(http.HandlerFunc(handleListMeetings)))
	mux.Handle("GET /api/v1/meetings/next", auth(http.HandlerFunc(handleGetNextMeeting)))
	mux.Handle("POST /api/v1/meetings/{id}/cancel", auth(http.HandlerFunc(handleCancelMeeting)))

	// Broker client engagements
	mux.Handle("GET /api/v1/broker/engagements", auth(http.HandlerFunc(handleGetClientEngagement)))
	mux.Handle("GET /api/v1/broker/engagements/all", auth(http.HandlerFunc(handleListClientEngagements)))
	mux.Handle("PUT /api/v1/broker/engagements", auth(http.HandlerFunc(handleUpsertClientEngagement)))

	// Broker follow-ups
	mux.Handle("GET /api/v1/broker/follow-ups", auth(http.HandlerFunc(handleListBrokerFollowUps)))
	mux.Handle("PUT /api/v1/broker/follow-ups", auth(http.HandlerFunc(handleUpsertBrokerFollowUp)))
	mux.Handle("DELETE /api/v1/broker/follow-ups/{id}", auth(http.HandlerFunc(handleDeleteBrokerFollowUp)))

	// File uploads
	mux.Handle("POST /api/v1/uploads/presigned-url", auth(http.HandlerFunc(handleGetPresignedURL)))
}
