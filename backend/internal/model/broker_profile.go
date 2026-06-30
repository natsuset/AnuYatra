package model

import "time"

type VerificationStatus string

const (
	VerificationUnverified VerificationStatus = "unverified"
	VerificationPending    VerificationStatus = "pending"
	VerificationVerified   VerificationStatus = "verified"
)

type BrokerProfile struct {
	UserID             string             `json:"userId"`
	AgencyID           *string            `json:"agencyId"`
	Name               string             `json:"name"`
	PhoneNumber        string             `json:"phoneNumber"`
	PhotoURL           *string            `json:"photoUrl"`
	Specializations    []string           `json:"specializations"`
	AreasServed        []string           `json:"areasServed"`
	ExperienceYears    int                `json:"experienceYears"`
	ClientCount        int                `json:"clientCount"`
	ProfilesManaged    int                `json:"profilesManaged"`
	Rating             float64            `json:"rating"`
	Bio                string             `json:"bio"`
	IsOnline           bool               `json:"isOnline"`
	LastSeen           time.Time          `json:"lastSeen"`
	CreatedAt          time.Time          `json:"createdAt"`
	Email              *string            `json:"email,omitempty"`
	OfficeAddress      *string            `json:"officeAddress,omitempty"`
	Website            *string            `json:"website,omitempty"`
	LicenseNumber      *string            `json:"licenseNumber,omitempty"`
	LanguagesSpoken    []string           `json:"languagesSpoken"`
	TotalSuccessful    int                `json:"totalSuccessfulMatches"`
	FeeStructure       *string            `json:"feeStructure,omitempty"`
	WorkingHours       *string            `json:"workingHours,omitempty"`
	SocialMediaLinks   map[string]string  `json:"socialMediaLinks"`
	VerificationStatus VerificationStatus `json:"verificationStatus"`
}

type BrokerStats struct {
	ActiveClients   int `json:"activeClients"`
	ProfilesManaged int `json:"profilesManaged"`
	ProfilesShared  int `json:"profilesShared"`
	PendingRequests int `json:"pendingRequests"`
}

type AgencyStats struct {
	TotalBrokers  int `json:"totalBrokers"`
	TotalClients  int `json:"totalClients"`
	TotalProfiles int `json:"totalProfiles"`
}
