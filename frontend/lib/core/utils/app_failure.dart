// lib/core/utils/app_failure.dart

abstract class AppFailure implements Exception {
  final String message;
  final int? statusCode;
  const AppFailure({required this.message, this.statusCode});
  @override String toString() => 'AppFailure($message)';
}

class NetworkFailure extends AppFailure {
  const NetworkFailure() : super(message: 'Connexion Internet indisponible. Vérifiez votre réseau.');
}

class AuthFailure extends AppFailure {
  const AuthFailure({required super.message, super.statusCode});
}

class ValidationFailure extends AppFailure {
  const ValidationFailure({required super.message, super.statusCode});
}

class ServerFailure extends AppFailure {
  const ServerFailure({required super.message, super.statusCode});
}

class StorageFailure extends AppFailure {
  const StorageFailure({super.message = 'Erreur de stockage local.'});
}

class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure() : super(message: 'Erreur inattendue. Veuillez réessayer.');
}
