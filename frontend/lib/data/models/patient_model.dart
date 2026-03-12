import 'package:equatable/equatable.dart';

class MenstrualCycle extends Equatable {
  final int? id;
  final String menstrualStatus; // ACTIVE, MENOPAUSE, PREPUBESCENT
  final String? startDate;
  final String? endDate;

  const MenstrualCycle({
    this.id,
    required this.menstrualStatus,
    this.startDate,
    this.endDate,
  });

  factory MenstrualCycle.fromJson(Map<String, dynamic> json) => MenstrualCycle(
        id: json['id'] as int?,
        menstrualStatus: json['menstrual_status'] as String? ?? 'ACTIVE',
        startDate: json['start_date'] as String?,
        endDate: json['end_date'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'menstrual_status': menstrualStatus,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      };

  @override
  List<Object?> get props => [id, menstrualStatus, startDate, endDate];
}

class Patient extends Equatable {
  final int? id;
  final int height;
  final double weight;
  final String? bloodType;
  final String? chronicDiseases;
  final String? allergies;
  final String? currentMedications;
  final String? familyDoctorName;
  final int? userId;
  final MenstrualCycle? menstrualCycle;

  const Patient({
    this.id,
    required this.height,
    required this.weight,
    this.bloodType,
    this.chronicDiseases,
    this.allergies,
    this.currentMedications,
    this.familyDoctorName,
    this.userId,
    this.menstrualCycle,
  });

  double get bmi => weight / ((height / 100) * (height / 100));
  String get bmiCategory {
    final b = bmi;
    if (b < 18.5) return 'Insuffisance pondérale';
    if (b < 25) return 'Normal';
    if (b < 30) return 'Surpoids';
    return 'Obésité';
  }

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
        id: json['id'] as int?,
        height: json['height'] as int? ?? 0,
        weight: (json['weight'] is String
                ? double.tryParse(json['weight'])
                : (json['weight'] as num?)?.toDouble()) ??
            0.0,
        bloodType: json['blood_type'] as String?,
        chronicDiseases: json['chronic_diseases'] as String?,
        allergies: json['allergies'] as String?,
        currentMedications: json['current_medications'] as String?,
        familyDoctorName: json['family_doctor_name'] as String?,
        userId: json['user'] as int?,
        menstrualCycle: json['menstrual_cycle'] != null
            ? MenstrualCycle.fromJson(json['menstrual_cycle'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'height': height,
        'weight': weight,
        if (bloodType != null) 'blood_type': bloodType,
        if (chronicDiseases != null) 'chronic_diseases': chronicDiseases,
        if (allergies != null) 'allergies': allergies,
        if (currentMedications != null) 'current_medications': currentMedications,
        if (familyDoctorName != null) 'family_doctor_name': familyDoctorName,
        if (menstrualCycle != null) 'menstrual_cycle': menstrualCycle!.toJson(),
      };

  Patient copyWith({
    int? id,
    int? height,
    double? weight,
    String? bloodType,
    String? chronicDiseases,
    String? allergies,
    String? currentMedications,
    String? familyDoctorName,
    int? userId,
    MenstrualCycle? menstrualCycle,
  }) =>
      Patient(
        id: id ?? this.id,
        height: height ?? this.height,
        weight: weight ?? this.weight,
        bloodType: bloodType ?? this.bloodType,
        chronicDiseases: chronicDiseases ?? this.chronicDiseases,
        allergies: allergies ?? this.allergies,
        currentMedications: currentMedications ?? this.currentMedications,
        familyDoctorName: familyDoctorName ?? this.familyDoctorName,
        userId: userId ?? this.userId,
        menstrualCycle: menstrualCycle ?? this.menstrualCycle,
      );

  @override
  List<Object?> get props => [id, height, weight, bloodType, userId];
}
