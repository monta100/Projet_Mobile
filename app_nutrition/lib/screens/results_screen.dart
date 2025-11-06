import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../Services/database_helper.dart';
import '../Services/gemini_ai_service.dart';
import '../Services/local_storage_service.dart';
import 'expenses_history_screen.dart';

const Color primaryGreen = Color(0xFF2ECC71);
const Color darkGreen = Color(0xFF27AE60);
const Color lightGreen = Color(0xFFD5F4E6);
const Color accentGreen = Color(0xFF1ABC9C);

class ResultsScreen extends StatefulWidget {
  final double currentWeight;
  final double targetWeight;
  final int trainingWeeks;
  final int sessionsPerWeek;
  final double gymCost;
  final double dailyFoodBudget;

  const ResultsScreen({
    super.key,
    required this.currentWeight,
    required this.targetWeight,
    required this.trainingWeeks,
    required this.sessionsPerWeek,
    required this.gymCost,
    required this.dailyFoodBudget,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final GeminiAIService _aiService = GeminiAIService();
  String? _budgetAdvice;
  String? _mealPlan;
  bool _isLoading = true;
  Map<String, dynamic>? _expenses;
  bool _expensesLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAIAdvice();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _expensesLoading = true;
    });
    try {
      // Simule un planId = 1 (à adapter selon votre logique réelle)
      final expenses = await DatabaseHelper().getPlanExpenses(1);
      setState(() {
        _expenses = expenses;
        _expensesLoading = false;
      });
    } catch (e) {
      setState(() {
        _expenses = null;
        _expensesLoading = false;
      });
    }
  }

  Future<void> _loadAIAdvice() async {
    try {
      final budgetAdvice = _aiService.getBudgetAdvice(
        currentWeight: widget.currentWeight,
        targetWeight: widget.targetWeight,
        trainingWeeks: widget.trainingWeeks,
        sessionsPerWeek: widget.sessionsPerWeek,
        gymCost: widget.gymCost,
        dailyFoodBudget: widget.dailyFoodBudget,
      );

      final mealPlan = _aiService.getCustomMealPlan(
        currentWeight: widget.currentWeight,
        targetWeight: widget.targetWeight,
        dailyFoodBudget: widget.dailyFoodBudget,
      );

      final results = await Future.wait([budgetAdvice, mealPlan]);

      setState(() {
        _budgetAdvice = results[0];
        _mealPlan = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _budgetAdvice = 'Error loading AI advice: $e';
        _mealPlan = 'Error loading meal plan';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDays = widget.trainingWeeks * 7;
    final monthlyGymCost = widget.gymCost;
    final totalGymCost = (widget.trainingWeeks / 4) * monthlyGymCost;
    final totalFoodCost = totalDays * widget.dailyFoodBudget;
    final totalCost = totalGymCost + totalFoodCost;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Résumé des Coûts'),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Training Summary',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildInfoRow(
                          'Duration',
                          '${widget.trainingWeeks} weeks',
                        ),
                        _buildInfoRow(
                          'Sessions per Week',
                          '${widget.sessionsPerWeek} sessions',
                        ),
                        _buildInfoRow(
                          'Weight Goal',
                          '${(widget.targetWeight - widget.currentWeight).abs()} kg ${widget.targetWeight > widget.currentWeight ? 'gain' : 'loss'}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cost Breakdown',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildCostRow('Monthly Gym Cost', monthlyGymCost),
                        _buildCostRow('Total Gym Cost', totalGymCost),
                        _buildCostRow(
                          'Daily Food Budget',
                          widget.dailyFoodBudget,
                        ),
                        _buildCostRow('Total Food Cost', totalFoodCost),
                        const Divider(thickness: 2),
                        _buildCostRow(
                          'Total Program Cost',
                          totalCost,
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.lightbulb_outline,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'AI Budget Recommendations',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_isLoading)
                              const Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (_isLoading)
                          const Center(
                            child: Text('Generating personalized advice...'),
                          )
                        else ...[
                          const Text(
                            'Budget Optimization Tips:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _budgetAdvice ?? 'Unable to load budget advice.',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Suggested Meal Plan:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _mealPlan ?? 'Unable to load meal plan.',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 4,
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _expensesLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _expenses == null
                        ? const Text('Aucune dépense enregistrée pour ce plan.')
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Gestion des Dépenses',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const ExpensesHistoryScreen(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.history,
                                      color: Colors.orange,
                                    ),
                                    label: const Text(
                                      'Historique',
                                      style: TextStyle(color: Colors.orange),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _buildExpenseRow(
                                'Abonnement Gym',
                                _expenses!['gym_subscription'],
                              ),
                              _buildExpenseRow(
                                'Nourriture',
                                _expenses!['food_costs'],
                              ),
                              _buildExpenseRow(
                                'Suppléments',
                                _expenses!['supplements_costs'],
                              ),
                              _buildExpenseRow(
                                'Équipement',
                                _expenses!['equipment_costs'],
                              ),
                              _buildExpenseRow(
                                'Autres',
                                _expenses!['other_costs'],
                              ),
                              const Divider(),
                              _buildExpenseRow(
                                'Total',
                                _expenses!['total_cost'],
                                isTotal: true,
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () async {
                    final localStorage = LocalStorageService();

                    // Precompute snapshot values for persistence
                    final int _totalDays = widget.trainingWeeks * 7;
                    final double _totalGymCost =
                        (widget.trainingWeeks / 4) * widget.gymCost;
                    final double _totalFoodCost =
                        _totalDays * widget.dailyFoodBudget;
                    final double _totalProgramCost =
                        _totalGymCost + _totalFoodCost;

                    // If not web, also persist to SQLite. On web, skip SQLite entirely.
                    if (!kIsWeb) {
                      final dbHelper = DatabaseHelper();
                      try {
                        // Save training plan
                        final planData = {
                          'user_id':
                              1, // Utiliser l'ID utilisateur actuel si disponible
                          'duration_weeks': widget.trainingWeeks,
                          'training_frequency': widget.sessionsPerWeek,
                          'start_date': DateTime.now().toIso8601String(),
                          'end_date': DateTime.now()
                              .add(Duration(days: widget.trainingWeeks * 7))
                              .toIso8601String(),
                        };
                        final planId = await dbHelper.insert(
                          'training_plans',
                          planData,
                        );

                        // Save expenses
                        await dbHelper.calculateAndSaveExpenses(
                          planId,
                          widget.gymCost,
                          widget.dailyFoodBudget,
                        );
                      } catch (e) {
                        print('Erreur lors de la sauvegarde: $e');
                      }
                    }

                    // Also store a lightweight copy in SharedPreferences for quick reloads
                    await localStorage.addPlan({
                      'created_at': DateTime.now().toIso8601String(),
                      'current_weight': widget.currentWeight,
                      'target_weight': widget.targetWeight,
                      'training_weeks': widget.trainingWeeks,
                      'sessions_per_week': widget.sessionsPerWeek,
                      'gym_cost_monthly': widget.gymCost,
                      'daily_food_budget': widget.dailyFoodBudget,
                      // precomputed snapshot values for quick display
                      'total_gym_cost': _totalGymCost,
                      'total_food_cost': _totalFoodCost,
                      'total_program_cost': _totalProgramCost,
                      // capture generated advice/plan if available
                      'budget_advice': _budgetAdvice,
                      'meal_plan': _mealPlan,
                    });

                    // Show success message
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Your plan has been saved successfully!',
                          ),
                          backgroundColor: Color(0xFF2ECC71),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2ECC71),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Save Plan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black : Colors.grey,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Color(0xFF2ECC71) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseRow(
    String label,
    dynamic amount, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 17 : 15,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            amount == null ? '-' : '\$${(amount as num).toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 17 : 15,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.orange : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
