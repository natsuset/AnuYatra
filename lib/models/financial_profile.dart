enum IncomeRange {
  below5L,
  range5to10L,
  range10to15L,
  range15to25L,
  range25to40L,
  above40L,
}

enum LifestyleType { simple, moderate, comfortable, luxury }

enum SavingPhilosophy { conservative, balanced, aggressive, spendThrift }

enum CareerStability { stable, growing, changing, entrepreneur }

class FinancialProfile {
  final String userId;
  final IncomeRange familyIncomeRange;
  final LifestyleType lifestylePreference;
  final SavingPhilosophy savingApproach;
  final CareerStability careerStatus;
  final WeddingBudgetPlan weddingPlanning;
  final FutureFinancialGoals futureGoals;
  final bool supportsDualIncome;
  final int profileCompleteness;
  final DateTime lastUpdated;

  FinancialProfile({
    required this.userId,
    required this.familyIncomeRange,
    required this.lifestylePreference,
    required this.savingApproach,
    required this.careerStatus,
    required this.weddingPlanning,
    required this.futureGoals,
    this.supportsDualIncome = true,
    this.profileCompleteness = 0,
    required this.lastUpdated,
  });

  String get incomeDisplayRange {
    switch (familyIncomeRange) {
      case IncomeRange.below5L:
        return 'Below ₹5L';
      case IncomeRange.range5to10L:
        return '₹5L - ₹10L';
      case IncomeRange.range10to15L:
        return '₹10L - ₹15L';
      case IncomeRange.range15to25L:
        return '₹15L - ₹25L';
      case IncomeRange.range25to40L:
        return '₹25L - ₹40L';
      case IncomeRange.above40L:
        return 'Above ₹40L';
    }
  }

  String get lifestyleDisplayName {
    switch (lifestylePreference) {
      case LifestyleType.simple:
        return 'Simple & Traditional';
      case LifestyleType.moderate:
        return 'Moderate Comfort';
      case LifestyleType.comfortable:
        return 'Comfortable Modern';
      case LifestyleType.luxury:
        return 'Luxury Lifestyle';
    }
  }

  String get savingDisplayName {
    switch (savingApproach) {
      case SavingPhilosophy.conservative:
        return 'Conservative Saver';
      case SavingPhilosophy.balanced:
        return 'Balanced Approach';
      case SavingPhilosophy.aggressive:
        return 'Aggressive Saver';
      case SavingPhilosophy.spendThrift:
        return 'Experience Focused';
    }
  }
}

class WeddingBudgetPlan {
  final String totalBudgetRange;
  final Map<String, String> brideContributions;
  final Map<String, String> groomContributions;
  final String ceremonyScale;
  final String honeymoonBudget;
  final bool isFlexible;

  WeddingBudgetPlan({
    required this.totalBudgetRange,
    required this.brideContributions,
    required this.groomContributions,
    required this.ceremonyScale,
    required this.honeymoonBudget,
    this.isFlexible = true,
  });

  static WeddingBudgetPlan getDefault() {
    return WeddingBudgetPlan(
      totalBudgetRange: '₹18L - ₹23L',
      brideContributions: {
        'Ceremony & Reception': '₹4.5L - ₹6L',
        'Jewelry & Gold': '₹3L - ₹4.5L',
        'Clothing & Accessories': '₹1.5L - ₹2.25L',
      },
      groomContributions: {
        'Photography & Video': '₹1.5L - ₹2.25L',
        'Music & Entertainment': '₹1L - ₹1.5L',
        'Transportation': '₹75K - ₹1.12L',
        'Honeymoon': '₹2.25L - ₹3.37L',
        'House Setup': '₹5L - ₹7.5L',
      },
      ceremonyScale: 'Grand Traditional',
      honeymoonBudget: '₹2.25L - ₹3.37L',
    );
  }
}

class FutureFinancialGoals {
  final String homePurchaseTimeline;
  final String childrenEducationPlan;
  final String parentsCareApproach;
  final String retirementStrategy;
  final List<String> investmentPreferences;
  final bool hasEmergencyFund;

  FutureFinancialGoals({
    required this.homePurchaseTimeline,
    required this.childrenEducationPlan,
    required this.parentsCareApproach,
    required this.retirementStrategy,
    required this.investmentPreferences,
    this.hasEmergencyFund = false,
  });

  static FutureFinancialGoals getDefault() {
    return FutureFinancialGoals(
      homePurchaseTimeline: '2-3 years',
      childrenEducationPlan: 'Premium education with SIPs',
      parentsCareApproach: 'Joint responsibility',
      retirementStrategy: 'Mutual funds & PPF',
      investmentPreferences: ['Mutual Funds', 'PPF', 'Real Estate'],
    );
  }
}

class FinancialCompatibility {
  final String userAId;
  final String userBId;
  final int overallCompatibility;
  final Map<String, int> categoryScores;
  final List<String> alignmentPoints;
  final List<String> discussionNeeded;
  final DateTime calculatedAt;

  FinancialCompatibility({
    required this.userAId,
    required this.userBId,
    required this.overallCompatibility,
    required this.categoryScores,
    required this.alignmentPoints,
    required this.discussionNeeded,
    required this.calculatedAt,
  });

  String get compatibilityLevel {
    if (overallCompatibility >= 90) return 'EXCELLENT';
    if (overallCompatibility >= 80) return 'VERY GOOD';
    if (overallCompatibility >= 70) return 'GOOD';
    if (overallCompatibility >= 60) return 'FAIR';
    return 'NEEDS DISCUSSION';
  }

  String get compatibilityEmoji {
    if (overallCompatibility >= 90) return '🎯';
    if (overallCompatibility >= 80) return '✅';
    if (overallCompatibility >= 70) return '👍';
    if (overallCompatibility >= 60) return '⚠️';
    return '🔴';
  }
}
