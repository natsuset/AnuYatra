/// The broker's commercial relationship with one parent client.
///
/// Captures the engagement lifecycle (lead → connection request → paid →
/// active → lapsed), the payment/subscription snapshot (plan, amount, when it
/// was paid, when profile-sharing starts, validity), and the client's stated
/// requirements (budget, expected income). One row per
/// `(brokerUserId, parentUserId)`.
///
/// This is demo/seed-driven — there is no real payment processing. It exists so
/// a broker can SEE and TRACK where each client stands.
enum EngagementStage {
  /// Broker is aware of the client but no connection exists yet.
  lead,

  /// A connection request has been sent and is awaiting acceptance.
  requested,

  /// Connected (linked) but the client hasn't paid — sharing is gated.
  connected,

  /// Payment received; profile-sharing may not have started yet.
  paid,

  /// Paid and sharing is live.
  active,

  /// Subscription validity has passed.
  lapsed;

  String get displayName => switch (this) {
        EngagementStage.lead => 'Lead',
        EngagementStage.requested => 'Request Sent',
        EngagementStage.connected => 'Connected · Unpaid',
        EngagementStage.paid => 'Paid',
        EngagementStage.active => 'Active',
        EngagementStage.lapsed => 'Lapsed',
      };

  /// Short label for a compact chip.
  String get shortLabel => switch (this) {
        EngagementStage.lead => 'Lead',
        EngagementStage.requested => 'Requested',
        EngagementStage.connected => 'Unpaid',
        EngagementStage.paid => 'Paid',
        EngagementStage.active => 'Active',
        EngagementStage.lapsed => 'Lapsed',
      };
}

class ClientEngagement {
  /// Composite id `{brokerUserId}_{parentUserId}`.
  final String id;
  final String brokerUserId;
  final String parentUserId;
  final EngagementStage stage;

  // ── Payment / subscription snapshot ──
  final String? planName;
  final double? amountPaid; // INR
  final DateTime? paidAt;
  final DateTime? sharingStartsAt;
  final DateTime? validUntil;

  // ── Client requirements ──
  final String? budgetExpectation; // e.g. "Wedding budget ₹25–40 L"
  final String? expectedIncomeMin; // e.g. "₹15 LPA+"
  final String? requirementNotes;

  final DateTime createdAt;
  final DateTime updatedAt;

  const ClientEngagement({
    required this.id,
    required this.brokerUserId,
    required this.parentUserId,
    required this.stage,
    this.planName,
    this.amountPaid,
    this.paidAt,
    this.sharingStartsAt,
    this.validUntil,
    this.budgetExpectation,
    this.expectedIncomeMin,
    this.requirementNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClientEngagement.create({
    required String brokerUserId,
    required String parentUserId,
    EngagementStage stage = EngagementStage.lead,
    String? planName,
    double? amountPaid,
    DateTime? paidAt,
    DateTime? sharingStartsAt,
    DateTime? validUntil,
    String? budgetExpectation,
    String? expectedIncomeMin,
    String? requirementNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return ClientEngagement(
      id: '${brokerUserId}_$parentUserId',
      brokerUserId: brokerUserId,
      parentUserId: parentUserId,
      stage: stage,
      planName: planName,
      amountPaid: amountPaid,
      paidAt: paidAt,
      sharingStartsAt: sharingStartsAt,
      validUntil: validUntil,
      budgetExpectation: budgetExpectation,
      expectedIncomeMin: expectedIncomeMin,
      requirementNotes: requirementNotes,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  bool get hasPaid => paidAt != null;

  bool get sharingStarted =>
      sharingStartsAt != null && sharingStartsAt!.isBefore(DateTime.now());

  bool get isExpired =>
      validUntil != null && validUntil!.isBefore(DateTime.now());

  /// Days until profile-sharing begins (negative if already started, null if
  /// no start date set).
  int? get daysUntilSharing {
    if (sharingStartsAt == null) return null;
    return sharingStartsAt!.difference(DateTime.now()).inDays;
  }

  ClientEngagement copyWith({
    EngagementStage? stage,
    String? planName,
    double? amountPaid,
    DateTime? paidAt,
    DateTime? sharingStartsAt,
    DateTime? validUntil,
    String? budgetExpectation,
    String? expectedIncomeMin,
    String? requirementNotes,
    DateTime? updatedAt,
  }) {
    return ClientEngagement(
      id: id,
      brokerUserId: brokerUserId,
      parentUserId: parentUserId,
      stage: stage ?? this.stage,
      planName: planName ?? this.planName,
      amountPaid: amountPaid ?? this.amountPaid,
      paidAt: paidAt ?? this.paidAt,
      sharingStartsAt: sharingStartsAt ?? this.sharingStartsAt,
      validUntil: validUntil ?? this.validUntil,
      budgetExpectation: budgetExpectation ?? this.budgetExpectation,
      expectedIncomeMin: expectedIncomeMin ?? this.expectedIncomeMin,
      requirementNotes: requirementNotes ?? this.requirementNotes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'brokerUserId': brokerUserId,
        'parentUserId': parentUserId,
        'stage': stage.name,
        'planName': planName,
        'amountPaid': amountPaid,
        'paidAt': paidAt?.toIso8601String(),
        'sharingStartsAt': sharingStartsAt?.toIso8601String(),
        'validUntil': validUntil?.toIso8601String(),
        'budgetExpectation': budgetExpectation,
        'expectedIncomeMin': expectedIncomeMin,
        'requirementNotes': requirementNotes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ClientEngagement.fromJson(Map<String, dynamic> json) {
    DateTime? parseDt(Object? v) =>
        v == null ? null : DateTime.tryParse(v as String);
    return ClientEngagement(
      id: json['id'] as String? ?? '',
      brokerUserId: json['brokerUserId'] as String? ?? '',
      parentUserId: json['parentUserId'] as String? ?? '',
      stage: EngagementStage.values.firstWhere(
        (e) => e.name == (json['stage'] as String?),
        orElse: () => EngagementStage.lead,
      ),
      planName: json['planName'] as String?,
      amountPaid: (json['amountPaid'] as num?)?.toDouble(),
      paidAt: parseDt(json['paidAt']),
      sharingStartsAt: parseDt(json['sharingStartsAt']),
      validUntil: parseDt(json['validUntil']),
      budgetExpectation: json['budgetExpectation'] as String?,
      expectedIncomeMin: json['expectedIncomeMin'] as String?,
      requirementNotes: json['requirementNotes'] as String?,
      createdAt: parseDt(json['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: parseDt(json['updatedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
