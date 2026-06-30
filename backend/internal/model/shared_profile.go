package model

import "time"

type SharedProfileResponse string

const (
	ResponsePending    SharedProfileResponse = "pending"
	ResponseInterested SharedProfileResponse = "interested"
	ResponsePass       SharedProfileResponse = "pass"
)

type SharedProfile struct {
	ID               string                 `json:"id"`
	ProfileID        string                 `json:"profileId"`
	SharedByUserID   string                 `json:"sharedByUserId"`
	SharedWithUserID string                 `json:"sharedWithUserId"`
	SharedAt         time.Time              `json:"sharedAt"`
	ParentResponse   SharedProfileResponse  `json:"parentResponse"`
	ForwardedToChild bool                   `json:"forwardedToChild"`
	ChildResponse    *SharedProfileResponse `json:"childResponse"`
	ParentNote       *string                `json:"parentNote"`
}
