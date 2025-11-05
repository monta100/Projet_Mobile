import 'package:flutter/material.dart';
import 'exercice_screen.dart';
import 'session_screen.dart';
import 'progression_screen.dart';
import 'recommandation_screen.dart';
import 'programme_screen.dart';
import 'activities_home_screen.dart';
import '../Theme/app_colors.dart' as theme_colors;

class PhysicalActivitiesMainScreen extends StatefulWidget {
  const PhysicalActivitiesMainScreen({super.key});

  @override
  State<PhysicalActivitiesMainScreen> createState() =>
      _PhysicalActivitiesMainScreenState();
}

class _PhysicalActivitiesMainScreenState
    extends State<PhysicalActivitiesMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ExerciceScreen(),
    const SessionScreen(),
    const ProgressionScreen(),
    const ProgrammeScreen(),
    const RecommandationScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.white,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  Icons.fitness_center,
                  'Exercices',
                  0,
                  Colors.blue,
                ),
                _buildNavItem(Icons.timer, 'Sessions', 1, Colors.orange),
                _buildNavItem(
                  Icons.trending_up,
                  'Progression',
                  2,
                  Colors.green,
                ),
                _buildNavItem(
                  Icons.calendar_month,
                  'Programmes',
                  3,
                  Colors.teal,
                ),
                _buildNavItem(Icons.lightbulb, 'Conseils', 4, Colors.purple),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, Color color) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? color
                  : (Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey.shade600),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? color
                    : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
