// lib/data/models/auth_model.dart

import 'package:equatable/equatable.dart';

// ─── Request Models ──────────────────────────────────────────────────────────

class SignInRequest extends Equatable {
  final String email;
  final String password;

  const SignInRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'email': email.trim().toLowerCase(),
        'password': password,
      };

  @override
  List<Object?> get props => [email, password];
}

class SignUpRequest extends Equatable {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String password;
  final String confirmPassword;
  final String birthDate; // ISO format: YYYY-MM-DD
  final String gender;    // 'male' | 'female'
  final String role;      // 'patient' | 'doctor'

  const SignUpRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.password,
    required this.confirmPassword,
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
        'confirm_password': confirmPassword,
        'birth_date': birthDate,
        'gender': gender,
        'role': role,
      };

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        email,
        phone,
        password,
        confirmPassword,
        birthDate,
        gender,
        role,
      ];
}

// ─── Response Models ─────────────────────────────────────────────────────────

class AuthTokens extends Equatable {
  final String accessToken;
  final String refreshToken;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });

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

  AuthTokens copyWith({
    String? accessToken,
    String? refreshToken,
  }) {
    return AuthTokens(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }

  @override
  List<Object?> get props => [accessToken, refreshToken];
}

// ─── API Response Wrapper ─────────────────────────────────────────────────────

class ApiResponse<T> extends Equatable {
  final bool success;
  final T? data;
  final String? message;
  final int? status;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.status,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? fromJsonT,
  ) {
    final dataField = json['data'] as Map<String, dynamic>?;
    final success = dataField?['success'] as bool? ?? false;
    final message = dataField?['message'] as String?;
    final status = json['status'] as int?;

    T? data;
    if (success && fromJsonT != null && dataField != null) {
      data = fromJsonT(json);
    }

    return ApiResponse(
      success: success,
      data: data,
      message: message,
      status: status,
    );
  }

  @override
  List<Object?> get props => [success, data, message, status];
}
