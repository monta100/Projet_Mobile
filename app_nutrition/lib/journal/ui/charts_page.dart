import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/journal_providers.dart';
import '../models/health_record.dart';
import '../utils/stats_utils.dart';
import '../utils/export_utils.dart';

class ChartsPage extends ConsumerWidget {
  const ChartsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapAsync = ref.watch(last7DaysProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques (7 jours)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exporter (PDF/Excel) …',
            onPressed: () => ExportUtils.openRangeExportSheet(context),
          )
        ],
      ),
      body: mapAsync.when(
        data: (map) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final t in HealthMetricType.values)
              if (map[t]!.isNotEmpty) _MetricCard(type: t, records: map[t]!),
          ],
        ),
        error: (e, st) => Center(child: Text('Erreur: $e')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final HealthMetricType type;
  final List<HealthRecord> records;
  const _MetricCard({required this.type, required this.records});

  @override
  Widget build(BuildContext context) {
    final points = StatsUtils.seriesFor(type, records);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(type.label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: LineChart(LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: const FlTitlesData(show: true),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (final p in points)
                        FlSpot(p.x.toDouble(), p.y.toDouble()),
                    ],
                    isCurved: true,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              )),
            ),
            const SizedBox(height: 8),
            Text('Moyenne: ${StatsUtils.avg(points).toStringAsFixed(2)}  •  Max: ${StatsUtils.max(points)}  •  Min: ${StatsUtils.min(points)}'),
          ],
        ),
      ),
    );
  }
}

