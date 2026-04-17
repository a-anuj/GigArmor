/// Full domain model for Claims, matching the backend ClaimOut schema.
library;

class ClaimModel {
  final int id;
  final int policyId;
  final int triggerEventId;
  final double payoutAmount;
  final double payoutPercentage; // 25 | 50 | 75 | 100
  final double trustScore;
  final String status; // Auto-Approved | Soft-Hold | Blocked | Under-Appeal
  final DateTime createdAt;
  final DateTime? appealDeadline;

  // Enriched fields from joins
  final String? eventType;
  final String? eventSeverity;
  final String? zoneName;
  final bool upiWebhookFired;

  const ClaimModel({
    required this.id,
    required this.policyId,
    required this.triggerEventId,
    required this.payoutAmount,
    required this.payoutPercentage,
    required this.trustScore,
    required this.status,
    required this.createdAt,
    this.appealDeadline,
    this.eventType,
    this.eventSeverity,
    this.zoneName,
    this.upiWebhookFired = false,
  });

  bool get isAutoApproved => status == 'Auto-Approved';
  bool get isBlocked => status == 'Blocked';
  bool get isSoftHold => status == 'Soft-Hold';
  bool get isUnderAppeal => status == 'Under-Appeal';

  /// Returns true if the 72-hour appeal window is still open.
  bool get canAppeal {
    if (!isBlocked) return false;
    if (appealDeadline == null) return true; // no deadline = still open
    return DateTime.now().isBefore(appealDeadline!);
  }

  factory ClaimModel.fromJson(Map<String, dynamic> j) {
    return ClaimModel(
      id: (j['id'] as num).toInt(),
      policyId: (j['policy_id'] as num).toInt(),
      triggerEventId: (j['trigger_event_id'] as num).toInt(),
      payoutAmount: (j['payout_amount'] as num).toDouble(),
      payoutPercentage: (j['payout_percentage'] as num?)?.toDouble() ?? 100.0,
      trustScore: (j['trust_score'] as num?)?.toDouble() ?? 0.0,
      status: j['status'] as String,
      createdAt: DateTime.parse(j['created_at'] as String),
      appealDeadline: j['appeal_deadline'] != null
          ? DateTime.parse(j['appeal_deadline'] as String)
          : null,
      eventType: j['event_type'] as String?,
      eventSeverity: j['event_severity'] as String?,
      zoneName: j['zone_name'] as String?,
      upiWebhookFired: j['upi_webhook_fired'] as bool? ?? false,
    );
  }
}

class ClaimsResult {
  final int workerId;
  final String workerName;
  final int totalClaims;
  final double totalPayout;
  final List<ClaimModel> claims;

  const ClaimsResult({
    required this.workerId,
    required this.workerName,
    required this.totalClaims,
    required this.totalPayout,
    required this.claims,
  });

  factory ClaimsResult.fromJson(Map<String, dynamic> j) {
    final list = (j['claims'] as List).map((c) => ClaimModel.fromJson(c as Map<String, dynamic>)).toList();
    return ClaimsResult(
      workerId: (j['worker_id'] as num).toInt(),
      workerName: j['worker_name'] as String? ?? '',
      totalClaims: (j['total_claims'] as num).toInt(),
      totalPayout: (j['total_payout'] as num).toDouble(),
      claims: list,
    );
  }
}
