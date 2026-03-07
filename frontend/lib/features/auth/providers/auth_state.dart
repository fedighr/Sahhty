// lib/features/auth/providers/auth_state.dart
import 'package:equatable/equatable.dart';
import '../../../data/models/auth_model.dart';

sealed class AuthState extends Equatable {
  const AuthState();
  bool get isInitial       => this is AuthInitial;
  bool get isLoading       => this is AuthLoading;
  bool get isAuthenticated => this is AuthAuthenticated;
  bool get isError         => this is AuthError;
  @override
  List<Object?> get props => [];
}

class AuthInitial          extends AuthState { const AuthInitial(); }
class AuthLoading          extends AuthState { const AuthLoading(); }
class AuthUnauthenticated  extends AuthState { const AuthUnauthenticated(); }
class AuthPasswordReset    extends AuthState { const AuthPasswordReset(); }

class AuthAuthenticated extends AuthState {
  final AuthTokens tokens;
  final String role; // 'P' | 'D'
  const AuthAuthenticated({required this.tokens, this.role = 'P'});
  bool get isDoctor  => role == 'D';
  bool get isPatient => role == 'P';
  @override List<Object?> get props => [tokens, role];
}

class AuthError extends AuthState {
  final String message;
  final int? statusCode;
  const AuthError({required this.message, this.statusCode});
  @override List<Object?> get props => [message, statusCode];
}

class AuthAwaitingVerification extends AuthState {
  final String email;
  const AuthAwaitingVerification({required this.email});
  @override List<Object?> get props => [email];
}

class AuthVerified extends AuthState {
  final String email;
  final String role;
  const AuthVerified({required this.email, this.role = 'P'});
  @override List<Object?> get props => [email, role];
}

class AuthAwaitingResetCode extends AuthState {
  final String email;
  const AuthAwaitingResetCode({required this.email});
  @override List<Object?> get props => [email];
}

class AuthCanResetPassword extends AuthState {
  final String email;
  const AuthCanResetPassword({required this.email});
  @override List<Object?> get props => [email];
}
