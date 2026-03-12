import 'package:equatable/equatable.dart';

class Appointment extends Equatable {
  final int? id;
  final String appointmentDate;
  final String status; // PENDING, CONFIRMED, CANCELLED, COMPLETED
  final String reason;
  final String? createdAt;
  final String? updatedAt;
  final int? patientId;
  final int? doctorId;
  final String? doctorName;
  final String? doctorSpeciality;

  const Appointment({
    this.id,
    required this.appointmentDate,
    required this.status,
    required this.reason,
    this.createdAt,
    this.updatedAt,
    this.patientId,
    this.doctorId,
    this.doctorName,
    this.doctorSpeciality,
  });

  bool get isPending => status == 'PENDING';
  bool get isConfirmed => status == 'CONFIRMED';
  bool get isCancelled => status == 'CANCELLED';
  bool get isCompleted => status == 'COMPLETED';
  bool get isUpcoming {
    final date = DateTime.tryParse(appointmentDate);
    return date != null && date.isAfter(DateTime.now()) && !isCancelled;
  }

  String get statusLabel {
    switch (status) {
      case 'PENDING': return 'En attente';
      case 'CONFIRMED': return 'Confirmé';
      case 'CANCELLED': return 'Annulé';
      case 'COMPLETED': return 'Terminé';
      default: return status;
    }
  }

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final doctor = json['doctor'] as Map<String, dynamic>?;
    final doctorUser = doctor?['user'] as Map<String, dynamic>?;
    final doctorSpec = doctor?['speciality'] as Map<String, dynamic>?;

    return Appointment(
      id: json['id'] as int?,
      appointmentDate: json['appointment_date'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      reason: json['reason'] as String? ?? '',
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      patientId: json['patient_id'] as int? ??
          (json['patient'] is Map ? json['patient']['id'] as int? : json['patient'] as int?),
      doctorId: json['doctor_id'] as int? ??
          (doctor != null ? doctor['id'] as int? : null),
      doctorName: doctorUser != null
          ? '${doctorUser['first_name'] ?? ''} ${doctorUser['last_name'] ?? ''}'.trim()
          : null,
      doctorSpeciality: doctorSpec?['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'appointment_date': appointmentDate,
        'status': status,
        'reason': reason,
        if (patientId != null) 'patient_id': patientId,
        if (doctorId != null) 'doctor_id': doctorId,
      };

  Appointment copyWith({String? status, String? appointmentDate, String? reason}) =>
      Appointment(
        id: id,
        appointmentDate: appointmentDate ?? this.appointmentDate,
        status: status ?? this.status,
        reason: reason ?? this.reason,
        createdAt: createdAt,
        updatedAt: updatedAt,
        patientId: patientId,
        doctorId: doctorId,
        doctorName: doctorName,
        doctorSpeciality: doctorSpeciality,
      );

  @override
  List<Object?> get props => [id, appointmentDate, status, reason, doctorId];
}
