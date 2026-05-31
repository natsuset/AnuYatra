/// Role-specific data carried into [AuthNotifier.completeProfileSetup].
///
/// Sealed so the auth provider can exhaustively switch on the variant
/// and the call sites only ever construct the fields relevant to one role —
/// no more 18-parameter optional-everything method.
sealed class ProfileSetupData {
  const ProfileSetupData();
}

/// Setup data for an agency-admin role.
class AgencySetupData extends ProfileSetupData {
  final String? name;
  final String city;
  final String state;
  final String description;
  final List<String> specializations;

  const AgencySetupData({
    this.name,
    this.city = '',
    this.state = '',
    this.description = '',
    this.specializations = const [],
  });
}

/// Setup data for a broker role.
class BrokerSetupData extends ProfileSetupData {
  final String bio;
  final List<String> specializations;
  final List<String> areasServed;
  final int experienceYears;

  const BrokerSetupData({
    this.bio = '',
    this.specializations = const [],
    this.areasServed = const [],
    this.experienceYears = 0,
  });
}

/// Setup data for a parent role.
class ParentSetupData extends ProfileSetupData {
  /// 'bride' or 'groom' — what kind of match the parent is looking for.
  final String lookingFor;
  final String city;
  final String state;

  const ParentSetupData({
    required this.lookingFor,
    this.city = '',
    this.state = '',
  });
}

/// Setup data for a candidate role. Currently minimal; parent + broker
/// manage the richer profile fields after the candidate links.
class CandidateSetupData extends ProfileSetupData {
  final int? age;
  final String? gender;

  const CandidateSetupData({this.age, this.gender});
}
