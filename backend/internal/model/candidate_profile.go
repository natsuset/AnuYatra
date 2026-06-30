package model

import "time"

type Gender string

const (
	GenderBride Gender = "bride"
	GenderGroom Gender = "groom"
)

type ProfileVisibility string

const (
	VisibilityPublic        ProfileVisibility = "public"
	VisibilityConnectedOnly ProfileVisibility = "connectedOnly"
	VisibilityHidden        ProfileVisibility = "hidden"
)

type Diet string

const (
	DietVegetarian    Diet = "vegetarian"
	DietNonVegetarian Diet = "nonVegetarian"
	DietEggetarian    Diet = "eggetarian"
	DietVegan         Diet = "vegan"
	DietJain          Diet = "jain"
)

type FamilyType string

const (
	FamilyTypeJoint   FamilyType = "joint"
	FamilyTypeNuclear FamilyType = "nuclear"
)

type FamilyValues string

const (
	FamilyValuesOrthodox FamilyValues = "orthodox"
	FamilyValuesModerate FamilyValues = "moderate"
	FamilyValuesLiberal  FamilyValues = "liberal"
)

type CandidateProfile struct {
	ID              string            `json:"id"`
	CreatedByUserID string            `json:"createdByUserId"`
	Name            string            `json:"name"`
	Age             int               `json:"age"`
	Gender          Gender            `json:"gender"`
	Profession      string            `json:"profession"`
	Education       string            `json:"education"`
	City            string            `json:"city"`
	Community       string            `json:"community"`
	Height          string            `json:"height"`
	Religion        string            `json:"religion"`
	Caste           string            `json:"caste"`
	MotherTongue    string            `json:"motherTongue"`
	MaritalStatus   string            `json:"maritalStatus"`
	AboutMe         string            `json:"aboutMe"`
	FamilyBackground string           `json:"familyBackground"`
	Interests       []string          `json:"interests"`
	FatherOccupation string           `json:"fatherOccupation"`
	MotherOccupation string           `json:"motherOccupation"`
	Siblings        string            `json:"siblings"`
	Photos          []string          `json:"photos"`
	BrokerIDs       []string          `json:"brokerIds"`
	ParentUserID    *string           `json:"parentUserId"`
	CandidateUserID *string           `json:"candidateUserId"`
	Visibility      ProfileVisibility `json:"visibility"`
	DeduplicationKey *string          `json:"deduplicationKey"`
	ListedWithBrokersCount int        `json:"listedWithBrokersCount"`
	SearchTags      []string          `json:"searchTags"`
	CreatedAt       time.Time         `json:"createdAt"`
	UpdatedAt       time.Time         `json:"updatedAt"`

	DateOfBirth   *time.Time    `json:"dateOfBirth,omitempty"`
	AnnualIncome  *string       `json:"annualIncome,omitempty"`
	Complexion    *string       `json:"complexion,omitempty"`
	Weight        *string       `json:"weight,omitempty"`
	BloodGroup    *string       `json:"bloodGroup,omitempty"`
	DietPref      *Diet         `json:"diet,omitempty"`
	Smokes        *bool         `json:"smokes,omitempty"`
	Drinks        *bool         `json:"drinks,omitempty"`
	ManglikStatus *string       `json:"manglikStatus,omitempty"`
	Gotra         *string       `json:"gotra,omitempty"`
	Rashi         *string       `json:"rashi,omitempty"`
	Nakshatra     *string       `json:"nakshatra,omitempty"`
	BirthTime     *string       `json:"birthTime,omitempty"`
	BirthPlace    *string       `json:"birthPlace,omitempty"`
	FamilyTypePref *FamilyType  `json:"familyType,omitempty"`
	FamilyValuesPref *FamilyValues `json:"familyValues,omitempty"`
	FamilyAffluence *string     `json:"familyAffluence,omitempty"`
	NumberOfBrothers *int       `json:"numberOfBrothers,omitempty"`
	NumberOfSisters  *int       `json:"numberOfSisters,omitempty"`
	OwnHouse      *bool         `json:"ownHouse,omitempty"`
	OwnCar        *bool         `json:"ownCar,omitempty"`
	WillingToRelocate *bool     `json:"willingToRelocate,omitempty"`
	PhysicalStatus *string      `json:"physicalStatus,omitempty"`

	PreferredAgeMin   *int    `json:"preferredAgeMin,omitempty"`
	PreferredAgeMax   *int    `json:"preferredAgeMax,omitempty"`
	PreferredHeightMin *string `json:"preferredHeightMin,omitempty"`
	PreferredHeightMax *string `json:"preferredHeightMax,omitempty"`
	PreferredEducation *string `json:"preferredEducation,omitempty"`
	PreferredProfession *string `json:"preferredProfession,omitempty"`
	PreferredLocation  *string `json:"preferredLocation,omitempty"`
	PreferredReligion  *string `json:"preferredReligion,omitempty"`
	PreferredCaste     *string `json:"preferredCaste,omitempty"`
	PreferredIncomeMin *string `json:"preferredIncomeMin,omitempty"`
}
