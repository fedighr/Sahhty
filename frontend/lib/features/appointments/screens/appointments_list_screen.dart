import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/services/appointment_service.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/empty_state_widget.dart';

final appointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  return await ref.read(appointmentServiceProvider).getAppointments();
});

class AppointmentsListScreen extends ConsumerWidget {
  const AppointmentsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apptAsync = ref.watch(appointmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes Rendez-vous', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: apptAsync.when(
        loading: () => const Padding(padding: EdgeInsets.all(20), child: LoadingShimmer()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (appointments) {
          if (appointments.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.calendar_month_outlined,
              title: 'Aucun rendez-vous',
              subtitle: 'Vos rendez-vous apparaîtront ici.',
            );
          }

          final upcoming = appointments.where((a) => a.isUpcoming).toList();
          final past = appointments.where((a) => !a.isUpcoming).toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (upcoming.isNotEmpty) ...[
                const Text('À venir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                ...upcoming.map((a) => _AppointmentTile(appointment: a)),
              ],
              if (past.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text('Passés', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                ...past.map((a) => _AppointmentTile(appointment: a, isPast: true)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final Appointment appointment;
  final bool isPast;
  const _AppointmentTile({required this.appointment, this.isPast = false});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(appointment.appointmentDate);
    final statusColor = _statusColor(appointment.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPast ? AppColors.surface.withOpacity(0.7) : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.cardShadow.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(date != null ? DateFormat('dd').format(date) : '--', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: statusColor)),
                Text(date != null ? DateFormat('MMM', 'fr_FR').format(date).toUpperCase() : '--', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appointment.reason, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isPast ? AppColors.textSecondary : AppColors.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                if (appointment.doctorName != null)
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Expanded(child: Text(appointment.doctorName!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                    ],
                  ),
                if (appointment.doctorSpeciality != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 18),
                    child: Text(appointment.doctorSpeciality!, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(date != null ? DateFormat('HH:mm').format(date) : '--:--', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(appointment.statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'CONFIRMED': return AppColors.success;
      case 'PENDING': return AppColors.warning;
      case 'CANCELLED': return AppColors.error;
      case 'COMPLETED': return AppColors.textSecondary;
      default: return AppColors.primary;
    }
  }
}
