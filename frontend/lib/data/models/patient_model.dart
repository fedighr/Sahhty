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

  // Extra user fields returned by backend getPatientById
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? birthDate;
  final int? age;
  final String? phone;
  final String? gender;

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
    this.firstName,
    this.lastName,
    this.email,
    this.birthDate,
    this.age,
    this.phone,
    this.gender,
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
        height: _parseInt(json['height']),
        weight: _parseDouble(json['weight']),
        bloodType: json['blood_type'] as String?,
        chronicDiseases: json['chronic_diseases'] as String?,
        allergies: json['allergies'] as String?,
        currentMedications: json['current_medications'] as String?,
        familyDoctorName: json['family_doctor_name'] as String?,
        userId: json['user'] as int?,
        menstrualCycle: json['menstrual_cycle'] != null && json['menstrual_cycle'] is Map
            ? MenstrualCycle.fromJson(json['menstrual_cycle'])
            : null,
        firstName: json['first_name'] as String?,
        lastName: json['last_name'] as String?,
        email: json['email'] as String?,
        birthDate: json['birth_date']?.toString(),
        age: json['age'] as int?,
        phone: json['phone'] as String?,
        gender: json['gender'] as String?,
      );

  static int _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

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
    String? firstName,
    String? lastName,
    String? email,
    String? birthDate,
    int? age,
    String? phone,
    String? gender,
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
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        email: email ?? this.email,
        birthDate: birthDate ?? this.birthDate,
        age: age ?? this.age,
        phone: phone ?? this.phone,
        gender: gender ?? this.gender,
      );

  @override
  List<Object?> get props => [id, height, weight, bloodType, userId];
}
