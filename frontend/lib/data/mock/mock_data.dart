import '../models/patient_model.dart';
import '../models/pregnancy_model.dart';
import '../models/measurement_model.dart';
import '../models/appointment_model.dart';
import '../models/medication_model.dart';
import '../models/alert_model.dart';
import '../models/attachment_model.dart';

/// Données mock utilisées quand le backend ne fournit pas encore les endpoints GET.
/// À remplacer progressivement par des appels API réels.
class MockData {
  MockData._();

  static Patient get patient => const Patient(
        id: 1,
        height: 165,
        weight: 68.5,
        bloodType: 'A+',
        chronicDiseases: null,
        allergies: 'Pénicilline',
        currentMedications: 'Acide folique',
        familyDoctorName: 'Dr Ben Salem',
        userId: 1,
        menstrualCycle: MenstrualCycle(
          id: 1,
          menstrualStatus: 'ACTIVE',
          startDate: '2025-12-01',
          endDate: '2025-12-06',
        ),
      );

  static Pregnancy get activePregnancy => Pregnancy(
        id: 1,
        testDate: '2025-11-15',
        testResult: true,
        startDate: '2025-11-01',
        dueDate: '2026-08-08',
        endDate: null,
        patientId: 1,
      );

  static List<Measurement> get recentMeasurements => [
        Measurement(
          id: 1,
          type: 'BLOOD_PRESSURE',
          measurementDate: DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
          value1: 118,
          value2: 75,
          unit: 'MMHG',
          patientId: 1,
        ),
        Measurement(
          id: 2,
          type: 'WEIGHT',
          measurementDate: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          value1: 69.2,
          unit: 'KG',
          patientId: 1,
        ),
        Measurement(
          id: 3,
          type: 'GLYCEMIA',
          measurementDate: DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          value1: 92,
          unit: 'G_L',
          patientId: 1,
        ),
        Measurement(
          id: 4,
          type: 'HEART_RATE',
          measurementDate: DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
          value1: 78,
          unit: 'BPM',
          patientId: 1,
        ),
        Measurement(
          id: 5,
          type: 'TEMPERATURE',
          measurementDate: DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
          value1: 36.8,
          unit: 'C',
          patientId: 1,
        ),
      ];

  static List<Appointment> get appointments => [
        Appointment(
          id: 1,
          appointmentDate: DateTime.now().add(const Duration(days: 3, hours: 10)).toIso8601String(),
          status: 'CONFIRMED',
          reason: 'Consultation prénatale - 2ème trimestre',
          doctorName: 'Dr. Amira Trabelsi',
          doctorSpeciality: 'Gynécologie-Obstétrique',
          patientId: 1,
          doctorId: 1,
        ),
        Appointment(
          id: 2,
          appointmentDate: DateTime.now().add(const Duration(days: 14, hours: 9)).toIso8601String(),
          status: 'PENDING',
          reason: 'Échographie morphologique',
          doctorName: 'Dr. Karim Mansour',
          doctorSpeciality: 'Radiologie',
          patientId: 1,
          doctorId: 2,
        ),
        Appointment(
          id: 3,
          appointmentDate: DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
          status: 'COMPLETED',
          reason: 'Bilan sanguin trimestriel',
          doctorName: 'Dr. Amira Trabelsi',
          doctorSpeciality: 'Gynécologie-Obstétrique',
          patientId: 1,
          doctorId: 1,
        ),
      ];

  static List<Treatment> get treatments => [
        Treatment(
          id: 1,
          startDate: '2025-11-15',
          endDate: '2026-08-08',
          dose: '400 µg',
          frequency: '1 fois par jour',
          patientId: 1,
          medication: const Medication(id: 1, name: 'Acide folique', description: 'Prévention des anomalies du tube neural'),
        ),
        Treatment(
          id: 2,
          startDate: '2026-01-01',
          endDate: '2026-08-08',
          dose: '200 mg',
          frequency: '1 fois par jour',
          patientId: 1,
          medication: const Medication(id: 2, name: 'Fer', description: 'Prévention de l\'anémie'),
        ),
      ];

  static List<Alert> get alerts => [
        Alert(
          id: 1,
          type: 'REMINDER',
          message: 'Votre prochain rendez-vous est dans 3 jours avec Dr. Amira Trabelsi.',
          level: 'INFO',
          status: 'NEW',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        ),
        Alert(
          id: 2,
          type: 'SYSTEM',
          message: 'N\'oubliez pas de prendre vos mesures de tension artérielle cette semaine.',
          level: 'WARNING',
          status: 'NEW',
          createdAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        ),
      ];

  static List<Attachment> get attachments => [
        Attachment(
          id: 1,
          type: 'ULTRASOUND',
          fileUrl: null,
          uploadDate: DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          patientId: 1,
        ),
        Attachment(
          id: 2,
          type: 'REPORT',
          fileUrl: null,
          uploadDate: DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
          patientId: 1,
        ),
      ];

  static RiskAssessment get latestRisk => const RiskAssessment(
        id: 1,
        globalRiskLevel: 'LOW',
        personalRiskLevel: 'LOW',
        personalRiskNote: 'All values within normal range',
        glucoseUsed: 92,
        bpSysUsed: 118,
        bpDiaUsed: 75,
        heartRateUsed: 78,
        weightUsed: 69.2,
        patientId: 1,
      );
}
