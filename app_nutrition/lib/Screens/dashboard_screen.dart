import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

const Color mainGreen = Color(0xFF2ECC71);

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              const Text(
                "Tableau de bord",
                style: TextStyle(
                  color: mainGreen,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Vue globale de vos performances sportives 🏋️‍♀️",
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),

              // 🟢 Résumé des stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  _StatCard(label: "Calories", value: "1450", unit: "kcal"),
                  _StatCard(label: "Durée", value: "210", unit: "min"),
                  _StatCard(label: "Séances", value: "12", unit: "total"),
                ],
              ),
              const SizedBox(height: 30),

              // 📈 Graphique d'évolution
              Container(
                height: 250,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: LineChart(
                  LineChartData(
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        color: mainGreen,
                        barWidth: 4,
                        belowBarData: BarAreaData(
                          show: true,
                          color: mainGreen.withOpacity(0.2),
                        ),
                        spots: const [
                          FlSpot(0, 1.5),
                          FlSpot(1, 2.5),
                          FlSpot(2, 1.8),
                          FlSpot(3, 3.4),
                          FlSpot(4, 2.9),
                          FlSpot(5, 3.8),
                          FlSpot(6, 4.2),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 🔥 Objectif du mois
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: mainGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "🎯 Objectif du mois : 5000 kcal brûlées et 20 séances réussies",
                  style: TextStyle(
                    color: mainGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🔸 Widget pour les petites cartes de stats
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mainGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: mainGreen,
            ),
          ),
          Text(unit,
              style: const TextStyle(
                  fontSize: 13, color: Colors.black54, height: 1.2)),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
                fontWeight: FontWeight.w500, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
