import 'package:flutter/material.dart';
import 'results_screen.dart';
import '../Services/local_storage_service.dart';

class TrainingPlanScreen extends StatefulWidget {
  final double currentWeight;
  final double targetWeight;
  final double height;
  final int age;
  final String gender;
  final String activityLevel;

  const TrainingPlanScreen({
    super.key,
    required this.currentWeight,
    required this.targetWeight,
    required this.height,
    required this.age,
    required this.gender,
    required this.activityLevel,
  });

  @override
  State<TrainingPlanScreen> createState() => _TrainingPlanScreenState();
}

class _TrainingPlanScreenState extends State<TrainingPlanScreen> {
  final _formKey = GlobalKey<FormState>();
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
        title: const Text('Training Plan'),
        backgroundColor: Colors.blue.shade900,
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
                    'Previous Plans',
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
                  'Plan Your Training',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Training Duration (weeks)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter training duration';
                    }
                    final weeks = int.tryParse(value);
                    if (weeks == null || weeks < 1) {
                      return 'Please enter a valid number of weeks';
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
                    labelText: 'Training Sessions per Week',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter sessions per week';
                    }
                    final sessions = int.tryParse(value);
                    if (sessions == null || sessions < 1 || sessions > 7) {
                      return 'Please enter a number between 1 and 7';
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
                    labelText: 'Monthly Gym Subscription Cost',
                    border: OutlineInputBorder(),
                    prefixText: '\$',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter gym subscription cost';
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
                    labelText: 'Daily Food Budget',
                    border: OutlineInputBorder(),
                    prefixText: '\$',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter daily food budget';
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
                            currentWeight: widget.currentWeight,
                            targetWeight: widget.targetWeight,
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
                    backgroundColor: Colors.blue.shade900,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Calculate Costs',
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