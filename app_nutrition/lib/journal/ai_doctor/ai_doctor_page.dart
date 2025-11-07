import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ai_doctor_service.dart';

class AiDoctorPage extends ConsumerWidget {
  const AiDoctorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tips = ref.watch(aiDoctorProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('AI Doctor – Conseils santé')),
      body: tips.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Aucune donnée suffisante. Ajoutez des mesures.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (_, i) => _TipCard(items[i]),
          );
        },
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard(this.tip);
  final AiTip tip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = switch (tip.priority) {
      3 => Colors.redAccent,
      2 => Colors.orange,
      _ => cs.primary,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(8)),
                child: Text(tip.category, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
              ),
              Text(tip.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 8),
            Text(tip.body),
          ],
        ),
      ),
    );
  }
}
