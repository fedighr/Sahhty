// lib/core/utils/app_failure.dart

import 'package:equatable/equatable.dart';

/// Sealed class hierarchy for all possible failures in the app.
/// This ensures proper error mapping from API → domain layer.
abstract class AppFailure extends Equatable {
  final String message;
  final int? statusCode;

  const AppFailure({
    required this.message,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, statusCode];
}

/// Network / connectivity issues
class NetworkFailure extends AppFailure {
  const NetworkFailure({
    super.message = 'Connexion Internet indisponible. Vérifiez votre réseau.',
    super.statusCode,
  });
}

/// Server returned a known error (4xx / 5xx)
class ServerFailure extends AppFailure {
  const ServerFailure({
    required super.message,
    super.statusCode,
  });
}

/// Authentication-specific errors (401, 403)
class AuthFailure extends AppFailure {
  const AuthFailure({
    required super.message,
    super.statusCode,
  });
}

/// Validation errors from backend
class ValidationFailure extends AppFailure {
  final Map<String, List<String>>? fieldErrors;

  const ValidationFailure({
    required super.message,
    this.fieldErrors,
    super.statusCode,
  });

  @override
  List<Object?> get props => [message, statusCode, fieldErrors];
}

/// Unexpected / unknown errors
class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure({
    super.message = 'Une erreur inattendue est survenue. Réessayez plus tard.',
    super.statusCode,
  });
}

/// Token storage failures
class StorageFailure extends AppFailure {
  const StorageFailure({
    super.message = 'Erreur de stockage sécurisé.',
    super.statusCode,
  });
}
