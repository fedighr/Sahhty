// lib/features/auth/providers/auth_state.dart

import 'package:equatable/equatable.dart';
import '../../../data/models/auth_model.dart';

/// Immutable auth state — exhaustive pattern matching with sealed class style
sealed class AuthState extends Equatable {
  const AuthState();

  bool get isInitial => this is AuthInitial;
  bool get isLoading => this is AuthLoading;
  bool get isAuthenticated => this is AuthAuthenticated;
  bool get isError => this is AuthError;

  @override
  List<Object?> get props => [];
}

/// App just launched — checking stored tokens
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Auth operation in progress (login / register)
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// User successfully authenticated
class AuthAuthenticated extends AuthState {
  final AuthTokens tokens;

  const AuthAuthenticated({required this.tokens});

  @override
  List<Object?> get props => [tokens];
}

/// Auth operation failed
class AuthError extends AuthState {
  final String message;
  final int? statusCode;

  const AuthError({
    required this.message,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, statusCode];
}

/// User explicitly signed out
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}
