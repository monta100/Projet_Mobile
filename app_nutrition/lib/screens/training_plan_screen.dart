import 'package:flutter/material.dart';
import 'results_screen.dart';
import '../Services/local_storage_service.dart';

const Color primaryGreen = Color(0xFF2ECC71);
const Color darkGreen = Color(0xFF27AE60);
const Color lightGreen = Color(0xFFD5F4E6);
const Color accentGreen = Color(0xFF1ABC9C);

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
        title: const Text('Plan d\'Entraînement'),
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [lightGreen, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_savedPlans.isNotEmpty) ...[
                    Text(
                      'Plans Antérieurs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._savedPlans
                        .take(3)
                        .map(
                          (plan) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white,
                                    lightGreen.withOpacity(0.5),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: primaryGreen.withOpacity(0.3),
                                ),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: primaryGreen.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.history,
                                    color: primaryGreen,
                                  ),
                                ),
                                title: Text(
                                  '${plan['training_weeks']}w • ${plan['sessions_per_week']}x/sem',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'Salle: \$${(plan['gym_cost_monthly'] as num).toStringAsFixed(2)} • Nourr./jour: \$${(plan['daily_food_budget'] as num).toStringAsFixed(2)}',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                trailing: Text(
                                  (plan['created_at'] as String)
                                      .split('T')
                                      .first,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    const SizedBox(height: 24),
                  ],
                  Text(
                    'Planifiez votre entraînement',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Entrez vos paramètres d\'entraînement et budgets',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 28),
                  _buildPlanField(
                    label: 'Durée d\'entraînement (semaines)',
                    icon: Icons.calendar_month,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer la durée';
                      }
                      final weeks = int.tryParse(value);
                      if (weeks == null || weeks < 1) {
                        return 'Entrez un nombre de semaines valide';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      trainingWeeks = int.tryParse(value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildPlanField(
                    label: 'Sessions d\'entraînement par semaine',
                    icon: Icons.repeat,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer le nombre de sessions';
                      }
                      final sessions = int.tryParse(value);
                      if (sessions == null || sessions < 1 || sessions > 7) {
                        return 'Entrez un nombre entre 1 et 7';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      sessionsPerWeek = int.tryParse(value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildPlanField(
                    label: 'Coût d\'abonnement mensuel à la salle',
                    icon: Icons.fitness_center,
                    keyboardType: TextInputType.number,
                    prefixText: '\$',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer le coût';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      gymCost = double.tryParse(value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildPlanField(
                    label: 'Budget quotidien pour la nourriture',
                    icon: Icons.restaurant_menu,
                    keyboardType: TextInputType.number,
                    prefixText: '\$',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer le budget';
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
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 6,
                      shadowColor: primaryGreen.withOpacity(0.4),
                    ),
                    child: const Text(
                      'Calculer les Coûts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanField({
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
    String? prefixText,
    required String? Function(String?)? validator,
    required void Function(String?)? onSaved,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryGreen),
        prefixText: prefixText != null ? '$prefixText ' : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: primaryGreen.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2.5),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        labelStyle: const TextStyle(color: darkGreen),
        floatingLabelStyle: const TextStyle(color: primaryGreen),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
      keyboardType: keyboardType,
      validator: validator,
      onSaved: onSaved,
    );
  }
}
