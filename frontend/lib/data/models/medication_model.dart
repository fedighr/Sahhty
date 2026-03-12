import 'package:equatable/equatable.dart';

class Medication extends Equatable {
  final int? id;
  final String name;
  final String? description;

  const Medication({this.id, required this.name, this.description});

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
        id: json['id'] as int?,
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description != null) 'description': description,
      };

  @override
  List<Object?> get props => [id, name];
}

class Treatment extends Equatable {
  final int? id;
  final String startDate;
  final String? endDate;
  final String dose;
  final String frequency;
  final int? patientId;
  final Medication? medication;
  final int? medicationId;

  const Treatment({
    this.id,
    required this.startDate,
    this.endDate,
    required this.dose,
    required this.frequency,
    this.patientId,
    this.medication,
    this.medicationId,
  });

  bool get isActive {
    final now = DateTime.now();
    final start = DateTime.tryParse(startDate);
    final end = endDate != null ? DateTime.tryParse(endDate!) : null;
    if (start == null) return false;
    if (start.isAfter(now)) return false;
    if (end != null && end.isBefore(now)) return false;
    return true;
  }

  factory Treatment.fromJson(Map<String, dynamic> json) => Treatment(
        id: json['id'] as int?,
        startDate: json['start_date'] as String? ?? '',
        endDate: json['end_date'] as String?,
        dose: json['dose'] as String? ?? json['dosage'] as String? ?? '',
        frequency: json['frequency'] as String? ?? '',
        patientId: json['patient_id'] as int? ??
            (json['patient'] is Map ? json['patient']['id'] as int? : json['patient'] as int?),
        medication: json['medication'] != null
            ? Medication.fromJson(json['medication'] as Map<String, dynamic>)
            : null,
        medicationId: json['medication_id'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        'dose': dose,
        'frequency': frequency,
        if (patientId != null) 'patient_id': patientId,
        if (medicationId != null) 'medication_id': medicationId,
      };

  @override
  List<Object?> get props => [id, startDate, dose, frequency, medicationId];
}

class TreatmentSchedule extends Equatable {
  final int? id;
  final String doseTime;
  final String? lastSentAt;
  final int? treatmentId;

  const TreatmentSchedule({this.id, required this.doseTime, this.lastSentAt, this.treatmentId});

  factory TreatmentSchedule.fromJson(Map<String, dynamic> json) =>
      TreatmentSchedule(
        id: json['id'] as int?,
        doseTime: json['dose_time'] as String? ?? '',
        lastSentAt: json['last_sent_at'] as String?,
        treatmentId: json['treatment_id'] as int?,
      );

  @override
  List<Object?> get props => [id, doseTime, treatmentId];
}
