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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF (entrée seule)',
            onPressed: () async {
              final r = await ref.read(selectedRecordProvider(recordId).future);
              if (r != null) await ExportUtils.exportSingleRecordPdf(context, r);
            },
          ),
        ],
      ),
      body: async.when(
        data: (r) => r == null
            ? const Center(child: Text('Introuvable'))
            : _Body(r: r),
        error: (e, st) => Center(child: Text('Erreur: $e')),
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(r.type.label, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(df.format(r.dateTime), style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(_valueText(r), style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          const SizedBox(height: 12),
          if (r.note != null) Text('📝 ${r.note!}'),
          const Spacer(),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete),
                label: const Text('Supprimer'),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                     title: const Text('Supprimer ?'),
content: const Text('Êtes-vous sûr de vouloir supprimer cet enregistrement ?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
                        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Oui')),
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
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditRecordPage(existing: r)));
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ),
          ])
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
