import 'package:flutter/material.dart';
import 'expenses_history_screen.dart';

// Palette de couleurs verte professionnelle
const Color primaryGreen = Color(0xFF2ECC71);
const Color darkGreen = Color(0xFF27AE60);
const Color lightGreen = Color(0xFFD5F4E6);
const Color accentGreen = Color(0xFF1ABC9C);

class ExpensesTrackerModuleScreen extends StatelessWidget {
  const ExpensesTrackerModuleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi des Dépenses'),
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Suivez toutes vos dépenses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Carte : Historique des dépenses
              _buildTrackerCard(
                context,
                icon: Icons.receipt_long,
                title: 'Historique des Dépenses',
                subtitle:
                    'Consultez toutes vos dépenses d\'entraînement et nutrition',
                color: primaryGreen,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ExpensesHistoryScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Conteneur d'informations
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Catégories de Dépenses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildExpenseCategory(
                      icon: Icons.fitness_center,
                      label: 'Abonnement Salle',
                      color: const Color(0xFF3498DB),
                    ),
                    const SizedBox(height: 12),
                    _buildExpenseCategory(
                      icon: Icons.restaurant_menu,
                      label: 'Nourriture & Nutrition',
                      color: const Color(0xFF27AE60),
                    ),
                    const SizedBox(height: 12),
                    _buildExpenseCategory(
                      icon: Icons.shopping_bag,
                      label: 'Suppléments',
                      color: const Color(0xFF9B59B6),
                    ),
                    const SizedBox(height: 12),
                    _buildExpenseCategory(
                      icon: Icons.handyman,
                      label: 'Équipement',
                      color: const Color(0xFFE74C3C),
                    ),
                    const SizedBox(height: 12),
                    _buildExpenseCategory(
                      icon: Icons.more_horiz,
                      label: 'Autres Dépenses',
                      color: primaryGreen,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackerCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 40),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: color, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseCategory({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }
}
