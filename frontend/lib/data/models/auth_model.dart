// lib/data/models/auth_model.dart

import 'package:equatable/equatable.dart';

// ─── Sign In ──────────────────────────────────────────────────────────────────

class SignInRequest extends Equatable {
  final String email;
  final String password;

  const SignInRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
    'email': email.trim().toLowerCase(),
    'password': password,
  };

  @override
  List<Object?> get props => [email, password];
}

// ─── Sign Up ──────────────────────────────────────────────────────────────────

class SignUpRequest extends Equatable {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String password;
  final String birthDate;
  final String gender;
  final String role;

  const SignUpRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.password,
    required this.birthDate,
    required this.gender,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
    'first_name': firstName.trim(),
    'last_name': lastName.trim(),
    'email': email.trim().toLowerCase(),
    'phone': phone.trim(),
    'password': password,
    'birth_date': birthDate,
    'gender': gender,
    'role': role,
  };

  @override
  List<Object?> get props => [firstName, lastName, email, phone,
      password, birthDate, gender, role];
}

// ─── OTP ──────────────────────────────────────────────────────────────────────

class VerifyCodeRequest extends Equatable {
  final String email;
  final String code;
  const VerifyCodeRequest({required this.email, required this.code});
  Map<String, dynamic> toJson() => {'email': email, 'code': code};
  @override
  List<Object?> get props => [email, code];
}

class EmailRequest extends Equatable {
  final String email;
  const EmailRequest({required this.email});
  Map<String, dynamic> toJson() => {'email': email.trim().toLowerCase()};
  @override
  List<Object?> get props => [email];
}

class ForgotPasswordRequest extends Equatable {
  final String email;
  final String password;
  const ForgotPasswordRequest({required this.email, required this.password});
  Map<String, dynamic> toJson() => {
    'email': email.trim().toLowerCase(),
    'password': password,
  };
  @override
  List<Object?> get props => [email, password];
}

// ─── Patient Setup ────────────────────────────────────────────────────────────

class MenstrualCycleData extends Equatable {
  final String menstrualStatus;
  final String? startDate;
  final String? endDate;

  const MenstrualCycleData({
    required this.menstrualStatus,
    this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toJson() => {
    'menstrual_status': menstrualStatus,
    if (startDate != null) 'start_date': startDate,
    if (endDate != null) 'end_date': endDate,
  };

  @override
  List<Object?> get props => [menstrualStatus, startDate, endDate];
}

class CreatePatientRequest extends Equatable {
  final String email;
  final int height;
  final double weight;
  final String? bloodType;
  final String? chronicDiseases;
  final String? allergies;
  final String? currentMedications;
  final String? familyDoctorName;
  final MenstrualCycleData? menstrualCycle;

  const CreatePatientRequest({
    required this.email,
    required this.height,
    required this.weight,
    this.bloodType,
    this.chronicDiseases,
    this.allergies,
    this.currentMedications,
    this.familyDoctorName,
    this.menstrualCycle,
  });

  Map<String, dynamic> toJson() => {
    'email': email.trim().toLowerCase(),
    'height': height,
    'weight': weight,
    if (bloodType != null && bloodType!.isNotEmpty) 'blood_type': bloodType,
    if (chronicDiseases != null && chronicDiseases!.isNotEmpty)
      'chronic_diseases': chronicDiseases,
    if (allergies != null && allergies!.isNotEmpty) 'allergies': allergies,
    if (currentMedications != null && currentMedications!.isNotEmpty)
      'current_medications': currentMedications,
    if (familyDoctorName != null && familyDoctorName!.isNotEmpty)
      'family_doctor_name': familyDoctorName,
    if (menstrualCycle != null) 'menstrual_cycle': menstrualCycle!.toJson(),
  };

  @override
  List<Object?> get props => [email, height, weight, bloodType];
}

// ─── Doctor Setup ─────────────────────────────────────────────────────────────

class CreateDoctorRequest extends Equatable {
  final int userId;
  final int specialityId;
  final String ville;
  final String address;
  final int experience;
  final double? consultationPrice;
  final String? bio;

  const CreateDoctorRequest({
    required this.userId,
    required this.specialityId,
    required this.ville,
    required this.address,
    required this.experience,
    this.consultationPrice,
    this.bio,
  });

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'speciality_id': specialityId,
    'ville': ville,
    'address': address,
    'experience': experience,
    if (consultationPrice != null) 'consultation_price': consultationPrice,
    if (bio != null && bio!.isNotEmpty) 'bio': bio,
  };

  @override
  List<Object?> get props => [userId, specialityId, ville, address, experience];
}

// ─── Tokens ───────────────────────────────────────────────────────────────────

class AuthTokens extends Equatable {
  final String accessToken;
  final String refreshToken;

  const AuthTokens({required this.accessToken, required this.refreshToken});

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return AuthTokens(
      accessToken: data['access'] as String,
      refreshToken: data['refresh'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'access': accessToken,
    'refresh': refreshToken,
  };

  AuthTokens copyWith({String? accessToken, String? refreshToken}) =>
      AuthTokens(
        accessToken: accessToken ?? this.accessToken,
        refreshToken: refreshToken ?? this.refreshToken,
      );

  @override
  List<Object?> get props => [accessToken, refreshToken];
}
