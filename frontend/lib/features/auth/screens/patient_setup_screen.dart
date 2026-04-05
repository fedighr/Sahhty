import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahhty/core/theme/app_theme.dart';
import 'package:sahhty/data/providers/service_providers.dart';

/// After signup + verify, the user needs to create their Patient profile.
/// Backend expects POST /patients/PatientService/create_patient/ with:
///   email, height, weight, blood_type (optional), chronic_diseases (optional),
///   allergies (optional), current_medications (optional), family_doctor_name (optional)
/// For females (gender == 'F'), also sends menstrual_cycle nested data:
///   { menstrual_status, start_date, end_date }
/// After patient creation, if pregnant, calls POST /pregnancies/PregnancyService/create_pregnancy/
///   { test_date, test_result, start_date?, due_date?, patient }
class PatientSetupScreen extends ConsumerStatefulWidget {
  final String email;
  final String gender;
  const PatientSetupScreen({super.key, required this.email, this.gender = 'F'});

  @override
  ConsumerState<PatientSetupScreen> createState() => _PatientSetupScreenState();
}

class _PatientSetupScreenState extends ConsumerState<PatientSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // ── Patient fields ───────────────────────────────────────────────────
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  String? _bloodType;
  final _chronicCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  final _medicationsCtrl = TextEditingController();
  final _doctorNameCtrl = TextEditingController();

  // ── Menstrual cycle fields (females only) ────────────────────────────
  String _menstrualStatus = 'ACTIVE';
  DateTime? _cycleStartDate;
  DateTime? _cycleEndDate;

  // ── Pregnancy fields (females only) ──────────────────────────────────
  bool _isPregnant = false;
  DateTime? _pregnancyTestDate;
  DateTime? _pregnancyStartDate;
  DateTime? _pregnancyDueDate;

  bool _isLoading = false;

  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<Map<String, String>> _menstrualStatuses = [
    {'value': 'ACTIVE', 'label': 'Actif'},
    {'value': 'MENOPAUSE', 'label': 'Ménopause'},
    {'value': 'PREPUBESCENT', 'label': 'Prépubère'},
  ];

  bool get _isFemale => widget.gender == 'F';

  int get _totalSteps {
    if (!_isFemale) return 1; // Just basic info
    if (_isPregnant) return 3; // Basic + Menstrual + Pregnancy
    return 2; // Basic + Menstrual
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _chronicCtrl.dispose();
    _allergiesCtrl.dispose();
    _medicationsCtrl.dispose();
    _doctorNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required DateTime? current,
    required ValueChanged<DateTime> onPicked,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => onPicked(picked));
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _formatDateApi(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // ── 1) Create Patient ────────────────────────────────────────────
    final data = <String, dynamic>{
      'email': widget.email,
      'height': int.parse(_heightCtrl.text.trim()),
      'weight': _weightCtrl.text.trim(),
    };

    if (_bloodType != null) data['blood_type'] = _bloodType;
    if (_chronicCtrl.text.isNotEmpty) data['chronic_diseases'] = _chronicCtrl.text.trim();
    if (_allergiesCtrl.text.isNotEmpty) data['allergies'] = _allergiesCtrl.text.trim();
    if (_medicationsCtrl.text.isNotEmpty) data['current_medications'] = _medicationsCtrl.text.trim();
    if (_doctorNameCtrl.text.isNotEmpty) data['family_doctor_name'] = _doctorNameCtrl.text.trim();

    // Add menstrual cycle data for females
    if (_isFemale) {
      final cycleData = <String, dynamic>{
        'menstrual_status': _menstrualStatus,
      };
      if (_cycleStartDate != null) cycleData['start_date'] = _formatDateApi(_cycleStartDate!);
      if (_cycleEndDate != null) cycleData['end_date'] = _formatDateApi(_cycleEndDate!);
      data['menstrual_cycle'] = cycleData;
    }

    final result = await ref.read(patientServiceProvider).createPatient(data);

    if (!mounted) return;

    if (result['success'] != true) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Erreur lors de la création du profil'), backgroundColor: AppColors.error),
      );
      return;
    }

    final int? patientId = result['patient_id'];

    // ── 2) Create Pregnancy if applicable ────────────────────────────
    if (_isFemale && _isPregnant && patientId != null) {
      final pregData = <String, dynamic>{
        'test_date': _pregnancyTestDate != null
            ? _formatDateApi(_pregnancyTestDate!)
            : _formatDateApi(DateTime.now()),
        'test_result': true,
        'patient': patientId,
      };
      if (_pregnancyStartDate != null) pregData['start_date'] = _formatDateApi(_pregnancyStartDate!);
      if (_pregnancyDueDate != null) pregData['due_date'] = _formatDateApi(_pregnancyDueDate!);

      final pregResult = await ref.read(pregnancyServiceProvider).createPregnancy(pregData);

      if (!mounted) return;
      if (pregResult['success'] != true) {
        // Patient created but pregnancy failed — warn but continue
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil créé mais erreur grossesse: ${pregResult['message'] ?? 'Erreur'}'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil créé ! Connectez-vous.'), backgroundColor: AppColors.success),
    );
    context.go('/login');
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compléter le profil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Step indicator
                _buildStepIndicator(),
                const SizedBox(height: 24),

                // Info banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _currentStep == 0
                              ? 'Ces informations nous aident à mieux suivre votre santé.'
                              : _currentStep == 1
                                  ? 'Informations sur votre cycle menstruel.'
                                  : 'Informations sur votre grossesse actuelle.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primaryDark),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (_currentStep == 0) ..._buildBasicInfoStep(),
                if (_currentStep == 1 && _isFemale) ..._buildMenstrualCycleStep(),
                if (_currentStep == 2 && _isFemale && _isPregnant) ..._buildPregnancyStep(),

                const SizedBox(height: 32),

                // Navigation buttons
                Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _prevStep,
                          child: const Text('Retour'),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _nextStep,
                        child: _isLoading
                            ? const SizedBox(
                                height: 22, width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(_currentStep < _totalSteps - 1 ? 'Suivant' : 'Créer mon profil'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(_totalSteps, (i) {
        return Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: i <= _currentStep ? AppColors.primary : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  STEP 0 — Basic Info (height, weight, blood type, etc.)
  // ══════════════════════════════════════════════════════════════════════
  List<Widget> _buildBasicInfoStep() {
    return [
      Text('Informations médicales', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),

      TextFormField(
        controller: _heightCtrl,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Taille (cm) *',
          prefixIcon: Icon(Icons.height, color: AppColors.primary),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Taille requise';
          final n = int.tryParse(v);
          if (n == null || n < 50 || n > 250) return 'Taille invalide';
          return null;
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _weightCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Poids (kg) *',
          prefixIcon: Icon(Icons.monitor_weight_outlined, color: AppColors.primary),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Poids requis';
          final n = double.tryParse(v);
          if (n == null || n < 20 || n > 300) return 'Poids invalide';
          return null;
        },
      ),
      const SizedBox(height: 16),

      DropdownButtonFormField<String>(
        value: _bloodType,
        decoration: const InputDecoration(
          labelText: 'Groupe sanguin',
          prefixIcon: Icon(Icons.bloodtype_outlined, color: AppColors.primary),
        ),
        items: _bloodTypes.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
        onChanged: (v) => setState(() => _bloodType = v),
      ),
      const SizedBox(height: 16),

      TextFormField(
        controller: _chronicCtrl,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'Maladies chroniques',
          prefixIcon: Icon(Icons.medical_information_outlined, color: AppColors.primary),
        ),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _allergiesCtrl,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'Allergies',
          prefixIcon: Icon(Icons.warning_amber, color: AppColors.primary),
        ),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _medicationsCtrl,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'Médicaments actuels',
          prefixIcon: Icon(Icons.medication_outlined, color: AppColors.primary),
        ),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _doctorNameCtrl,
        decoration: const InputDecoration(
          labelText: 'Nom du médecin traitant',
          prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
        ),
      ),
    ];
  }

  // ══════════════════════════════════════════════════════════════════════
  //  STEP 1 — Menstrual Cycle (females only)
  // ══════════════════════════════════════════════════════════════════════
  List<Widget> _buildMenstrualCycleStep() {
    return [
      Text('Cycle menstruel', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),

      // Menstrual status
      Text('Statut menstruel', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      Wrap(
        spacing: 10,
        children: _menstrualStatuses.map((s) {
          final selected = s['value'] == _menstrualStatus;
          return GestureDetector(
            onTap: () => setState(() => _menstrualStatus = s['value']!),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected ? AppColors.primary : const Color(0xFFE0E0E0)),
              ),
              child: Text(
                s['label']!,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 20),

      // Cycle start date
      if (_menstrualStatus == 'ACTIVE') ...[
        Text('Date début du dernier cycle', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        _buildDatePicker(
          value: _cycleStartDate,
          hint: 'Sélectionner la date de début',
          onTap: () => _pickDate(
            current: _cycleStartDate,
            firstDate: DateTime.now().subtract(const Duration(days: 90)),
            lastDate: DateTime.now(),
            onPicked: (d) => _cycleStartDate = d,
          ),
        ),
        const SizedBox(height: 16),

        // Cycle end date
        Text('Date fin du dernier cycle', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        _buildDatePicker(
          value: _cycleEndDate,
          hint: 'Sélectionner la date de fin',
          onTap: () => _pickDate(
            current: _cycleEndDate,
            firstDate: _cycleStartDate ?? DateTime.now().subtract(const Duration(days: 90)),
            lastDate: DateTime.now(),
            onPicked: (d) => _cycleEndDate = d,
          ),
        ),
        const SizedBox(height: 16),

        if (_cycleStartDate != null && _cycleEndDate != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: AppColors.accentDark, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Durée du cycle : ${_cycleEndDate!.difference(_cycleStartDate!).inDays} jours',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.accentDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
      ],

      // Pregnancy question
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.secondary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondary.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Êtes-vous enceinte ?', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildChoiceChip('Oui', true, _isPregnant, (v) => setState(() => _isPregnant = v)),
                const SizedBox(width: 12),
                _buildChoiceChip('Non', false, _isPregnant, (v) => setState(() => _isPregnant = v)),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  // ══════════════════════════════════════════════════════════════════════
  //  STEP 2 — Pregnancy Info (if pregnant)
  // ══════════════════════════════════════════════════════════════════════
  List<Widget> _buildPregnancyStep() {
    return [
      Text('Grossesse', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),

      // Pregnancy test date
      Text('Date du test de grossesse *', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      _buildDatePicker(
        value: _pregnancyTestDate,
        hint: 'Sélectionner la date du test',
        onTap: () => _pickDate(
          current: _pregnancyTestDate,
          firstDate: DateTime.now().subtract(const Duration(days: 300)),
          lastDate: DateTime.now(),
          onPicked: (d) => _pregnancyTestDate = d,
        ),
      ),
      const SizedBox(height: 20),

      // Start date of pregnancy
      Text('Date de début de grossesse', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      _buildDatePicker(
        value: _pregnancyStartDate,
        hint: 'Sélectionner la date de début',
        onTap: () => _pickDate(
          current: _pregnancyStartDate,
          firstDate: DateTime.now().subtract(const Duration(days: 300)),
          lastDate: DateTime.now(),
          onPicked: (d) => _pregnancyStartDate = d,
        ),
      ),
      const SizedBox(height: 20),

      // Due date
      Text('Date prévue d\'accouchement', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      _buildDatePicker(
        value: _pregnancyDueDate,
        hint: 'Sélectionner la date prévue',
        onTap: () => _pickDate(
          current: _pregnancyDueDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 300)),
          onPicked: (d) => _pregnancyDueDate = d,
        ),
      ),
      const SizedBox(height: 20),

      // Summary
      if (_pregnancyStartDate != null) ...[
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.pregnant_woman, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Résumé de la grossesse',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Semaine actuelle : ${((DateTime.now().difference(_pregnancyStartDate!).inDays) / 7).floor()} semaines',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primaryDark),
              ),
              if (_pregnancyDueDate != null)
                Text(
                  'Jours restants : ${_pregnancyDueDate!.difference(DateTime.now()).inDays} jours',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primaryDark),
                ),
            ],
          ),
        ),
      ],
    ];
  }

  // ── Helper widgets ──────────────────────────────────────────────────

  Widget _buildDatePicker({DateTime? value, required String hint, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value != null ? _formatDate(value) : hint,
                style: TextStyle(
                  color: value != null ? AppColors.textPrimary : AppColors.textLight,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip<T>(String label, T value, T groupValue, ValueChanged<T> onSelected) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : const Color(0xFFE0E0E0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
