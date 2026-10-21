class TandaModel {
  final String id;
  final String title;
  final String? description;
  final String organizerId;
  final String currency;
  final double contributionAmount;
  final int totalSlots;
  final double payoutTotal;
  final String frequency;
  final String assignmentMethod;
  final String status;
  final int gracePeriodDays;
  final double lateFeePerDay;
  final String inviteCode;
  final DateTime? startDate;
  final DateTime createdAt;
  final String? organizerName;
  // En sorteo, los números siguen ocultos mientras esto sea null
  final DateTime? numbersDrawnAt;

  // Solo vienen en el listado (GET /tandas): avance y turnos del usuario actual
  final int? currentRoundNumber;
  final List<int> mySlotNumbers;
  final DateTime? myNextPayoutDate;

  TandaModel({
    required this.id,
    required this.title,
    this.description,
    required this.organizerId,
    required this.currency,
    required this.contributionAmount,
    required this.totalSlots,
    required this.payoutTotal,
    required this.frequency,
    required this.assignmentMethod,
    required this.status,
    required this.gracePeriodDays,
    required this.lateFeePerDay,
    required this.inviteCode,
    this.startDate,
    required this.createdAt,
    this.organizerName,
    this.numbersDrawnAt,
    this.currentRoundNumber,
    this.mySlotNumbers = const [],
    this.myNextPayoutDate,
  });

  factory TandaModel.fromJson(Map<String, dynamic> json) {
    return TandaModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      organizerId: json['organizer_id'] as String,
      currency: json['currency'] as String? ?? 'MXN',
      contributionAmount: (json['contribution_amount'] as num).toDouble(),
      totalSlots: (json['total_slots'] as num).toInt(),
      payoutTotal: (json['payout_total'] as num).toDouble(),
      frequency: json['frequency'] as String,
      assignmentMethod: json['assignment_method'] as String,
      status: json['status'] as String,
      gracePeriodDays: (json['grace_period_days'] as num?)?.toInt() ?? 2,
      lateFeePerDay: (json['late_fee_per_day'] as num?)?.toDouble() ?? 0.0,
      inviteCode: json['invite_code'] as String,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      createdAt: DateTime.parse(json['created_at']),
      organizerName: (json['organizer'] as Map<String, dynamic>?)?['full_name'] as String?,
      numbersDrawnAt: json['numbers_drawn_at'] != null ? DateTime.parse(json['numbers_drawn_at']) : null,
      currentRoundNumber: (json['current_round_number'] as num?)?.toInt(),
      mySlotNumbers: (json['my_slot_numbers'] as List<dynamic>? ?? [])
          .map((n) => (n as num).toInt())
          .toList(),
      myNextPayoutDate: json['my_next_payout_date'] != null
          ? DateTime.parse(json['my_next_payout_date'])
          : null,
    );
  }
}
