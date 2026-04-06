/// All API endpoints matching the Django REST backend exactly.
class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'http://192.168.100.10:8000';

  // ── Auth (ViewSet: users/auth/) ──────────────────────────────────────
  static const String signup            = '/users/auth/signup/';
  static const String signin            = '/users/auth/signin/';
  static const String refreshToken      = '/users/refresh/';
  static const String verifyCode        = '/users/auth/verify_code/';
  static const String resendCode        = '/users/auth/resend_code/';
  static const String verifyResetEmail  = '/users/auth/verify_reset_email/';
  static const String verifyResetCode   = '/users/auth/verify_reset_code/';
  static const String forgetPassword    = '/users/auth/forget_password/';
  static const String isEmailAvailable  = '/users/auth/is_email_available/';
  static const String verifyPhone       = '/users/auth/verify_phone/';

  // ── FCM Device (ViewSet: users/devices/) ──────────────────────────────
  static const String registerDevice    = '/users/devices/register_device/';

  // ── Patient (ViewSet: patients/PatientService/) ──────────────────────
  static const String createPatient     = '/patients/PatientService/create_patient/';
  static String getPatientById(int pk)  => '/patients/PatientService/$pk/get_patient_by_id/';
  static String updatePatient(int pk)   => '/patients/PatientService/$pk/update_patient/';

  // ── Doctor (ViewSet: doctors/DoctorService/) ─────────────────────────
  static const String createDoctor      = '/doctors/DoctorService/create_doctor/';
  static String getDoctorById(int pk)   => '/doctors/DoctorService/$pk/get_doctor_by_id/';
  static String updateDoctor(int pk)    => '/doctors/DoctorService/$pk/update_doctor/';
  static const String getAllDoctors     = '/doctors/DoctorService/get_all_doctors/';

  // ── Pregnancy (ViewSet: pregnancies/PregnancyService/) ───────────────
  static const String createPregnancy           = '/pregnancies/PregnancyService/create_pregnancy/';
  static String getCurrentPregnancy(int pk)     => '/pregnancies/PregnancyService/$pk/get_current_pregnancy/';
  static String updatePregnancy(int pk)         => '/pregnancies/PregnancyService/$pk/update_pregnancy/';
  static String deletePregnancy(int pk)         => '/pregnancies/PregnancyService/$pk/delete_pregnancy/';

  // ── Measurement (ViewSet: measurements/MeasurementService/) ──────────
  static const String createMeasurement             = '/measurements/MeasurementService/create_measurement/';
  static String getLatestMeasurements(int pk)       => '/measurements/MeasurementService/$pk/get_latest_measurements/';
  static String getPatientMeasurements(int pk)      => '/measurements/MeasurementService/$pk/get_patient_measurements/';
  static String getRiskAssessment(int pk)           => '/measurements/MeasurementService/$pk/get_risk_assessment/';

  // ── Alert (ViewSet: alerts/AlertService/) ────────────────────────────
  static String getAlertsByUser(int userId) => '/alerts/AlertService/$userId/get_alerts_by_user/';
  static String markAlertAsRead(int alertId) => '/alerts/AlertService/$alertId/mark_as_read/';
}

/// Secure storage keys
class StorageKeys {
  StorageKeys._();
  static const String accessToken  = 'sahhty_access_token';
  static const String refreshToken = 'sahhty_refresh_token';
  static const String userEmail    = 'sahhty_user_email';
  static const String userName     = 'sahhty_user_name';
  static const String userRole     = 'sahhty_user_role';
  static const String userId       = 'sahhty_user_id';
  static const String patientId    = 'sahhty_patient_id';
  static const String doctorId     = 'sahhty_doctor_id';
  static const String userGender   = 'sahhty_user_gender';
}
