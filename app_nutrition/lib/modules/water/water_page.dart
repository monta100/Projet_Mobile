import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'water_notifs.dart';

final waterGoalProvider = StateProvider<int>((_) => 2000); // ml / jour
final waterIntervalProvider = StateProvider<int>(
  (_) => 120,
); // minutes (toutes 2h)

class WaterPage extends ConsumerStatefulWidget {
  const WaterPage({super.key});

  @override
  ConsumerState<WaterPage> createState() => _WaterPageState();
}

class _WaterPageState extends ConsumerState<WaterPage> {
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_hydrateFromStorage);
  }

  Future<void> _hydrateFromStorage() async {
    await WaterNotifs.init();
    final prefs = await SharedPreferences.getInstance();
    final savedGoal = prefs.getInt('water_goal');
    final savedInterval = prefs.getInt('water_interval');

    if (savedGoal != null) {
      ref.read(waterGoalProvider.notifier).state = savedGoal;
    }
    if (savedInterval != null) {
      ref.read(waterIntervalProvider.notifier).state = savedInterval;
    }

    if (mounted) {
      setState(() => _isReady = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goal = ref.watch(waterGoalProvider);
    final interval = ref.watch(waterIntervalProvider);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hydratation',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Gérez vos objectifs d\'hydratation',
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
      body: !_isReady
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Objectif quotidien (ml): $goal',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final value = await _pickNumber(
                            context,
                            goal,
                            500,
                            6000,
                          );
                          if (value != null) {
                            ref.read(waterGoalProvider.notifier).state = value;
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setInt('water_goal', value);
                          }
                        },
                        icon: const Icon(Icons.edit),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Intervalle rappel (min): $interval',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final value = await _pickNumber(
                            context,
                            interval,
                            15,
                            360,
                          );
                          if (value != null) {
                            final int safeValue = value.clamp(15, 360);
                            ref.read(waterIntervalProvider.notifier).state =
                                safeValue;
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setInt('water_interval', safeValue);
                          }
                        },
                        icon: const Icon(Icons.edit),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              if (interval < 15) {
                                throw ArgumentError(
                                  'Intervalle trop court pour programmer un rappel.',
                                );
                              }
                              await WaterNotifs.scheduleEvery(interval);
                              if (!mounted) return;
                              _showToast(context, 'Rappels activés');
                            } catch (e) {
                              if (!mounted) return;
                              String displayMessage =
                                  'Impossible d\'activer les rappels. Vérifiez les permissions.';
                              if (e is ArgumentError) {
                                displayMessage =
                                    e.message?.toString() ?? e.toString();
                              } else if (e is StateError) {
                                displayMessage = e.message;
                              }
                              _showToast(context, displayMessage);
                              debugPrint(
                                'Water reminder activation failed: $e',
                              );
                            }
                          },
                          icon: const Icon(Icons.alarm),
                          label: const Text('Activer les rappels'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8BC34A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await WaterNotifs.cancel();
                            if (context.mounted) {
                              _showToast(context, 'Rappels désactivés');
                            }
                          },
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: const Text('Désactiver'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF8BC34A),
                            side: const BorderSide(color: Color(0xFF8BC34A)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Future<int?> _pickNumber(
    BuildContext ctx,
    int current,
    int min,
    int max,
  ) async {
    final theme = Theme.of(ctx);
    final controller = TextEditingController(text: '$current');
    final result = await showDialog<int>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(
          'Modifier',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: const Color(0xFF8BC34A),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF8BC34A)),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF8BC34A), width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.water_drop, color: Color(0xFF8BC34A)),
          ),
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
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed == null) {
                Navigator.pop(ctx);
                return;
              }
              final clamped = parsed.clamp(min, max).toInt();
              Navigator.pop(ctx, clamped);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8BC34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return result;
  }

  void _showToast(BuildContext ctx, String message) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(message)));
  }
}
