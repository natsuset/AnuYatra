enum UserRole {
  agencyAdmin,
  broker,
  parent,
  candidate;

  String get displayName {
    switch (this) {
      case UserRole.agencyAdmin:
        return 'Agency';
      case UserRole.broker:
        return 'Broker';
      case UserRole.parent:
        return 'Parent / Family';
      case UserRole.candidate:
        return 'Bride / Groom';
    }
  }

  String get description {
    switch (this) {
      case UserRole.agencyAdmin:
        return 'I run a matrimonial agency and want to manage my brokers and clients';
      case UserRole.broker:
        return 'I help families find the perfect match for their children';
      case UserRole.parent:
        return 'I\'m looking for a match for my son or daughter';
      case UserRole.candidate:
        return 'I\'m looking for my own life partner';
    }
  }

  String get icon {
    switch (this) {
      case UserRole.agencyAdmin:
        return '🏢';
      case UserRole.broker:
        return '🤝';
      case UserRole.parent:
        return '👨‍👩‍👧';
      case UserRole.candidate:
        return '💍';
    }
  }
}
