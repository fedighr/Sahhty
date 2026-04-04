import 'package:equatable/equatable.dart';

class Alert extends Equatable {
  final int? id;
  final String type;     // HEALTH, REMINDER, DOCTOR_MESSAGE, SYSTEM
  final String message;
  final String level;    // INFO, WARNING, CRITICAL
  final String status;   // NEW, READ, RESOLVED
  final String? createdAt;
  final int? userId;

  const Alert({
    this.id,
    required this.type,
    required this.message,
    required this.level,
    required this.status,
    this.createdAt,
    this.userId,
  });

  bool get isNew => status == 'NEW';
  bool get isCritical => level == 'CRITICAL';
  bool get isWarning => level == 'WARNING';

  String get typeLabel {
    switch (type) {
      case 'HEALTH': return 'Santé';
      case 'REMINDER': return 'Rappel';
      case 'DOCTOR_MESSAGE': return 'Message du médecin';
      case 'SYSTEM': return 'Système';
      default: return type;
    }
  }

  String get levelLabel {
    switch (level) {
      case 'INFO': return 'Information';
      case 'WARNING': return 'Avertissement';
      case 'CRITICAL': return 'Critique';
      default: return level;
    }
  }

  factory Alert.fromJson(Map<String, dynamic> json) => Alert(
        id: json['id'] as int?,
        type: json['type'] as String? ?? 'SYSTEM',
        message: json['message'] as String? ?? '',
        level: json['level'] as String? ?? 'INFO',
        // Backend serializer uses 'Status' (capital S)
        status: json['Status'] as String? ?? json['status'] as String? ?? 'NEW',
        createdAt: json['created_at'] as String?,
        userId: json['user_id'] as int? ?? (json['user'] is Map ? json['user']['id'] as int? : json['user'] as int?),
      );

  Alert copyWith({String? status}) => Alert(
        id: id,
        type: type,
        message: message,
        level: level,
        status: status ?? this.status,
        createdAt: createdAt,
        userId: userId,
      );

  @override
  List<Object?> get props => [id, type, message, level, status];
}
