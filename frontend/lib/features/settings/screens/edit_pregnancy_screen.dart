import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/core/widgets/animated_background.dart';
import 'package:sahhty/features/auth/providers/auth_provider.dart';
import 'package:sahhty/data/providers/service_providers.dart';

class EditPregnancyScreen extends ConsumerStatefulWidget {
  const EditPregnancyScreen({super.key});

  @override
  ConsumerState<EditPregnancyScreen> createState() => _EditPregnancyScreenState();
}

class _EditPregnancyScreenState extends ConsumerState<EditPregnancyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _testDateCtrl = TextEditingController();
  final _startDateCtrl = TextEditingController();
  final _dueDateCtrl = TextEditingController();
  final _endDateCtrl = TextEditingController();

  bool _testResult = true;
  DateTime? _testDate;
  DateTime? _startDate;
  DateTime? _dueDate;
  DateTime? _endDate;

  bool _loading = true;
  bool _saving = false;
  String? _error;
  int? _pregnancyId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _testDateCtrl.dispose();
    _startDateCtrl.dispose();
    _dueDateCtrl.dispose();
    _endDateCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    final patientId = int.tryParse(ref.read(authProvider).patientId ?? '');
    if (patientId == null) {
      setState(() { _loading = false; _error = 'ID patient non trouvé'; });
      return;
    }

    final result = await ref.read(pregnancyServiceProvider).getCurrentPregnancy(patientId);
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (result['success'] == true && result['pregnancy'] != null) {
        final p = result['pregnancy'];
        _pregnancyId = p['id'];
        _testResult = p['test_result'] ?? true;

        if (p['test_date'] != null) {
          _testDate = DateTime.tryParse(p['test_date'].toString());
          _testDateCtrl.text = p['test_date'].toString();
        }
        if (p['start_date'] != null) {
          _startDate = DateTime.tryParse(p['start_date'].toString());
          _startDateCtrl.text = p['start_date'].toString();
        }
        if (p['due_date'] != null) {
          _dueDate = DateTime.tryParse(p['due_date'].toString());
          _dueDateCtrl.text = p['due_date'].toString();
        }
        if (p['end_date'] != null) {
          _endDate = DateTime.tryParse(p['end_date'].toString());
          _endDateCtrl.text = p['end_date'].toString();
        }
      } else {
        _error = result['message'] ?? 'Aucune grossesse trouvée';
      }
    });
  }

  Future<void> _pickDate({
    required TextEditingController ctrl,
    required DateTime? current,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.info, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        ctrl.text = _formatDate(picked);
        onPicked(picked);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pregnancyId == null) return;

    setState(() => _saving = true);

    final data = <String, dynamic>{
      'test_result': _testResult,
    };
    if (_testDateCtrl.text.trim().isNotEmpty) data['test_date'] = _testDateCtrl.text.trim();
    if (_startDateCtrl.text.trim().isNotEmpty) data['start_date'] = _startDateCtrl.text.trim();
    if (_dueDateCtrl.text.trim().isNotEmpty) data['due_date'] = _dueDateCtrl.text.trim();
    if (_endDateCtrl.text.trim().isNotEmpty) data['end_date'] = _endDateCtrl.text.trim();

    final result = await ref.read(pregnancyServiceProvider).updatePregnancy(_pregnancyId!, data);
    if (!mounted) return;
    setState(() => _saving = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Grossesse mise à jour !'),
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
        title: const Text('Modifier la grossesse', style: TextStyle(fontWeight: FontWeight.bold)),
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
              ? const Center(child: CircularProgressIndicator(color: AppColors.info))
              : _error != null
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 8),
                      Text(_error!, style: const TextStyle(color: AppColors.error), textAlign: TextAlign.center),
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
                                  decoration: BoxDecoration(color: AppColors.info.withAlpha(15), shape: BoxShape.circle),
                                  child: const Text('🤰', style: TextStyle(fontSize: 40)),
                                ),
                              ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8), duration: 400.ms, curve: Curves.elasticOut),
                              const SizedBox(height: 24),
                              const Center(child: Text('Données de grossesse', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))).animate().fadeIn(delay: 100.ms),
                              const SizedBox(height: 8),
                              const Center(child: Text('Modifiez les dates et résultats', style: TextStyle(color: AppColors.textSecondary, fontSize: 14))).animate().fadeIn(delay: 150.ms),
                              const SizedBox(height: 32),

                              // Test result toggle
                              _buildLabel('Résultat du test'),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.textLight.withAlpha(50)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(children: [
                                      Icon(_testResult ? Icons.check_circle : Icons.cancel,
                                          color: _testResult ? AppColors.success : AppColors.error),
                                      const SizedBox(width: 12),
                                      Text(_testResult ? 'Positif' : 'Négatif',
                                          style: const TextStyle(fontWeight: FontWeight.w500)),
                                    ]),
                                    Switch(
                                      value: _testResult,
                                      activeTrackColor: AppColors.success.withAlpha(100),
                                      thumbColor: WidgetStateProperty.resolveWith((states) {
                                        if (states.contains(WidgetState.selected)) return AppColors.success;
                                        return AppColors.textLight;
                                      }),
                                      onChanged: (v) => setState(() => _testResult = v),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05),
                              const SizedBox(height: 20),

                              // Test date
                              _buildLabel('Date du test'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _testDateCtrl,
                                readOnly: true,
                                onTap: () => _pickDate(
                                  ctrl: _testDateCtrl,
                                  current: _testDate,
                                  onPicked: (d) => _testDate = d,
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                                decoration: const InputDecoration(
                                  hintText: 'AAAA-MM-JJ',
                                  prefixIcon: Icon(Icons.science_outlined, color: AppColors.info),
                                  suffixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.textLight),
                                ),
                              ).animate().fadeIn(delay: 250.ms).slideX(begin: 0.05),
                              const SizedBox(height: 20),

                              // Start date
                              _buildLabel('Date de début de grossesse'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _startDateCtrl,
                                readOnly: true,
                                onTap: () => _pickDate(
                                  ctrl: _startDateCtrl,
                                  current: _startDate,
                                  onPicked: (d) => _startDate = d,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'AAAA-MM-JJ (optionnel)',
                                  prefixIcon: Icon(Icons.event, color: AppColors.info),
                                  suffixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.textLight),
                                ),
                              ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.05),
                              const SizedBox(height: 20),

                              // Due date
                              _buildLabel('Date prévue d\'accouchement'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _dueDateCtrl,
                                readOnly: true,
                                onTap: () => _pickDate(
                                  ctrl: _dueDateCtrl,
                                  current: _dueDate,
                                  onPicked: (d) => _dueDate = d,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'AAAA-MM-JJ (optionnel)',
                                  prefixIcon: Icon(Icons.child_care, color: AppColors.info),
                                  suffixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.textLight),
                                ),
                              ).animate().fadeIn(delay: 350.ms).slideX(begin: 0.05),
                              const SizedBox(height: 20),

                              // End date
                              _buildLabel('Date de fin'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _endDateCtrl,
                                readOnly: true,
                                onTap: () => _pickDate(
                                  ctrl: _endDateCtrl,
                                  current: _endDate,
                                  onPicked: (d) => _endDate = d,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'AAAA-MM-JJ (optionnel)',
                                  prefixIcon: Icon(Icons.event_available, color: AppColors.info),
                                  suffixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.textLight),
                                ),
                              ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.05),
                              const SizedBox(height: 40),

                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _saving ? null : _save,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.info,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: _saving
                                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [Icon(Icons.save_outlined, color: Colors.white), SizedBox(width: 8), Text('Enregistrer', style: TextStyle(color: Colors.white))],
                                        ),
                                ),
                              ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1),
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
