import 'package:equatable/equatable.dart';

class Doctor extends Equatable {
  final int? id;
  final String ville;
  final String address;
  final int experience;
  final double? consultationPrice;
  final String? bio;
  final bool isAvailable;
  final String? firstName;
  final String? lastName;
  final String? specialityName;
  final int? specialityId;

  const Doctor({
    this.id,
    required this.ville,
    required this.address,
    required this.experience,
    this.consultationPrice,
    this.bio,
    this.isAvailable = true,
    this.firstName,
    this.lastName,
    this.specialityName,
    this.specialityId,
  });

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  factory Doctor.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final spec = json['speciality'] as Map<String, dynamic>?;
    return Doctor(
      id: json['id'] as int?,
      ville: json['ville'] as String? ?? '',
      address: json['address'] as String? ?? '',
      experience: json['experience'] as int? ?? 0,
      consultationPrice: json['consultation_price'] != null
          ? (json['consultation_price'] is String
              ? double.tryParse(json['consultation_price'])
              : (json['consultation_price'] as num?)?.toDouble())
          : null,
      bio: json['bio'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      firstName: user?['first_name'] as String?,
      lastName: user?['last_name'] as String?,
      specialityName: spec?['name'] as String?,
      specialityId: spec?['id'] as int? ?? json['speciality_id'] as int?,
    );
  }

  @override
  List<Object?> get props => [id, ville, experience, specialityName];
}
