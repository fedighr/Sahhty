import 'package:equatable/equatable.dart';

class Attachment extends Equatable {
  final int? id;
  final String type; // REPORT, ULTRASOUND
  final String? fileUrl;
  final String? uploadDate;
  final int? patientId;

  const Attachment({
    this.id,
    required this.type,
    this.fileUrl,
    this.uploadDate,
    this.patientId,
  });

  String get typeLabel {
    switch (type) {
      case 'REPORT': return 'Rapport';
      case 'ULTRASOUND': return 'Échographie';
      default: return type;
    }
  }

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
        id: json['id'] as int?,
        type: json['type'] as String? ?? 'REPORT',
        fileUrl: json['file'] as String?,
        uploadDate: json['upload_date'] as String?,
        patientId: json['patient_id'] as int? ??
            (json['patient'] is Map ? json['patient']['id'] as int? : json['patient'] as int?),
      );

  @override
  List<Object?> get props => [id, type, fileUrl, uploadDate];
}
