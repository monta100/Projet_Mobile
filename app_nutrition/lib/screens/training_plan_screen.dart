import 'package:flutter/material.dart';
import 'results_screen.dart';
import '../Services/local_storage_service.dart';

class TrainingPlanScreen extends StatefulWidget {
  const TrainingPlanScreen({super.key});

  @override
  State<TrainingPlanScreen> createState() => _TrainingPlanScreenState();
}

class _TrainingPlanScreenState extends State<TrainingPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  double? currentWeight;
  double? targetWeight;
  int? trainingWeeks;
  int? sessionsPerWeek;
  double? gymCost;
  double? dailyFoodBudget;
  List<Map<String, dynamic>> _savedPlans = const [];

  @override
  void initState() {
    super.initState();
    _loadSavedPlans();
  }

  Future<void> _loadSavedPlans() async {
    final storage = LocalStorageService();
    final plans = await storage.getSavedPlans();
    if (!mounted) return;
    setState(() {
      _savedPlans = plans.reversed.toList(growable: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan d\'Entraînement'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_savedPlans.isNotEmpty) ...[
                  const Text(
                    'Plans Précédents',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._savedPlans.take(5).map((plan) => Card(
                        elevation: 2,
                        child: ListTile(
                          leading: const Icon(Icons.history),
                          title: Text(
                            '${plan['training_weeks']}w • ${plan['sessions_per_week']}x/week',
                          ),
                          subtitle: Text(
                            'Gym: \$${(plan['gym_cost_monthly'] as num).toStringAsFixed(2)} • Food/day: \$${(plan['daily_food_budget'] as num).toStringAsFixed(2)}',
                          ),
                          trailing: Text(
                            (plan['created_at'] as String).split('T').first,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      )),
                  const SizedBox(height: 20),
                ],
                const Text(
                  'Planifiez Votre Entraînement',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Poids Actuel (kg)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre poids actuel';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    currentWeight = double.tryParse(value!);
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Poids Cible (kg)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre poids cible';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    targetWeight = double.tryParse(value!);
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Durée d\'Entraînement (semaines)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer la durée d\'entraînement';
                    }
                    final weeks = int.tryParse(value);
                    if (weeks == null || weeks < 1) {
                      return 'Veuillez entrer un nombre de semaines valide';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    trainingWeeks = int.tryParse(value!);
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Séances par Semaine',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer le nombre de séances par semaine';
                    }
                    final sessions = int.tryParse(value);
                    if (sessions == null || sessions < 1 || sessions > 7) {
                      return 'Veuillez entrer un nombre entre 1 et 7';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    sessionsPerWeek = int.tryParse(value!);
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Coût Abonnement Gym (mensuel)',
                    border: OutlineInputBorder(),
                    prefixText: '\$',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer le coût de l\'abonnement';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    gymCost = double.tryParse(value!);
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Budget Alimentaire (quotidien)',
                    border: OutlineInputBorder(),
                    prefixText: '\$',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer le budget alimentaire quotidien';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    dailyFoodBudget = double.tryParse(value!);
                  },
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResultsScreen(
                            currentWeight: currentWeight!,
                            targetWeight: targetWeight!,
                            trainingWeeks: trainingWeeks!,
                            sessionsPerWeek: sessionsPerWeek!,
                            gymCost: gymCost!,
                            dailyFoodBudget: dailyFoodBudget!,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Calculer les Coûts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}