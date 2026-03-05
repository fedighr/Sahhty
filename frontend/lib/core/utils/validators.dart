// lib/core/utils/validators.dart

import '../constants/app_constants.dart';

class Validators {
  Validators._();

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'L\'email est requis';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Format email invalide';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }
    if (value.length < AppConstants.passwordMinLength) {
      return 'Minimum ${AppConstants.passwordMinLength} caractères requis';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Doit contenir au moins une majuscule';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Doit contenir au moins une minuscule';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Doit contenir au moins un chiffre';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]').hasMatch(value)) {
      return 'Doit contenir au moins un caractère spécial';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'La confirmation est requise';
    }
    if (value != password) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le numéro de téléphone est requis';
    }
    // Strip spaces, dashes, dots — keep digits and leading +
    final cleaned = value.trim().replaceAll(RegExp(r'[\s\-\.]'), '');

    // Accept:
    //   22345678          → 8 digits starting with 2,4,5,7,9
    //   +21622345678      → +216 followed by 8 digits
    //   21622345678       → 216 followed by 8 digits
    final eightDigits = RegExp(r'^[2457-9][0-9]{7}$');
    final withCountryCode = RegExp(r'^(\+?216)[2457-9][0-9]{7}$');

    if (!eightDigits.hasMatch(cleaned) && !withCountryCode.hasMatch(cleaned)) {
      return 'Numéro tunisien invalide (ex: 22 345 678)';
    }
    return null;
  }

  static String? validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le prénom est requis';
    }
    if (value.trim().length < 2) {
      return 'Le prénom doit contenir au moins 2 caractères';
    }
    if (value.trim().length > 50) {
      return 'Le prénom est trop long';
    }
    return null;
  }

  static String? validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le nom est requis';
    }
    if (value.trim().length < 2) {
      return 'Le nom doit contenir au moins 2 caractères';
    }
    if (value.trim().length > 50) {
      return 'Le nom est trop long';
    }
    return null;
  }

  static String? validateBirthDate(DateTime? value) {
    if (value == null) {
      return 'La date de naissance est requise';
    }
    final now = DateTime.now();
    final age = now.year -
        value.year -
        ((now.month < value.month ||
                (now.month == value.month && now.day < value.day))
            ? 1
            : 0);
    if (age < 1) {
      return 'Date de naissance invalide';
    }
    if (age > 120) {
      return 'Date de naissance invalide';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName est requis';
    }
    return null;
  }
}
