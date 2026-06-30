package model

import "time"

type UserRole string

const (
	RoleParent      UserRole = "parent"
	RoleBroker      UserRole = "broker"
	RoleCandidate   UserRole = "candidate"
	RoleAgencyAdmin UserRole = "agencyAdmin"
)

func (r UserRole) IsValid() bool {
	switch r {
	case RoleParent, RoleBroker, RoleCandidate, RoleAgencyAdmin:
		return true
	}
	return false
}

type AppUser struct {
	UID         string   `json:"uid"`
	PhoneNumber string   `json:"phoneNumber"`
	DisplayName string   `json:"displayName"`
	PhotoURL    *string  `json:"photoUrl"`
	Role        UserRole `json:"role"`
	AgencyID    *string  `json:"agencyId"`
	CreatedAt   time.Time `json:"createdAt"`
	IsActive    bool     `json:"isActive"`
}
