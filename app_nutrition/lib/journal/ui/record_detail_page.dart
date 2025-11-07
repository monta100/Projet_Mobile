import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../state/journal_providers.dart';
import '../models/health_record.dart';
import '../data/journal_repository.dart';
import 'add_edit_record_page.dart';
import '../utils/export_utils.dart';

class RecordDetailPage extends ConsumerWidget {
  final int recordId;
  const RecordDetailPage({super.key, required this.recordId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(selectedRecordProvider(recordId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Détail',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Visualisez et gérez vos données',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
          centerTitle: false,
          backgroundColor: const Color(0xFF8BC34A), // Matching green shade
          elevation: 6,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Export PDF (entrée seule)',
              onPressed: () async {
                final r = await ref.read(
                  selectedRecordProvider(recordId).future,
                );
                if (r != null)
                  await ExportUtils.exportSingleRecordPdf(context, r);
              },
            ),
          ],
        ),
      ),
      body: async.when(
        data: (r) =>
            r == null ? const Center(child: Text('Introuvable')) : _Body(r: r),
        error: (e, st) => Center(
          child: Text(
            'Erreur: $e',
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.redAccent),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final HealthRecord r;
  const _Body({required this.r});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final df = DateFormat('y-MM-dd HH:mm');
    final repo = ref.read(journalRepoProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            r.type.label,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(df.format(r.dateTime), style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(_valueText(r), style: theme.textTheme.titleMedium),
            ),
          ),
          const SizedBox(height: 12),
          if (r.note != null)
            Text('📝 ${r.note!}', style: theme.textTheme.bodyMedium),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('Supprimer'),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(
                          'Supprimer ?',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: const Color(0xFF8BC34A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: const Text(
                          'Êtes-vous sûr de vouloir supprimer cet enregistrement ?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              'Non',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF8BC34A),
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8BC34A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Oui'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await repo.delete(r.id!);
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Modifier'),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditRecordPage(existing: r),
                      ),
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8BC34A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _valueText(HealthRecord r) {
    switch (r.type) {
      case HealthMetricType.bloodPressure:
        return 'BP: ${r.values['systolic']?.toStringAsFixed(0)}/${r.values['diastolic']?.toStringAsFixed(0)} mmHg';
      case HealthMetricType.glucose:
        return 'Glucose: ${r.values['value']} mg/dL';
      case HealthMetricType.sleep:
        return 'Sleep: ${r.values['hours']} h';
      case HealthMetricType.weight:
        return 'Poids: ${r.values['kg']} kg';
      case HealthMetricType.heartRate:
        return 'BPM: ${r.values['bpm']}';
      case HealthMetricType.custom:
        return 'Valeur: ${r.values['value']} ${r.unit ?? ''}';
    }
  }
}
