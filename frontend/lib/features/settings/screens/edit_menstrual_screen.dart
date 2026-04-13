import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/core/widgets/animated_background.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';
import 'package:sahhty/data/providers/service_providers.dart';

class EditMenstrualScreen extends ConsumerStatefulWidget {
  const EditMenstrualScreen({super.key});

  @override
  ConsumerState<EditMenstrualScreen> createState() => _EditMenstrualScreenState();
}

class _EditMenstrualScreenState extends ConsumerState<EditMenstrualScreen> {
  final _formKey = GlobalKey<FormState>();
  final _startDateCtrl = TextEditingController();
  final _endDateCtrl = TextEditingController();

  String _selectedStatus = 'ACTIVE';
  DateTime? _startDate;
  DateTime? _endDate;

  bool _loading = true;
  bool _saving = false;
  String? _error;

  static const _statusOptions = [
    {'value': 'ACTIVE', 'label': 'Actif'},
    {'value': 'MENOPAUSE', 'label': 'Ménopause'},
    {'value': 'PREPUBESCENT', 'label': 'Prépubère'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    final patientId = int.tryParse(ref.read(authProvider).patientId ?? '');
    if (patientId == null) {
      setState(() { _loading = false; _error = 'ID patient non trouvé'; });
      return;
    }

    final result = await ref.read(patientServiceProvider).getPatientById(patientId);
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (result['success'] == true) {
        final mc = result['patient']?['menstrual_cycle'];
        if (mc != null) {
          _selectedStatus = mc['menstrual_status'] ?? 'ACTIVE';
          if (mc['start_date'] != null) {
            _startDate = DateTime.tryParse(mc['start_date'].toString());
            _startDateCtrl.text = mc['start_date'].toString();
          }
          if (mc['end_date'] != null) {
            _endDate = DateTime.tryParse(mc['end_date'].toString());
            _endDateCtrl.text = mc['end_date'].toString();
          }
        }
      } else {
        _error = result['message'] ?? 'Erreur';
      }
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.secondary, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final formatted = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart) {
          _startDate = picked;
          _startDateCtrl.text = formatted;
        } else {
          _endDate = picked;
          _endDateCtrl.text = formatted;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final patientId = int.tryParse(ref.read(authProvider).patientId ?? '');
    if (patientId == null) return;

    setState(() => _saving = true);

    final menstrualData = <String, dynamic>{
      'menstrual_status': _selectedStatus,
    };
    if (_startDateCtrl.text.trim().isNotEmpty) {
      menstrualData['start_date'] = _startDateCtrl.text.trim();
    }
    if (_endDateCtrl.text.trim().isNotEmpty) {
      menstrualData['end_date'] = _endDateCtrl.text.trim();
    }

    final result = await ref.read(patientServiceProvider).updatePatient(
      patientId,
      {'menstrual_cycle': menstrualData},
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Cycle menstruel mis à jour !'),
          ]),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Erreur'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Cycle menstruel', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withAlpha(200), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.arrow_back_ios_new, size: 18),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          const AnimatedBackground(showImage: false),
          _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
              : _error != null
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 8),
                      Text(_error!, style: const TextStyle(color: AppColors.error)),
                      TextButton(onPressed: _loadData, child: const Text('Réessayer')),
                    ]))
                  : SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(color: AppColors.secondary.withAlpha(15), shape: BoxShape.circle),
                                  child: const Icon(Icons.calendar_month_outlined, color: AppColors.secondary, size: 48),
                                ),
                              ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8), duration: 400.ms, curve: Curves.elasticOut),
                              const SizedBox(height: 24),
                              const Center(child: Text('Cycle menstruel', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))).animate().fadeIn(delay: 100.ms),
                              const SizedBox(height: 8),
                              const Center(child: Text('Modifiez les informations de votre cycle', style: TextStyle(color: AppColors.textSecondary, fontSize: 14))).animate().fadeIn(delay: 150.ms),
                              const SizedBox(height: 32),

                              _buildLabel('Statut menstruel'),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _selectedStatus,
                                items: _statusOptions.map((opt) => DropdownMenuItem(
                                  value: opt['value'],
                                  child: Text(opt['label']!),
                                )).toList(),
                                onChanged: (v) { if (v != null) setState(() => _selectedStatus = v); },
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.cyclone, color: AppColors.secondary),
                                ),
                              ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05),
                              const SizedBox(height: 20),

                              _buildLabel('Date de début'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _startDateCtrl,
                                readOnly: true,
                                onTap: () => _pickDate(isStart: true),
                                decoration: const InputDecoration(
                                  hintText: 'AAAA-MM-JJ',
                                  prefixIcon: Icon(Icons.event, color: AppColors.secondary),
                                  suffixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.textLight),
                                ),
                              ).animate().fadeIn(delay: 250.ms).slideX(begin: 0.05),
                              const SizedBox(height: 20),

                              _buildLabel('Date de fin'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _endDateCtrl,
                                readOnly: true,
                                onTap: () => _pickDate(isStart: false),
                                decoration: const InputDecoration(
                                  hintText: 'AAAA-MM-JJ',
                                  prefixIcon: Icon(Icons.event_available, color: AppColors.secondary),
                                  suffixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.textLight),
                                ),
                              ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.05),
                              const SizedBox(height: 40),

                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _saving ? null : _save,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.secondary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: _saving
                                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [Icon(Icons.save_outlined, color: Colors.white), SizedBox(width: 8), Text('Enregistrer', style: TextStyle(color: Colors.white))],
                                        ),
                                ),
                              ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary));
  }
}
