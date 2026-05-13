import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // Primary — soft rose/pink for pregnancy theme
  static const Color primary       = Color(0xFFE8878F);
  static const Color primaryLight  = Color(0xFFFCE4EC);
  static const Color primaryDark   = Color(0xFFC75B6A);

  // Secondary — warm peach
  static const Color secondary     = Color(0xFFF8BBD0);
  static const Color secondaryDark = Color(0xFFEF9A9A);

  // Accent — soft teal for contrast
  static const Color accent        = Color(0xFF80CBC4);
  static const Color accentDark    = Color(0xFF4DB6AC);

  // Backgrounds
  static const Color background    = Color(0xFFFFF5F5);
  static const Color surface       = Colors.white;
  static const Color card          = Colors.white;

  // Text
  static const Color textPrimary   = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF424242);
  static const Color textLight     = Color(0xFFBDBDBD);

  // Status
  static const Color success       = Color(0xFF66BB6A);
  static const Color warning       = Color(0xFFE65100);
  static const Color error         = Color(0xFFEF5350);
  static const Color info          = Color(0xFF42A5F5);

  // Risk
  static const Color riskLow       = Color(0xFF66BB6A);
  static const Color riskMedium    = Color(0xFFE65100);
  static const Color riskHigh      = Color(0xFFEF5350);

  // Drug interaction severity
  static const Color interactionContraindication = Color(0xFFD32F2F); // CONTRE_INDICATION
  static const Color interactionDiscouraged      = Color(0xFFE65100); // DECONSEILLEE
  static const Color interactionPrecaution       = Color(0xFFE65100); // PRECAUTION_EMPLOI
  static const Color interactionConsideration    = Color(0xFF1976D2); // A_PRENDRE_EN_COMPTE
  static const Color interactionNone             = Color(0xFF9E9E9E); // NON_SIGNIFICATIVE
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.poppinsTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 14),
        labelStyle: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
