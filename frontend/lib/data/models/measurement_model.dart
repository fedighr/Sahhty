import 'package:equatable/equatable.dart';

class Measurement extends Equatable {
  final int? id;
  final String type; // WEIGHT, BLOOD_PRESSURE, GLYCEMIA, TEMPERATURE, HEART_RATE, OXYGEN
  final String? measurementDate;
  final double value1;
  final double? value2;
  final String unit;
  final String? context;
  final int? patientId;

  const Measurement({
    this.id,
    required this.type,
    this.measurementDate,
    required this.value1,
    this.value2,
    required this.unit,
    this.context,
    this.patientId,
  });

  String get displayValue {
    if (type == 'BLOOD_PRESSURE' && value2 != null) {
      return '${value1.toInt()}/${value2!.toInt()}';
    }
    if (type == 'WEIGHT') return value1.toStringAsFixed(1);
    if (type == 'TEMPERATURE') return value1.toStringAsFixed(1);
    return value1.toInt().toString();
  }

  String get displayUnit {
    switch (unit) {
      case 'KG': return 'kg';
      case 'MMHG': return 'mmHg';
      case 'G_L': return 'g/L';
      case 'C': return '°C';
      case 'BPM': return 'bpm';
      default: return unit;
    }
  }

  String get typeLabel {
    switch (type) {
      case 'WEIGHT': return 'Poids';
      case 'BLOOD_PRESSURE': return 'Tension artérielle';
      case 'GLYCEMIA': return 'Glycémie';
      case 'TEMPERATURE': return 'Température';
      case 'HEART_RATE': return 'Fréquence cardiaque';
      case 'OXYGEN': return 'Saturation O₂';
      default: return type;
    }
  }

  bool get isAbnormal {
    switch (type) {
      case 'BLOOD_PRESSURE':
        return value1 > 140 || (value2 != null && value2! > 90) || value1 < 90;
      case 'GLYCEMIA':
        return value1 > 140 || value1 < 60;
      case 'HEART_RATE':
        return value1 > 100 || value1 < 50;
      case 'TEMPERATURE':
        return value1 > 38 || value1 < 36;
      case 'OXYGEN':
        return value1 < 95;
      default:
        return false;
    }
  }

  factory Measurement.fromJson(Map<String, dynamic> json) => Measurement(
        id: json['id'] as int?,
        type: json['type'] as String? ?? '',
        measurementDate: json['measurement_date'] as String?,
        value1: _parseDouble(json['value1']),
        value2: json['value2'] != null ? _parseDouble(json['value2']) : null,
        unit: json['unit'] as String? ?? '',
        context: json['context'] as String?,
        patientId: json['patient_id'] as int? ?? (json['patient'] is Map ? json['patient']['id'] as int? : json['patient'] as int?),
      );

  static double _parseDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'value1': value1,
        if (value2 != null) 'value2': value2,
        'unit': unit,
        if (context != null && context!.isNotEmpty) 'context': context,
        if (patientId != null) 'patient_id': patientId,
      };

  @override
  List<Object?> get props => [id, type, value1, value2, unit, measurementDate];
}

class RiskAssessment extends Equatable {
  final int? id;
  final String? assessedAt;
  final String globalRiskLevel; // LOW, MEDIUM, HIGH
  final double globalRiskPercentage; // May be 0 if backend doesn't provide it
  final String? personalRiskLevel;
  final String? personalRiskNote;
  final double? glucoseUsed;
  final double? bpSysUsed;
  final double? bpDiaUsed;
  final double? heartRateUsed;
  final double? weightUsed;
  final double? bodyTempUsed;
  final int? patientId;

  const RiskAssessment({
    this.id,
    this.assessedAt,
    required this.globalRiskLevel,
    this.globalRiskPercentage = 0.0,
    this.personalRiskLevel,
    this.personalRiskNote,
    this.glucoseUsed,
    this.bpSysUsed,
    this.bpDiaUsed,
    this.heartRateUsed,
    this.weightUsed,
    this.bodyTempUsed,
    this.patientId,
  });

  bool get isHighRisk => globalRiskLevel == 'HIGH';
  bool get isMediumRisk => globalRiskLevel == 'MEDIUM';

  factory RiskAssessment.fromJson(Map<String, dynamic> json) => RiskAssessment(
        id: json['id'] as int?,
        assessedAt: json['assessed_at'] as String?,
        globalRiskLevel: json['global_risk_level'] as String? ?? 'LOW',
        globalRiskPercentage: json['global_risk_percentage'] != null
            ? Measurement._parseDouble(json['global_risk_percentage'])
            : 0.0,
        personalRiskLevel: json['personal_risk_level'] as String?,
        personalRiskNote: json['personal_risk_note'] as String?,
        glucoseUsed: json['glucose_used'] != null ? Measurement._parseDouble(json['glucose_used']) : null,
        bpSysUsed: json['bp_sys_used'] != null ? Measurement._parseDouble(json['bp_sys_used']) : null,
        bpDiaUsed: json['bp_dia_used'] != null ? Measurement._parseDouble(json['bp_dia_used']) : null,
        heartRateUsed: json['heart_rate_used'] != null ? Measurement._parseDouble(json['heart_rate_used']) : null,
        weightUsed: json['weight_used'] != null ? Measurement._parseDouble(json['weight_used']) : null,
        bodyTempUsed: json['body_temp_used'] != null ? Measurement._parseDouble(json['body_temp_used']) : null,
        patientId: json['patient_id'] as int? ?? (json['patient'] is Map ? json['patient']['id'] as int? : json['patient'] as int?),
      );

  @override
  List<Object?> get props => [id, globalRiskLevel, globalRiskPercentage, assessedAt];
}
