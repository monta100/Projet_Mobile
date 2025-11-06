import 'package:flutter/material.dart';
import '../Services/database_helper.dart';

// Palette de couleurs verte professionnelle
const Color primaryGreen = Color(0xFF2ECC71);
const Color darkGreen = Color(0xFF27AE60);
const Color lightGreen = Color(0xFFD5F4E6);
const Color accentGreen = Color(0xFF1ABC9C);

class ExpensesHistoryScreen extends StatefulWidget {
  const ExpensesHistoryScreen({super.key});

  @override
  State<ExpensesHistoryScreen> createState() => _ExpensesHistoryScreenState();
}

class _ExpensesHistoryScreenState extends State<ExpensesHistoryScreen> {
  late Future<List<Map<String, dynamic>>> _expensesFuture;

  @override
  void initState() {
    super.initState();
    _expensesFuture = DatabaseHelper().queryAll('expenses');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Dépenses'),
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
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _expensesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(darkGreen),
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Erreur: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              );
            }
            final expenses = snapshot.data ?? [];
            if (expenses.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox,
                      size: 80,
                      color: darkGreen.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune dépense enregistrée',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: expenses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final e = expenses[index];
                return _buildExpenseCard(e);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildExpenseCard(Map<String, dynamic> expense) {
    final gymCost = (expense['gym_subscription'] as num?)?.toDouble() ?? 0.0;
    final foodCost = (expense['food_costs'] as num?)?.toDouble() ?? 0.0;
    final supplementsCost =
        (expense['supplements_costs'] as num?)?.toDouble() ?? 0.0;
    final equipmentCost =
        (expense['equipment_costs'] as num?)?.toDouble() ?? 0.0;
    final otherCost = (expense['other_costs'] as num?)?.toDouble() ?? 0.0;
    final totalCost = (expense['total_cost'] as num?)?.toDouble() ?? 0.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, lightGreen.withValues(alpha: 0.3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: primaryGreen.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plan #${expense['plan_id'] ?? '-'}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dépenses détaillées',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: primaryGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'TOTAL',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${totalCost.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildExpenseBadge(
                      icon: Icons.fitness_center,
                      label: 'Salle',
                      value: gymCost,
                      color: const Color(0xFF3498DB),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildExpenseBadge(
                      icon: Icons.restaurant_menu,
                      label: 'Nourriture',
                      value: foodCost,
                      color: const Color(0xFF27AE60),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildExpenseBadge(
                      icon: Icons.shopping_bag,
                      label: 'Suppléments',
                      value: supplementsCost,
                      color: const Color(0xFF9B59B6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildExpenseBadge(
                      icon: Icons.handyman,
                      label: 'Équipement',
                      value: equipmentCost,
                      color: const Color(0xFFE74C3C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildExpenseBadge(
                icon: Icons.more_horiz,
                label: 'Autres',
                value: otherCost,
                color: primaryGreen,
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseBadge({
    required IconData icon,
    required String label,
    required double value,
    required Color color,
    bool fullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
