import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/attachment_model.dart';
import '../../../core/widgets/empty_state_widget.dart';

final attachmentsProvider = FutureProvider<List<Attachment>>((ref) async {
  // Backend medical_files module has no endpoints yet
  // Return empty list until backend implements the API
  return [];
});

class MedicalFilesScreen extends ConsumerWidget {
  const MedicalFilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(attachmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dossier Médical', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: filesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (files) {
          if (files.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.folder_outlined,
              title: 'Aucun document',
              subtitle: 'Vos rapports et échographies apparaîtront ici.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: files.length,
            itemBuilder: (_, i) {
              final file = files[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: AppColors.cardShadow.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: file.type == 'ULTRASOUND' ? const Color(0xFFEC407A).withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        file.type == 'ULTRASOUND' ? Icons.pregnant_woman_rounded : Icons.description_outlined,
                        color: file.type == 'ULTRASOUND' ? const Color(0xFFEC407A) : AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(file.typeLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          if (file.uploadDate != null)
                            Text(
                              _formatDate(file.uploadDate!),
                              style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(String date) {
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }
}
