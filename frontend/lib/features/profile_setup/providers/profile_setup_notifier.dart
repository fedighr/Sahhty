// lib/features/profile_setup/providers/profile_setup_notifier.dart

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_failure.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/auth_model.dart';
import '../../../data/services/profile_service.dart';

// ─── State ────────────────────────────────────────────────────────────────────

sealed class ProfileSetupState extends Equatable {
  const ProfileSetupState();
  @override List<Object?> get props => [];
}

class ProfileSetupInitial  extends ProfileSetupState { const ProfileSetupInitial(); }
class ProfileSetupLoading  extends ProfileSetupState { const ProfileSetupLoading(); }
class ProfileSetupSuccess  extends ProfileSetupState { const ProfileSetupSuccess(); }
class ProfileSetupError extends ProfileSetupState {
  final String message;
  const ProfileSetupError(this.message);
  @override List<Object?> get props => [message];
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class ProfileSetupNotifier extends Notifier<ProfileSetupState> {
  late final IProfileService _service;

  @override
  ProfileSetupState build() {
    _service = ref.watch(profileServiceProvider);
    return const ProfileSetupInitial();
  }

  Future<void> createPatient(CreatePatientRequest request) async {
    if (state is ProfileSetupLoading) return;
    state = const ProfileSetupLoading();
    try {
      await _service.createPatient(request);
      AppLogger.i('Patient profile created');
      state = const ProfileSetupSuccess();
    } on ValidationFailure catch (e) {
      state = ProfileSetupError(e.message);
    } on NetworkFailure catch (e) {
      state = ProfileSetupError(e.message);
    } on AppFailure catch (e) {
      state = ProfileSetupError(e.message);
    } catch (e, st) {
      AppLogger.e('createPatient error', e, st);
      state = const ProfileSetupError('Erreur inattendue. Réessayez.');
    }
  }

  Future<void> createDoctor(CreateDoctorRequest request) async {
    if (state is ProfileSetupLoading) return;
    state = const ProfileSetupLoading();
    try {
      await _service.createDoctor(request);
      AppLogger.i('Doctor profile created');
      state = const ProfileSetupSuccess();
    } on ValidationFailure catch (e) {
      state = ProfileSetupError(e.message);
    } on NetworkFailure catch (e) {
      state = ProfileSetupError(e.message);
    } on AppFailure catch (e) {
      state = ProfileSetupError(e.message);
    } catch (e, st) {
      AppLogger.e('createDoctor error', e, st);
      state = const ProfileSetupError('Erreur inattendue. Réessayez.');
    }
  }

  void reset() => state = const ProfileSetupInitial();
}

final profileSetupNotifierProvider =
    NotifierProvider<ProfileSetupNotifier, ProfileSetupState>(ProfileSetupNotifier.new);
