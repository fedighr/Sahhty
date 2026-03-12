import 'package:equatable/equatable.dart';

class Pregnancy extends Equatable {
  final int? id;
  final String testDate;
  final bool testResult;
  final String? startDate;
  final String? dueDate;
  final String? endDate;
  final int? patientId;

  const Pregnancy({
    this.id,
    required this.testDate,
    required this.testResult,
    this.startDate,
    this.dueDate,
    this.endDate,
    this.patientId,
  });

  bool get isActive => testResult && endDate == null;

  int? get currentWeek {
    if (startDate == null) return null;
    final start = DateTime.tryParse(startDate!);
    if (start == null) return null;
    return DateTime.now().difference(start).inDays ~/ 7;
  }

  int? get daysRemaining {
    if (dueDate == null) return null;
    final due = DateTime.tryParse(dueDate!);
    if (due == null) return null;
    final remaining = due.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  int get trimester {
    final week = currentWeek ?? 0;
    if (week <= 12) return 1;
    if (week <= 27) return 2;
    return 3;
  }

  String get babySize {
    final week = currentWeek ?? 0;
    const sizes = {
      4: '🫐 Graine de pavot',
      5: '🫐 Graine de sésame',
      6: '🫐 Lentille',
      7: '🫐 Myrtille',
      8: '🫒 Framboise',
      9: '🫒 Olive',
      10: '🍇 Prune',
      11: '🍋 Citron vert',
      12: '🍋 Citron',
      13: '🍑 Pêche',
      14: '🍑 Nectarine',
      15: '🍎 Pomme',
      16: '🥑 Avocat',
      17: '🥕 Navet',
      18: '🫑 Poivron',
      19: '🥭 Mangue',
      20: '🍌 Banane',
      21: '🥕 Carotte',
      22: '🌽 Épi de maïs',
      23: '🍆 Aubergine',
      24: '🥒 Concombre',
      25: '🥦 Chou-fleur',
      26: '🥬 Laitue',
      27: '🥥 Noix de coco',
      28: '🍍 Ananas',
      29: '🎃 Courge butternut',
      30: '🥬 Chou',
      31: '🥬 Chou frisé',
      32: '🍈 Melon',
      33: '🍈 Cantaloup',
      34: '🍈 Honeydew',
      35: '🍈 Melon miel',
      36: '🥬 Romaine',
      37: '🎃 Courge',
      38: '🍉 Mini pastèque',
      39: '🍉 Pastèque',
      40: '🎃 Citrouille',
    };
    if (week < 4) return '🌱 Tout petit';
    return sizes[week] ?? '🎃 Citrouille';
  }

  factory Pregnancy.fromJson(Map<String, dynamic> json) => Pregnancy(
        id: json['id'] as int?,
        testDate: json['test_date'] as String? ?? '',
        testResult: json['test_result'] as bool? ?? false,
        startDate: json['start_date'] as String?,
        dueDate: json['due_date'] as String?,
        endDate: json['end_date'] as String?,
        patientId: json['patient'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'test_date': testDate,
        'test_result': testResult,
        if (startDate != null) 'start_date': startDate,
        if (dueDate != null) 'due_date': dueDate,
        if (endDate != null) 'end_date': endDate,
        if (patientId != null) 'patient': patientId,
      };

  Pregnancy copyWith({
    int? id,
    String? testDate,
    bool? testResult,
    String? startDate,
    String? dueDate,
    String? endDate,
    int? patientId,
  }) =>
      Pregnancy(
        id: id ?? this.id,
        testDate: testDate ?? this.testDate,
        testResult: testResult ?? this.testResult,
        startDate: startDate ?? this.startDate,
        dueDate: dueDate ?? this.dueDate,
        endDate: endDate ?? this.endDate,
        patientId: patientId ?? this.patientId,
      );

  @override
  List<Object?> get props => [id, testDate, testResult, startDate, dueDate, endDate, patientId];
}
