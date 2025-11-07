import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/health_record.dart';
import '../state/journal_providers.dart';
import 'add_edit_record_page.dart';
import 'record_detail_page.dart';
import 'charts_page.dart';

class JournalHomePage extends ConsumerWidget {
  const JournalHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(journalListProvider);
    final filter = ref.watch(journalFilterProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('📒 Journal de Santé'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            tooltip: 'Statistiques',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.show_chart, 
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChartsPage()),
            ),
          ),
          IconButton(
            tooltip: 'Filtrer',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _hasActiveFilter(filter) 
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.filter_list,
                color: _hasActiveFilter(filter) 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
                size: 20,
              ),
            ),
            onPressed: () async {
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                backgroundColor: Theme.of(context).colorScheme.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => _FilterSheet(initial: filter),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Stats Header
          _buildQuickStats(context, ref),
          
          // Records List
          Expanded(
            child: listAsync.when(
              data: (items) => items.isEmpty
                  ? const _EmptyState()
                  : _buildRecordsList(context, items),
              error: (e, st) => _buildErrorState(context, e),
              loading: () => const _LoadingState(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditRecordPage()),
          );
          ref.invalidate(journalListProvider);
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  bool _hasActiveFilter(JournalFilter filter) {
    return filter.type != null || filter.from != null || filter.to != null || 
           (filter.query != null && filter.query!.isNotEmpty);
  }

  Widget _buildQuickStats(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<HealthRecord>>(
      future: ref.read(journalListProvider.future),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final records = snapshot.data!;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Theme.of(context).colorScheme.primaryContainer.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(context, 'Total', '${records.length}', Icons.assessment),
                _buildStatItem(context, 'Aujourd\'hui', 
                  '${records.where((r) => _isToday(r.dateTime)).length}', 
                  Icons.today
                ),
                _buildStatItem(context, '7 jours', 
                  '${records.where((r) => _isLast7Days(r.dateTime)).length}', 
                  Icons.calendar_view_week
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isLast7Days(DateTime date) {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    return date.isAfter(sevenDaysAgo) && date.isBefore(now.add(const Duration(days: 1)));
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordsList(BuildContext context, List<HealthRecord> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _RecordCard(record: items[i]),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Une erreur est survenue',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Veuillez réessayer',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordCard extends ConsumerWidget {
  final HealthRecord record;
  const _RecordCard({required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isToday = _isToday(record.dateTime);
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RecordDetailPage(recordId: record.id!)),
          );
          ref.invalidate(journalListProvider);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon with colored background
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getTypeColor(record.type).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getTypeIcon(record.type),
                  color: _getTypeColor(record.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          record.type.label,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Aujourd\'hui',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _buildValuesText(record),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (record.note != null && record.note!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        record.note!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              
              // Time and chevron
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(record.dateTime),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    if (_isToday(date)) {
      return DateFormat('HH:mm').format(date);
    } else {
      return DateFormat('dd/MM').format(date);
    }
  }

  Color _getTypeColor(HealthMetricType type) {
    switch (type) {
      case HealthMetricType.bloodPressure:
        return Colors.red;
      case HealthMetricType.glucose:
        return Colors.orange;
      case HealthMetricType.sleep:
        return Colors.blue;
      case HealthMetricType.weight:
        return Colors.green;
      case HealthMetricType.heartRate:
        return Colors.purple;
      case HealthMetricType.custom:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(HealthMetricType type) {
    switch (type) {
      case HealthMetricType.bloodPressure:
        return Icons.monitor_heart;
      case HealthMetricType.glucose:
        return Icons.bakery_dining;
      case HealthMetricType.sleep:
        return Icons.night_shelter;
      case HealthMetricType.weight:
        return Icons.monitor_weight;
      case HealthMetricType.heartRate:
        return Icons.favorite;
      case HealthMetricType.custom:
        return Icons.photo_size_select_actual;
    }
  }

  String _buildValuesText(HealthRecord r) {
    switch (r.type) {
      case HealthMetricType.bloodPressure:
        return '${r.values['systolic']?.toStringAsFixed(0)}/${r.values['diastolic']?.toStringAsFixed(0)} mmHg • Pouls: ${r.values['pulse'] ?? 'N/A'}';
      case HealthMetricType.glucose:
        return '${r.values['value']} mg/dL • ${r.values['context'] ?? 'N/A'}';
      case HealthMetricType.sleep:
        return '${r.values['hours']} heures • Qualité: ${r.values['quality'] ?? 'N/A'}';
      case HealthMetricType.weight:
        return '${r.values['kg']} kg • IMC: ${_calculateBMI(r.values['kg'])}';
      case HealthMetricType.heartRate:
        return '${r.values['bpm']} bpm • ${r.values['context'] ?? 'Au repos'}';
      case HealthMetricType.custom:
        return '${r.values['value']} ${r.unit ?? ''} • ${r.note ?? ''}';
    }
  }

  String _calculateBMI(dynamic kg) {
    if (kg == null) return 'N/A';
    // You might want to get height from user profile
    final height = 1.75; // Example height
    final bmi = (kg / (height * height));
    return bmi.toStringAsFixed(1);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.health_and_safety,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Commencez votre suivi santé ✨',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Ajoutez votre première mesure : pression artérielle, glycémie, sommeil, poids, fréquence cardiaque…',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement de vos données...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// Enhanced Filter Sheet with better UI
class _FilterSheet extends ConsumerStatefulWidget {
  final JournalFilter initial;
  const _FilterSheet({required this.initial});

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  HealthMetricType? _type;
  DateTime? _from;
  DateTime? _to;
  final _q = TextEditingController();

  @override
  void initState() {
    super.initState();
    _type = widget.initial.type;
    _from = widget.initial.from;
    _to = widget.initial.to;
    _q.text = widget.initial.query ?? '';
  }

  bool get _hasActiveFilter {
    return _type != null || _from != null || _to != null || _q.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Filtrer les données',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_hasActiveFilter)
                TextButton(
                  onPressed: () {
                    ref.read(journalFilterProvider.notifier).state = const JournalFilter();
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Tout effacer',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                )
            ],
          ),
          const SizedBox(height: 20),
          
          // Type Filter
          Text(
            'Type de mesure',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<HealthMetricType?>(
            value: _type,
            items: [
              const DropdownMenuItem(value: null, child: Text('Tous les types')),
              ...HealthMetricType.values.map((e) => DropdownMenuItem(
                value: e,
                child: Row(
                  children: [
                    Icon(_getTypeIcon(e), size: 20, color: _getTypeColor(e)),
                    const SizedBox(width: 8),
                    Text(e.label),
                  ],
                ),
              )),
            ],
            onChanged: (v) => setState(() => _type = v),
            decoration: InputDecoration(
              hintText: 'Sélectionnez un type',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Search
          TextField(
            controller: _q,
            decoration: InputDecoration(
              labelText: 'Rechercher dans les notes',
              prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurfaceVariant),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Date Range
          Text(
            'Période',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DatePickerTile(
                  label: 'Du',
                  initial: _from,
                  onPick: (d) => setState(() => _from = d),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DatePickerTile(
                  label: 'Au',
                  initial: _to,
                  onPick: (d) => setState(() => _to = d),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Apply Button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                ref.read(journalFilterProvider.notifier).state =
                    JournalFilter(type: _type, from: _from, to: _to, query: _q.text);
                ref.invalidate(journalListProvider);
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Appliquer les filtres'),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(HealthMetricType type) {
    switch (type) {
      case HealthMetricType.bloodPressure: return Colors.red;
      case HealthMetricType.glucose: return Colors.orange;
      case HealthMetricType.sleep: return Colors.blue;
      case HealthMetricType.weight: return Colors.green;
      case HealthMetricType.heartRate: return Colors.purple;
      case HealthMetricType.custom: return Colors.grey;
    }
  }

  IconData _getTypeIcon(HealthMetricType type) {
    switch (type) {
      case HealthMetricType.bloodPressure: return Icons.monitor_heart;
      case HealthMetricType.glucose: return Icons.bakery_dining;
      case HealthMetricType.sleep: return Icons.night_shelter;
      case HealthMetricType.weight: return Icons.monitor_weight;
      case HealthMetricType.heartRate: return Icons.favorite;
      case HealthMetricType.custom: return Icons.photo_size_select_actual;
    }
  }
}

class _DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime? initial;
  final ValueChanged<DateTime?> onPick;
  const _DatePickerTile({required this.label, required this.initial, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final now = DateTime.now();
        final d = await showDatePicker(
          context: context,
          initialDate: initial ?? now,
          firstDate: DateTime(now.year - 5),
          lastDate: DateTime(now.year + 5),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Theme.of(context).colorScheme.primary,
                ),
              ),
              child: child!,
            );
          },
        );
        onPick(d);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                initial == null ? label : DateFormat('dd/MM/yyyy').format(initial!),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: initial == null 
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}