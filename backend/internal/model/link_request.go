package model

import "time"

type LinkRequestType string

const (
	LinkParentToBroker LinkRequestType = "parentToBroker"
	LinkParentToAgency LinkRequestType = "parentToAgency"
	LinkAgencyToBroker LinkRequestType = "agencyToBroker"
	LinkChildToParent  LinkRequestType = "childToParent"
)

type LinkRequestStatus string

const (
	LinkStatusPending  LinkRequestStatus = "pending"
	LinkStatusAccepted LinkRequestStatus = "accepted"
	LinkStatusDeclined LinkRequestStatus = "declined"
	LinkStatusRevoked  LinkRequestStatus = "revoked"
)

type LinkRequest struct {
	ID           string            `json:"id"`
	FromUserID   string            `json:"fromUserId"`
	ToUserID     string            `json:"toUserId"`
	FromUserName string            `json:"fromUserName"`
	ToUserName   string            `json:"toUserName"`
	Type         LinkRequestType   `json:"type"`
	Status       LinkRequestStatus `json:"status"`
	CreatedAt    time.Time         `json:"createdAt"`
	RespondedAt  *time.Time        `json:"respondedAt"`
	Note         *string           `json:"note"`
}
