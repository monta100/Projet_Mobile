import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MoodEntry {
  final DateTime date;
  final int mood; // 1..5
  final String? note;
  MoodEntry(this.date, this.mood, this.note);
}

final moodListProvider = StateProvider<List<MoodEntry>>((_) => []);

class WellbeingPage extends ConsumerWidget {
  const WellbeingPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final list = ref.watch(moodListProvider);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bien-être mental',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Suivez et améliorez votre humeur',
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
        ),
      ),
      body: list.isEmpty
          ? const Center(
              child: Text('Aucune entrée. Ajoutez votre humeur du jour.'),
            )
          : ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (_, i) {
                final e = list[i];
                final moodFaces = List.generate(e.mood, (_) => '😊').join();
                return ListTile(
                  title: Text(
                    'Humeur: $moodFaces',
                    style: theme.textTheme.bodyLarge,
                  ),
                  subtitle: Text(
                    e.note ?? '',
                    style: theme.textTheme.bodyMedium,
                  ),
                  trailing: Text(
                    '${e.date.year}-${e.date.month}-${e.date.day}',
                    style: theme.textTheme.bodySmall,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final res = await _add(context);
          if (res != null) {
            ref.read(moodListProvider.notifier).state = [res, ...list];
          }
        },
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Future<MoodEntry?> _add(BuildContext ctx) async {
    final theme = Theme.of(ctx);
    int mood = 3;
    final noteCtl = TextEditingController();
    return showDialog<MoodEntry>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(
          'Ajouter humeur',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: const Color(0xFF8BC34A),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: mood,
              items: [1, 2, 3, 4, 5]
                  .map(
                    (e) => DropdownMenuItem(value: e, child: Text('Niveau $e')),
                  )
                  .toList(),
              onChanged: (v) => mood = v ?? 3,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF8BC34A)),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Color(0xFF8BC34A),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtl,
              decoration: InputDecoration(
                labelText: 'Note',
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF8BC34A)),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Color(0xFF8BC34A),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Annuler',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF8BC34A),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              ctx,
              MoodEntry(
                DateTime.now(),
                mood,
                noteCtl.text.trim().isEmpty ? null : noteCtl.text.trim(),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8BC34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}
