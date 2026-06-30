package model

import "time"

type LookingFor string

const (
	LookingForBride LookingFor = "bride"
	LookingForGroom LookingFor = "groom"
)

type Lifestyle string

const (
	LifestyleSimple    Lifestyle = "simple"
	LifestyleModerate  Lifestyle = "moderate"
	LifestyleLuxurious Lifestyle = "luxurious"
)

type ParentProfile struct {
	UserID               string     `json:"userId"`
	Name                 string     `json:"name"`
	LookingFor           LookingFor `json:"lookingFor"`
	City                 string     `json:"city"`
	State                string     `json:"state"`
	PreferredCommunities []string   `json:"preferredCommunities"`
	PreferredMinAge      *int       `json:"preferredMinAge"`
	PreferredMaxAge      *int       `json:"preferredMaxAge"`
	CreatedAt            time.Time  `json:"createdAt"`

	Email          *string `json:"email,omitempty"`
	WhatsAppNumber *string `json:"whatsappNumber,omitempty"`
	AlternatePhone *string `json:"alternatePhone,omitempty"`

	ChildName          *string    `json:"childName,omitempty"`
	ChildDateOfBirth   *time.Time `json:"childDateOfBirth,omitempty"`
	ChildHeight        *string    `json:"childHeight,omitempty"`
	ChildWeight        *string    `json:"childWeight,omitempty"`
	ChildComplexion    *string    `json:"childComplexion,omitempty"`
	ChildBloodGroup    *string    `json:"childBloodGroup,omitempty"`
	ChildDiet          *Diet      `json:"childDiet,omitempty"`
	ChildSmokes        *bool      `json:"childSmokes,omitempty"`
	ChildDrinks        *bool      `json:"childDrinks,omitempty"`
	ChildPhysicalStatus *string   `json:"childPhysicalStatus,omitempty"`
	ChildManglikStatus *string    `json:"childManglikStatus,omitempty"`
	ChildEducation     *string    `json:"childEducation,omitempty"`
	ChildProfession    *string    `json:"childProfession,omitempty"`
	ChildIncome        *string    `json:"childIncome,omitempty"`

	ChildRashi      *string `json:"childRashi,omitempty"`
	ChildNakshatra  *string `json:"childNakshatra,omitempty"`
	ChildGotra      *string `json:"childGotra,omitempty"`
	ChildBirthTime  *string `json:"childBirthTime,omitempty"`
	ChildBirthPlace *string `json:"childBirthPlace,omitempty"`

	FamilyTypePref   *FamilyType   `json:"familyType,omitempty"`
	FamilyValuesPref *FamilyValues `json:"familyValues,omitempty"`
	FamilyAffluence  *string       `json:"familyAffluence,omitempty"`
	NumberOfBrothers *int          `json:"numberOfBrothers,omitempty"`
	NumberOfSisters  *int          `json:"numberOfSisters,omitempty"`
	FatherOccupation *string       `json:"fatherOccupation,omitempty"`
	MotherOccupation *string       `json:"motherOccupation,omitempty"`
	FamilyLivingIn   *string       `json:"familyLivingIn,omitempty"`
	AboutFamily      *string       `json:"aboutFamily,omitempty"`

	OwnHouse          *bool      `json:"ownHouse,omitempty"`
	OwnCar            *bool      `json:"ownCar,omitempty"`
	WillingToRelocate  *bool     `json:"willingToRelocate,omitempty"`
	LifestylePref      *Lifestyle `json:"lifestyle,omitempty"`

	PreferredHeightMin   *string `json:"preferredHeightMin,omitempty"`
	PreferredHeightMax   *string `json:"preferredHeightMax,omitempty"`
	PreferredComplexion  *string `json:"preferredComplexion,omitempty"`
	PreferredEducation   *string `json:"preferredEducation,omitempty"`
	PreferredProfession  *string `json:"preferredProfession,omitempty"`
	PreferredIncomeMin   *string `json:"preferredIncomeMin,omitempty"`
	PreferredDiet        *Diet   `json:"preferredDiet,omitempty"`
	PreferredLocation    *string `json:"preferredLocation,omitempty"`
	PreferredReligion    *string `json:"preferredReligion,omitempty"`
	PreferredCaste       *string `json:"preferredCaste,omitempty"`
	PreferredMotherTongue *string `json:"preferredMotherTongue,omitempty"`
}
