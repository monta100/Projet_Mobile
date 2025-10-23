import 'package:flutter/material.dart';
import '../Services/local_storage_service.dart';

class TestSavedPlansScreen extends StatefulWidget {
  const TestSavedPlansScreen({super.key});

  @override
  State<TestSavedPlansScreen> createState() => _TestSavedPlansScreenState();
}

class _TestSavedPlansScreenState extends State<TestSavedPlansScreen> {
  final LocalStorageService _storage = LocalStorageService();
  List<Map<String, dynamic>> _plans = [];
  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final plans = await _storage.getSavedPlans();
      setState(() {
        _plans = plans;
        _debugInfo = 'Plans chargés: ${plans.length}\n';
        if (plans.isNotEmpty) {
          _debugInfo += 'Premier plan: ${plans.first}\n';
        }
      });
    } catch (e) {
      setState(() {
        _debugInfo = 'Erreur: $e';
      });
    }
  }

  Future<void> _addTestPlan() async {
    try {
      await _storage.addPlan({
        'created_at': DateTime.now().toIso8601String(),
        'current_weight': 80.0,
        'target_weight': 75.0,
        'training_weeks': 8,
        'sessions_per_week': 3,
        'gym_cost_monthly': 50.0,
        'daily_food_budget': 20.0,
        'total_gym_cost': 100.0,
        'total_food_cost': 1120.0,
        'total_program_cost': 1220.0,
        'budget_advice': 'Test advice',
        'meal_plan': 'Test meal plan',
      });
      
      setState(() {
        _debugInfo = 'Plan de test ajouté avec succès!\n';
      });
      
      await _loadPlans();
    } catch (e) {
      setState(() {
        _debugInfo = 'Erreur lors de l\'ajout: $e';
      });
    }
  }

  Future<void> _clearAllPlans() async {
    try {
      await _storage.clearPlans();
      setState(() {
        _debugInfo = 'Tous les plans ont été supprimés!\n';
      });
      await _loadPlans();
    } catch (e) {
      setState(() {
        _debugInfo = 'Erreur lors de la suppression: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Saved Plans'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Debug Info:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_debugInfo),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addTestPlan,
              child: const Text('Ajouter un plan de test'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadPlans,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Recharger les plans'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _clearAllPlans,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Supprimer tous les plans'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _plans.length,
                itemBuilder: (context, index) {
                  final plan = _plans[index];
                  return Card(
                    child: ListTile(
                      title: Text('Plan ${index + 1}'),
                      subtitle: Text(
                        'Semaines: ${plan['training_weeks']}\n'
                        'Sessions: ${plan['sessions_per_week']}\n'
                        'Gym: \$${plan['gym_cost_monthly']}\n'
                        'Food: \$${plan['daily_food_budget']}',
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

