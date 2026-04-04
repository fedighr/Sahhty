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

  // ── Profile Setup Endpoints ───────────────────────────────────────────────
  static const String createPatientEndpoint = '/patients/PatientService/create_patient/';
  static const String createDoctorEndpoint  = '/doctors/DoctorService/create_doctor/';

  // ── Patient Endpoints ───────────────────────────────────────────────────
  // Backend uses: /patients/PatientService/{pk}/get_patient_by_id/
  //               /patients/PatientService/{pk}/update_patient/
  static const String patientById           = '/patients/PatientService/'; // append {pk}/get_patient_by_id/
  static const String patientUpdate         = '/patients/PatientService/'; // append {pk}/update_patient/

  // ── Pregnancy Endpoints ───────────────────────────────────────────────────
  // Backend uses: /pregnancies/PregnancyService/create_pregnancy/
  //               /pregnancies/PregnancyService/{pk}/get_current_pregnancy/
  static const String pregnancyCreate       = '/pregnancies/PregnancyService/create_pregnancy/';
  static const String pregnancyByPatient    = '/pregnancies/PregnancyService/'; // append {pk}/get_current_pregnancy/

  // ── Measurement Endpoints ─────────────────────────────────────────────────
  // Backend uses: /measurements/MeasurementService/create_measurement/
  //               /measurements/MeasurementService/{pk}/get_latest_measurements/
  //               /measurements/MeasurementService/{pk}/get_patient_measurements/
  //               /measurements/MeasurementService/{pk}/get_risk_assessment/
  static const String createMeasurement     = '/measurements/MeasurementService/create_measurement/';
  static const String measurementsByPatient = '/measurements/MeasurementService/'; // append {pk}/get_patient_measurements/
  static const String measurementsLatest    = '/measurements/MeasurementService/'; // append {pk}/get_latest_measurements/
  static const String riskAssessment        = '/measurements/MeasurementService/'; // append {pk}/get_risk_assessment/

  // ── Measurement List & Risk (used by measurement_service.dart) ──────────────
  static const String measurementsList      = '/measurements/MeasurementService/'; // needs patient pk
  static const String riskAssessments       = '/measurements/MeasurementService/'; // needs patient pk + get_risk_assessment/

  // ── Appointment Endpoints (backend urls.py is empty – endpoints not yet available) ─
  static const String appointments          = '/appointments/';
  static const String appointmentsUpcoming  = '/appointments/upcoming/';

  // ── Medication Endpoints (backend urls.py is empty – endpoints not yet available) ─
  static const String treatments            = '/medications/treatments/';
  static const String medications           = '/medications/';

  // ── Medical Files Endpoints (backend urls.py is empty – endpoints not yet available)
  static const String attachments           = '/medical_files/';

  // ── Alert Endpoints ───────────────────────────────────────────────────────
  // Backend uses: /alerts/AlertService/{pk}/get_alerts_by_user/
  //               /alerts/AlertService/{pk}/mark_as_read/
  static const String alertsList            = '/alerts/AlertService/'; // needs user pk + get_alerts_by_user/
  static const String alertsByUser          = '/alerts/AlertService/'; // append {pk}/get_alerts_by_user/
  static const String alertMarkRead         = '/alerts/AlertService/'; // append {pk}/mark_as_read/

  // ── Patient Profile (get by id) ────────────────────────────────────────────
  static const String patientProfile        = '/patients/PatientService/'; // append {pk}/get_patient_by_id/

  // ── Pregnancy list / active (aliases used by pregnancy_service.dart) ──────
  static const String pregnancies           = '/pregnancies/PregnancyService/create_pregnancy/';
  static const String activePregnancy       = '/pregnancies/PregnancyService/'; // append {pk}/get_current_pregnancy/

  // ── Doctor Endpoints ──────────────────────────────────────────────────────
  // Backend uses: /doctors/DoctorService/get_all_doctors/
  static const String doctorsList           = '/doctors/DoctorService/get_all_doctors/';

  // ── FCM Device Registration ───────────────────────────────────────────────
  // Backend uses: POST /users/devices/register_device/
  static const String registerDevice        = '/users/devices/register_device/';

  // ── Secure Storage Keys ───────────────────────────────────────────────────
  static const String userNameKey     = 'sahhty_user_name';
  static const String userGenderKey   = 'sahhty_user_gender';
  static const String accessTokenKey  = 'sahhty_access_token';
  static const String refreshTokenKey = 'sahhty_refresh_token';
  static const String userDataKey     = 'sahhty_user_data';
  static const String userEmailKey    = 'sahhty_user_email';
  static const String userRoleKey     = 'sahhty_user_role';
  static const String userIdKey       = 'sahhty_user_id';
  static const String patientIdKey    = 'sahhty_patient_id';

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
