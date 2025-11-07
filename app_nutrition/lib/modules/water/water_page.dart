import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'water_notifs.dart';
import 'package:shared_preferences/shared_preferences.dart';


final waterGoalProvider = StateProvider<int>((_) => 2000); // ml / jour
final waterIntervalProvider = StateProvider<int>((_) => 120); // minutes (toutes 2h)

class WaterPage extends ConsumerWidget {
  const WaterPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(waterGoalProvider);
    final interval = ref.watch(waterIntervalProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Hydratation')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            Expanded(child: Text('Objectif quotidien (ml): $goal')),
            IconButton(
              onPressed: () async {
                final val = await _pickNumber(context, goal, 500, 6000);
                if (val != null) {
                  ref.read(waterGoalProvider.notifier).state = val;
                  final p = await SharedPreferences.getInstance();
                  p.setInt('water_goal', val);
                }
              },
              icon: const Icon(Icons.edit),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text('Intervalle rappel (min): $interval')),
            IconButton(
              onPressed: () async {
                final val = await _pickNumber(context, interval, 15, 360);
                if (val != null) {
                  ref.read(waterIntervalProvider.notifier).state = val;
                  final p = await SharedPreferences.getInstance();
                  p.setInt('water_interval', val);
                }
              },
              icon: const Icon(Icons.edit),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await WaterNotifs.scheduleEvery(interval);
                  if (context.mounted) _ok(context, 'Rappels activés');
                },
                icon: const Icon(Icons.alarm),
                label: const Text('Activer les rappels'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await WaterNotifs.cancel();
                  if (context.mounted) _ok(context, 'Rappels désactivés');
                },
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('Désactiver'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Future<int?> _pickNumber(BuildContext ctx, int current, int min, int max) async {
    final c = TextEditingController(text: '$current');
    return showDialog<int>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Modifier'),
        content: TextField(controller: c, keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final v = int.tryParse(c.text);
              if (v != null && v >= min && v <= max) Navigator.pop(ctx, v);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _ok(BuildContext ctx, String m) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(m)));
  }
}