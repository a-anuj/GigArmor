// HustleHalt — Activity State
//
// Provides:
//   - ActivityModel           — single activity log entry
//   - ActivitySummaryModel    — aggregated weekly summary for a worker
//   - weeklyActivityProvider  — FutureProvider.family for dashboard card
//   - logSessionProvider      — FutureProvider.family to POST a session

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class ActivitySummaryModel {
  final int workerId;
  final int totalOrders;
  final double totalHours;
  final int sessionCount;
  final int activeDays;
  final String activityLevel; // HIGH | MEDIUM | LOW | NONE
  final String claimContextNote;
  final String weekStart;

  ActivitySummaryModel({
    required this.workerId,
    required this.totalOrders,
    required this.totalHours,
    required this.sessionCount,
    required this.activeDays,
    required this.activityLevel,
    required this.claimContextNote,
    required this.weekStart,
  });

  factory ActivitySummaryModel.fromJson(Map<String, dynamic> json) {
    return ActivitySummaryModel(
      workerId:         (json['worker_id'] as num).toInt(),
      totalOrders:      (json['total_orders'] as num).toInt(),
      totalHours:       (json['total_hours'] as num).toDouble(),
      sessionCount:     (json['session_count'] as num).toInt(),
      activeDays:       (json['active_days'] as num).toInt(),
      activityLevel:    json['activity_level'] as String? ?? 'NONE',
      claimContextNote: json['claim_context_note'] as String? ?? '',
      weekStart:        json['week_start'] as String? ?? '',
    );
  }
}

class LogSessionRequest {
  final int workerId;
  final String activityType;
  final int ordersCount;
  final double sessionHours;
  final int? zoneId;
  final String? notes;

  const LogSessionRequest({
    required this.workerId,
    this.activityType = 'delivery_session',
    required this.ordersCount,
    required this.sessionHours,
    this.zoneId,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'worker_id':     workerId,
    'activity_type': activityType,
    'orders_count':  ordersCount,
    'session_hours': sessionHours,
    if (zoneId != null) 'zone_id': zoneId,
    if (notes != null) 'notes': notes,
  };
}

// ── Providers ─────────────────────────────────────────────────────────────────

/// Fetches the aggregated weekly activity summary for a given worker.
final weeklyActivityProvider = FutureProvider.family<ActivitySummaryModel, int>(
  (ref, workerId) async {
    final response = await ApiClient.instance.get(
      '/api/v1/activity/$workerId/summary',
    );
    return ActivitySummaryModel.fromJson(response.data as Map<String, dynamic>);
  },
);

/// Posts a new delivery session log entry.
/// Usage: ref.read(logSessionProvider(request).future)
final logSessionProvider = FutureProvider.family<Map<String, dynamic>, LogSessionRequest>(
  (ref, request) async {
    final response = await ApiClient.instance.post(
      '/api/v1/activity/log',
      data: request.toJson(),
    );
    return response.data as Map<String, dynamic>;
  },
);
