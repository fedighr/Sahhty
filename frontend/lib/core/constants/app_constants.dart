// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Sahhty';
  static const String appVersion = '1.0.0';

  // Base URL — change to your Django backend
  static const String baseUrl = 'http://10.0.2.2:8000';

  // ── Auth Endpoints ────────────────────────────────────────────────────────
  static const String signupEndpoint        = '/users/auth/signup/';
  static const String signinEndpoint        = '/users/auth/signin/';
  static const String refreshEndpoint       = '/users/refresh/';
  static const String verifyCodeEndpoint    = '/users/auth/verify_code/';
  static const String resendCodeEndpoint    = '/users/auth/resend_code/';
  static const String verifyResetEmail      = '/users/auth/verify_reset_email/';
  static const String verifyResetCode       = '/users/auth/verify_reset_code/';
  static const String forgetPassword        = '/users/auth/forget_password/';
  static const String isEmailAvailable      = '/users/auth/is_email_available/';
  static const String verifyPhone           = '/users/auth/verify_phone/';
  static const String registerFCMDevice     = '/users/devices/register_device/';

  // ── Profile Setup Endpoints ───────────────────────────────────────────────
  static const String createPatientEndpoint = '/patients/PatientService/create_patient/';
  static const String createDoctorEndpoint  = '/doctors/DoctorService/create_doctor/';

  // ── Patient Endpoints ───────────────────────────────────────────────────────
  static const String patientProfile        = '/patients/me/';
  static const String patientUpdate         = '/patients/me/';
  static const String legacyPatientProfile  = '/patients/PatientService/me/';
  static const String legacyPatientUpdate   = '/patients/PatientService/update/';

  // ── Pregnancy Endpoints ─────────────────────────────────────────────────────
  static const String pregnancies           = '/pregnancies/';
  static const String legacyPregnancyBase  = '/pregnancies/PregnancyService';

  // ── Measurement Endpoints ─────────────────────────────────────────────────
  static const String createMeasurement     = '/measurements/MeasurementService/create_measurement/';
  static const String measurementsList      = '/measurements/list/';
  static const String legacyMeasurementsByPatient = '/measurements/MeasurementService';
  static const String riskAssessments       = '/risk_assessments/';
  static const String legacyRiskAssessmentsByPatient = '/measurements/MeasurementService';

  // ── Appointment Endpoints (backend TBD – mock for now) ────────────────────
  static const String appointments          = '/appointments/';
  static const String appointmentsUpcoming  = '/appointments/upcoming/';

  // ── Medication Endpoints (backend TBD – mock for now) ─────────────────────
  static const String treatments            = '/medications/treatments/';
  static const String medications           = '/medications/';

  // ── Medical Files Endpoints (backend TBD – mock for now) ──────────────────
  static const String attachments           = '/medical_files/';

  // ── Alert Endpoints ───────────────────────────────────────────────────────
  static const String alertsList            = '/alerts/list/';
  static const String alertsBase            = '/alerts';
  static const String alertMarkRead         = '/alerts';
  static const String legacyAlertsBase      = '/alerts/AlertService';

  // ── Doctor Endpoints ──────────────────────────────────────────────────────
  static const String doctorsList           = '/doctors/list/';
  static const String legacyDoctorsList     = '/doctors/DoctorService/get_all_doctors/';

  // ── Secure Storage Keys ───────────────────────────────────────────────────
  static const String userNameKey     = 'sahhty_user_name';
  static const String userGenderKey   = 'sahhty_user_gender';
  static const String accessTokenKey  = 'sahhty_access_token';
  static const String refreshTokenKey = 'sahhty_refresh_token';
  static const String userDataKey     = 'sahhty_user_data';
  static const String userEmailKey    = 'sahhty_user_email';
  static const String userRoleKey     = 'sahhty_user_role';

  // ── Timeouts ──────────────────────────────────────────────────────────────
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout    = 30000;

  // ── Validation ────────────────────────────────────────────────────────────
  static const int passwordMinLength = 8;

  // ── HTTP Headers ──────────────────────────────────────────────────────────
  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix        = 'Bearer ';
  static const String contentTypeHeader   = 'Content-Type';
  static const String applicationJson     = 'application/json';

  // ── User Roles (backend uses single char) ─────────────────────────────────
  static const String rolePatient = 'P';
  static const String roleDoctor  = 'D';

  // ── Gender (backend uses single char) ────────────────────────────────────
  static const String genderMale   = 'M';
  static const String genderFemale = 'F';
}
