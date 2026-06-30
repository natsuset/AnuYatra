package model

import "time"

type Agency struct {
	ID                 string             `json:"id"`
	AdminUserID        string             `json:"adminUserId"`
	Name               string             `json:"name"`
	LogoURL            *string            `json:"logoUrl"`
	City               string             `json:"city"`
	State              string             `json:"state"`
	Description        string             `json:"description"`
	Specializations    []string           `json:"specializations"`
	AreasServed        []string           `json:"areasServed"`
	Rating             float64            `json:"rating"`
	IsActive           bool               `json:"isActive"`
	CreatedAt          time.Time          `json:"createdAt"`
	Email              *string            `json:"email,omitempty"`
	Phone              *string            `json:"phone,omitempty"`
	Website            *string            `json:"website,omitempty"`
	FoundedYear        *int               `json:"foundedYear,omitempty"`
	LicenseNumber      *string            `json:"licenseNumber,omitempty"`
	TotalStaff         int                `json:"totalStaff"`
	TotalSuccessful    int                `json:"totalSuccessfulMatches"`
	LanguagesServed    []string           `json:"languagesServed"`
	FeeStructure       *string            `json:"feeStructure,omitempty"`
	Awards             []string           `json:"awardsAndRecognition"`
	VerificationStatus VerificationStatus `json:"verificationStatus"`
	OfficeAddresses    []string           `json:"officeAddresses"`
}
