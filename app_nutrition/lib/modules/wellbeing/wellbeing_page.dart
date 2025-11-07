import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

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
    final list = ref.watch(moodListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Bien-être mental')),
      body: list.isEmpty
          ? const Center(child: Text('Aucune entrée. Ajoutez votre humeur du jour.'))
          : ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (_, i) {
                final e = list[i];
                return ListTile(
                  title: Text('Humeur: ${"😊😊😊😊😊".substring(0, e.mood)}'),
                  subtitle: Text(e.note ?? ''),
                  trailing: Text('${e.date.year}-${e.date.month}-${e.date.day}'),
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
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<MoodEntry?> _add(BuildContext ctx) async {
    int mood = 3;
    final noteCtl = TextEditingController();
    return showDialog<MoodEntry>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Ajouter humeur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: mood,
              items: [1,2,3,4,5].map((e)=>DropdownMenuItem(value:e, child: Text('Niveau $e'))).toList(),
              onChanged: (v) => mood = v ?? 3,
            ),
            const SizedBox(height: 8),
            TextField(controller: noteCtl, decoration: const InputDecoration(labelText: 'Note')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, MoodEntry(DateTime.now(), mood, noteCtl.text.trim().isEmpty? null: noteCtl.text.trim())), child: const Text('Ajouter')),
        ],
      ),
    );
  }
}
