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
        title: const Text('Plans Sauvegardés'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Tout supprimer',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Supprimer tous les plans ?'),
                  content: const Text('Cette action est irréversible.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer')),
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
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          final plans = snapshot.data ?? const [];
          if (plans.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucun plan sauvegardé',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
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
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.calendar_month, color: Colors.blue),
                    ),
                    title: Text(
                      'Plan ${weeks} semaines • ${freq}x/semaine',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.fitness_center, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text('Gym: \$$gym/mois'),
                              const SizedBox(width: 12),
                              Icon(Icons.restaurant, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text('Nourriture: \$$food/jour'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Coût total: \$$totalProgram',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Créé le: $created',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Détails des coûts
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Détails des coûts',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const Divider(),
                                  _buildDetailRow('Gym total', '\$$totalGym'),
                                  _buildDetailRow('Nourriture total', '\$$totalFood'),
                                  const Divider(thickness: 2),
                                  _buildDetailRow('Total du programme', '\$$totalProgram', isBold: true),
                                ],
                              ),
                            ),
                            // Recommandations IA
                            if (advice.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.amber.shade300),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.lightbulb, color: Colors.amber.shade700),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Recommandations IA Budget',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      advice,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            // Plan de repas IA
                            if (meal.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.shade300),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.restaurant_menu, color: Colors.green.shade700),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Plan de Repas Suggéré',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      meal,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Colors.green.shade700 : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}


