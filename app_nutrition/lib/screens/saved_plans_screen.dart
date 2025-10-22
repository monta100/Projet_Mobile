import 'package:flutter/material.dart';
import '../Services/local_storage_service.dart';

class SavedPlansScreen extends StatefulWidget {
  const SavedPlansScreen({super.key});

  @override
  State<SavedPlansScreen> createState() => _SavedPlansScreenState();
}

class _SavedPlansScreenState extends State<SavedPlansScreen> {
  final LocalStorageService _storage = LocalStorageService();
  late Future<List<Map<String, dynamic>>> _plansFuture;

  @override
  void initState() {
    super.initState();
    _plansFuture = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final plans = await _storage.getSavedPlans();
    return plans.reversed.toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Plans'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear all',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear all saved plans?'),
                  content: const Text('This action cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
                  ],
                ),
              );
              if (confirm == true) {
                await _storage.clearPlans();
                setState(() {
                  _plansFuture = _load();
                });
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _plansFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final plans = snapshot.data ?? const [];
          if (plans.isEmpty) {
            return const Center(child: Text('No saved plans yet'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: plans.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final p = plans[index];
              final created = (p['created_at'] as String?)?.split('T').first ?? '';
              final weeks = p['training_weeks'];
              final freq = p['sessions_per_week'];
              final gym = (p['gym_cost_monthly'] as num?)?.toStringAsFixed(2) ?? '0.00';
              final food = (p['daily_food_budget'] as num?)?.toStringAsFixed(2) ?? '0.00';
              final totalGym = (p['total_gym_cost'] as num?)?.toStringAsFixed(2) ?? '0.00';
              final totalFood = (p['total_food_cost'] as num?)?.toStringAsFixed(2) ?? '0.00';
              final totalProgram = (p['total_program_cost'] as num?)?.toStringAsFixed(2) ?? '0.00';
              final advice = (p['budget_advice'] as String?) ?? '';
              final meal = (p['meal_plan'] as String?) ?? '';
              return Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    leading: const Icon(Icons.calendar_month),
                    title: Text('Duration: ${weeks}w • ${freq}x/week'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gym/month: \$$gym • Food/day: \$$food'),
                        Text('Totals • Gym: \$$totalGym • Food: \$$totalFood • Total: \$$totalProgram'),
                        if (advice.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text('AI Budget Recommendations:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(advice),
                        ],
                        if (meal.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text('Suggested Meal Plan:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(meal),
                        ],
                      ],
                    ),
                    trailing: Text(created, style: const TextStyle(color: Colors.grey)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}


