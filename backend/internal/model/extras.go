package model

import "time"

type SavedProfile struct {
	ID        string    `json:"id"`
	UserID    string    `json:"userId"`
	ProfileID string    `json:"profileId"`
	SavedAt   time.Time `json:"savedAt"`
}

type ViewedProfile struct {
	ID        string    `json:"id"`
	UserID    string    `json:"userId"`
	ProfileID string    `json:"profileId"`
	ViewedAt  time.Time `json:"viewedAt"`
}

type ProfileActivityKind string

const (
	ActivityBrokerShared       ProfileActivityKind = "brokerSharedProfile"
	ActivityBrokerMessage      ProfileActivityKind = "brokerSentMessage"
	ActivityParentInterested   ProfileActivityKind = "parentMarkedInterested"
	ActivityParentPass         ProfileActivityKind = "parentMarkedPass"
	ActivityParentSaved        ProfileActivityKind = "parentSavedProfile"
	ActivityParentForwarded    ProfileActivityKind = "parentForwardedToChild"
	ActivityChildInterested    ProfileActivityKind = "childMarkedInterested"
	ActivityChildPass          ProfileActivityKind = "childMarkedPass"
	ActivityMeetingScheduled   ProfileActivityKind = "meetingScheduled"
	ActivityMeetingCompleted   ProfileActivityKind = "meetingCompleted"
	ActivityMeetingCancelled   ProfileActivityKind = "meetingCancelled"
	ActivityBrokerNoteAdded    ProfileActivityKind = "brokerNoteAdded"
	ActivityParentNoteAdded    ProfileActivityKind = "parentNoteAdded"
	ActivityProfileViewed      ProfileActivityKind = "profileViewed"
)

type ProfileActivity struct {
	ID           string              `json:"id"`
	ProfileID    string              `json:"profileId"`
	ActorUserID  *string             `json:"actorUserId"`
	ActorName    *string             `json:"actorName"`
	Kind         ProfileActivityKind `json:"kind"`
	At           time.Time           `json:"at"`
	Meta         map[string]any      `json:"meta"`
}

type ParentNote struct {
	ID                 string    `json:"id"`
	ParentUserID       string    `json:"parentUserId"`
	CandidateProfileID string    `json:"candidateProfileId"`
	Body               string    `json:"body"`
	UpdatedAt          time.Time `json:"updatedAt"`
}

type BrokerNote struct {
	ID                 string    `json:"id"`
	BrokerUserID       string    `json:"brokerUserId"`
	CandidateProfileID string    `json:"candidateProfileId"`
	ForParentUserID    string    `json:"forParentUserId"`
	Body               string    `json:"body"`
	UpdatedAt          time.Time `json:"updatedAt"`
}

// ── Client Engagements ──────────────────────────────────────────────

type EngagementStage string

const (
	StageLead      EngagementStage = "lead"
	StageRequested EngagementStage = "requested"
	StageConnected EngagementStage = "connected"
	StagePaid      EngagementStage = "paid"
	StageActive    EngagementStage = "active"
	StageLapsed    EngagementStage = "lapsed"
)

type ClientEngagement struct {
	ID                string          `json:"id"`
	BrokerUserID      string          `json:"brokerUserId"`
	ParentUserID      string          `json:"parentUserId"`
	Stage             EngagementStage `json:"stage"`
	PlanName          *string         `json:"planName,omitempty"`
	AmountPaid        *float64        `json:"amountPaid,omitempty"`
	PaidAt            *time.Time      `json:"paidAt,omitempty"`
	SharingStartsAt   *time.Time      `json:"sharingStartsAt,omitempty"`
	ValidUntil        *time.Time      `json:"validUntil,omitempty"`
	BudgetExpectation *string         `json:"budgetExpectation,omitempty"`
	ExpectedIncomeMin *string         `json:"expectedIncomeMin,omitempty"`
	RequirementNotes  *string         `json:"requirementNotes,omitempty"`
	CreatedAt         time.Time       `json:"createdAt"`
	UpdatedAt         time.Time       `json:"updatedAt"`
}

// ── Broker Follow-ups ───────────────────────────────────────────────

type FollowUpPriority string

const (
	PriorityLow    FollowUpPriority = "low"
	PriorityNormal FollowUpPriority = "normal"
	PriorityHigh   FollowUpPriority = "high"
)

type BrokerFollowUp struct {
	ID                 string           `json:"id"`
	BrokerUserID       string           `json:"brokerUserId"`
	ClientUserID       *string          `json:"clientUserId,omitempty"`
	CandidateProfileID *string          `json:"candidateProfileId,omitempty"`
	Title              string           `json:"title"`
	Notes              string           `json:"notes"`
	DueAt              time.Time        `json:"dueAt"`
	Priority           FollowUpPriority `json:"priority"`
	IsDone             bool             `json:"isDone"`
	CreatedAt          time.Time        `json:"createdAt"`
	CompletedAt        *time.Time       `json:"completedAt,omitempty"`
}

// ── Meetings ────────────────────────────────────────────────────────

type MeetingScheduledBy string

const (
	ScheduledByParent    MeetingScheduledBy = "parent"
	ScheduledByCandidate MeetingScheduledBy = "candidate"
	ScheduledByBroker    MeetingScheduledBy = "broker"
)

type MeetingType string

const (
	MeetingInPerson MeetingType = "inPerson"
	MeetingVirtual  MeetingType = "virtual"
	MeetingPhone    MeetingType = "phone"
)

type MeetingStatus string

const (
	MeetingScheduled MeetingStatus = "scheduled"
	MeetingCompleted MeetingStatus = "completed"
	MeetingCancelled MeetingStatus = "cancelled"
)

type Meeting struct {
	ID                 string             `json:"id"`
	CandidateProfileID string            `json:"candidateProfileId"`
	ParentUserID       string             `json:"parentUserId"`
	BrokerUserID       string             `json:"brokerUserId"`
	ScheduledByUserID  string             `json:"scheduledByUserId"`
	ScheduledByRole    MeetingScheduledBy `json:"scheduledByRole"`
	BrokerVisible      bool               `json:"brokerVisible"`
	ParentPartyVisible bool               `json:"parentPartyVisible"`
	When               time.Time          `json:"when"`
	DurationMinutes    int                `json:"durationMinutes"`
	Type               MeetingType        `json:"type"`
	Location           string             `json:"location"`
	VirtualLink        *string            `json:"virtualLink,omitempty"`
	Status             MeetingStatus      `json:"status"`
	Notes              *string            `json:"notes,omitempty"`
	CreatedAt          time.Time          `json:"createdAt"`
}
