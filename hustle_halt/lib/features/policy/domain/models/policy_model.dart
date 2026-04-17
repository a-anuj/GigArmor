/// Full domain models for Policy and Premium Quote,
/// matching the backend schemas exactly.
library;

class PremiumQuoteModel {
  final int workerId;
  final String workerName;
  final int zoneId;
  final String zoneName;

  // Multipliers (for transparency screen)
  final double rBase;
  final double mWeather;
  final double mSocial;
  final double mColdstart;
  final double hExpected;
  final double baseRiskMultiplier;

  // Premiums
  final double rawPremium;
  final double premiumBeforeDiscount;
  final double premium; // final ₹19–₹99

  // Context
  final String weatherCondition;
  final String socialCondition;
  final bool coldStartActive;

  // Loyalty
  final int consecutiveQuietWeeks;
  final bool shieldCreditsApplied;
  final double discountAmount;
  final double coverageAmount;

  final String message;

  // Live weather
  final double liveRainfallMmHr;
  final double liveTemperatureC;
  final double liveHumidityPct;

  const PremiumQuoteModel({
    required this.workerId,
    required this.workerName,
    required this.zoneId,
    required this.zoneName,
    required this.rBase,
    required this.mWeather,
    required this.mSocial,
    required this.mColdstart,
    required this.hExpected,
    required this.baseRiskMultiplier,
    required this.rawPremium,
    required this.premiumBeforeDiscount,
    required this.premium,
    required this.weatherCondition,
    required this.socialCondition,
    required this.coldStartActive,
    required this.consecutiveQuietWeeks,
    required this.shieldCreditsApplied,
    required this.discountAmount,
    required this.coverageAmount,
    required this.message,
    this.liveRainfallMmHr = 0.0,
    this.liveTemperatureC = 0.0,
    this.liveHumidityPct = 0.0,
  });

  factory PremiumQuoteModel.fromJson(Map<String, dynamic> j) {
    return PremiumQuoteModel(
      workerId: (j['worker_id'] as num).toInt(),
      workerName: j['worker_name'] as String? ?? '',
      zoneId: (j['zone_id'] as num).toInt(),
      zoneName: j['zone_name'] as String? ?? '',
      rBase: (j['r_base'] as num?)?.toDouble() ?? 5.0,
      mWeather: (j['m_weather'] as num?)?.toDouble() ?? 1.0,
      mSocial: (j['m_social'] as num?)?.toDouble() ?? 1.0,
      mColdstart: (j['m_coldstart'] as num?)?.toDouble() ?? 1.0,
      hExpected: (j['h_expected'] as num?)?.toDouble() ?? 1.0,
      baseRiskMultiplier: (j['base_risk_multiplier'] as num?)?.toDouble() ?? 1.0,
      rawPremium: (j['raw_premium'] as num?)?.toDouble() ?? 0.0,
      premiumBeforeDiscount: (j['premium_before_discount'] as num?)?.toDouble() ?? 0.0,
      premium: (j['premium'] as num).toDouble(),
      weatherCondition: j['weather_condition'] as String? ?? 'Normal',
      socialCondition: j['social_condition'] as String? ?? 'Normal',
      coldStartActive: j['cold_start_active'] as bool? ?? false,
      consecutiveQuietWeeks: (j['consecutive_quiet_weeks'] as num?)?.toInt() ?? 0,
      shieldCreditsApplied: j['shield_credits_applied'] as bool? ?? false,
      discountAmount: (j['discount_amount'] as num?)?.toDouble() ?? 0.0,
      coverageAmount: (j['coverage_amount'] as num?)?.toDouble() ?? 1200.0,
      message: j['message'] as String? ?? '',
      liveRainfallMmHr: (j['live_rainfall_mm_hr'] as num?)?.toDouble() ?? 0.0,
      liveTemperatureC: (j['live_temperature_c'] as num?)?.toDouble() ?? 0.0,
      liveHumidityPct: (j['live_humidity_pct'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PolicyModel {
  final int id;
  final int workerId;
  final DateTime startDate;
  final DateTime endDate;
  final double premiumAmount;
  final double coverageAmount;
  final String status; // Active | Expired

  const PolicyModel({
    required this.id,
    required this.workerId,
    required this.startDate,
    required this.endDate,
    required this.premiumAmount,
    required this.coverageAmount,
    required this.status,
  });

  bool get isActive => status == 'Active';

  factory PolicyModel.fromJson(Map<String, dynamic> j) {
    return PolicyModel(
      id: (j['id'] as num).toInt(),
      workerId: (j['worker_id'] as num).toInt(),
      startDate: DateTime.parse(j['start_date'] as String),
      endDate: DateTime.parse(j['end_date'] as String),
      premiumAmount: (j['premium_amount'] as num).toDouble(),
      coverageAmount: (j['coverage_amount'] as num).toDouble(),
      status: j['status'] as String? ?? 'Active',
    );
  }
}

class EnrollResult {
  final PolicyModel policy;
  final PremiumQuoteModel quoteUsed;
  final String message;

  const EnrollResult({
    required this.policy,
    required this.quoteUsed,
    required this.message,
  });

  factory EnrollResult.fromJson(Map<String, dynamic> j) {
    return EnrollResult(
      policy: PolicyModel.fromJson(j['policy'] as Map<String, dynamic>),
      quoteUsed: PremiumQuoteModel.fromJson(j['quote_used'] as Map<String, dynamic>),
      message: j['message'] as String? ?? '',
    );
  }
}
