import 'package:flutter/material.dart';
import '../Theme/app_colors.dart';
import 'programme_screen.dart';
import 'exercice_screen.dart';
import 'session_screen.dart';
import 'progression_screen.dart';
import 'recommandation_screen.dart';
import '../Entites/utilisateur.dart';

/// 💪 Module Activité Physique - Navigation principale
class ActivityNavigationScreen extends StatefulWidget {
  final Utilisateur utilisateur;

  const ActivityNavigationScreen({Key? key, required this.utilisateur}) : super(key: key);

  @override
  _ActivityNavigationScreenState createState() => _ActivityNavigationScreenState();
}

class _ActivityNavigationScreenState extends State<ActivityNavigationScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const ProgrammeScreen(),
      const ExerciceScreen(),
      const SessionScreen(),
      const ProgressionScreen(),
      const RecommandationScreen(),
    ];
  }

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
      label: 'Plans',
      color: Color(0xFF2196F3), // Bleu
    ),
    NavigationItem(
      icon: Icons.fitness_center_outlined,
      activeIcon: Icons.fitness_center,
      label: 'Exercices',
      color: Color(0xFFFF9800), // Orange
    ),
    NavigationItem(
      icon: Icons.sports_outlined,
      activeIcon: Icons.sports,
      label: 'Séances',
      color: Color(0xFF4CAF50), // Vert
    ),
    NavigationItem(
      icon: Icons.show_chart_outlined,
      activeIcon: Icons.show_chart,
      label: 'Progrès',
      color: Color(0xFF9C27B0), // Violet
    ),
    NavigationItem(
      icon: Icons.lightbulb_outline,
      activeIcon: Icons.lightbulb,
      label: 'Conseils',
      color: Color(0xFFFFC107), // Doré
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: _navigationItems[_currentIndex].color,
            unselectedItemColor: Colors.grey.shade600,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            elevation: 0,
            items: _navigationItems
                .map(
                  (item) => BottomNavigationBarItem(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.icon, size: 24),
                    ),
                    activeIcon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.activeIcon, size: 26),
                    ),
                    label: item.label,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}

