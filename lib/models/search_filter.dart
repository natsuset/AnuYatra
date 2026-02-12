enum SearchType {
  all,
  agencies,
  brokers;

  String get displayName {
    switch (this) {
      case SearchType.all:
        return 'All';
      case SearchType.agencies:
        return 'Agencies';
      case SearchType.brokers:
        return 'Brokers';
    }
  }
}

enum SortBy {
  relevance,
  ratingHighToLow,
  newest,
  nameAZ;

  String get displayName {
    switch (this) {
      case SortBy.relevance:
        return 'Relevance';
      case SortBy.ratingHighToLow:
        return 'Rating: High to Low';
      case SortBy.newest:
        return 'Newest First';
      case SortBy.nameAZ:
        return 'Name: A-Z';
    }
  }
}

class DiscoverySearchFilter {
  final String? query;
  final SearchType searchType;
  final String? city;
  final String? state;
  final List<String> specializations;
  final double? minRating;
  final SortBy sortBy;

  const DiscoverySearchFilter({
    this.query,
    this.searchType = SearchType.all,
    this.city,
    this.state,
    this.specializations = const [],
    this.minRating,
    this.sortBy = SortBy.relevance,
  });

  bool get hasActiveFilters =>
      query != null ||
      searchType != SearchType.all ||
      city != null ||
      state != null ||
      specializations.isNotEmpty ||
      minRating != null;

  DiscoverySearchFilter copyWith({
    String? query,
    SearchType? searchType,
    String? city,
    String? state,
    List<String>? specializations,
    double? minRating,
    SortBy? sortBy,
  }) => DiscoverySearchFilter(
    query: query ?? this.query,
    searchType: searchType ?? this.searchType,
    city: city ?? this.city,
    state: state ?? this.state,
    specializations: specializations ?? this.specializations,
    minRating: minRating ?? this.minRating,
    sortBy: sortBy ?? this.sortBy,
  );

  DiscoverySearchFilter clearAll() => const DiscoverySearchFilter();
}

// --- Candidate Search Filter ---

enum CandidateSortBy {
  newest,
  ageAsc,
  ageDesc,
  nameAZ;

  String get displayName {
    switch (this) {
      case CandidateSortBy.newest:
        return 'Newest First';
      case CandidateSortBy.ageAsc:
        return 'Age: Low to High';
      case CandidateSortBy.ageDesc:
        return 'Age: High to Low';
      case CandidateSortBy.nameAZ:
        return 'Name: A-Z';
    }
  }
}

class CandidateSearchFilter {
  final int? minAge;
  final int? maxAge;
  final String? gender;
  final String? religion;
  final String? caste;
  final String? city;
  final String? education;
  final String? profession;
  final CandidateSortBy sortBy;

  const CandidateSearchFilter({
    this.minAge,
    this.maxAge,
    this.gender,
    this.religion,
    this.caste,
    this.city,
    this.education,
    this.profession,
    this.sortBy = CandidateSortBy.newest,
  });

  bool get hasActiveFilters =>
      minAge != null ||
      maxAge != null ||
      gender != null ||
      religion != null ||
      caste != null ||
      city != null ||
      education != null ||
      profession != null;

  CandidateSearchFilter copyWith({
    int? minAge,
    int? maxAge,
    String? gender,
    String? religion,
    String? caste,
    String? city,
    String? education,
    String? profession,
    CandidateSortBy? sortBy,
  }) => CandidateSearchFilter(
    minAge: minAge ?? this.minAge,
    maxAge: maxAge ?? this.maxAge,
    gender: gender ?? this.gender,
    religion: religion ?? this.religion,
    caste: caste ?? this.caste,
    city: city ?? this.city,
    education: education ?? this.education,
    profession: profession ?? this.profession,
    sortBy: sortBy ?? this.sortBy,
  );

  CandidateSearchFilter clearAll() => const CandidateSearchFilter();
}
