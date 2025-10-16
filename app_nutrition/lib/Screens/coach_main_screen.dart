import 'package:flutter/material.dart';
import '../Entites/utilisateur.dart';
import 'coach_dashboard_screen.dart';
import 'coach_clients_screen.dart';
import 'coach_objectives_screen.dart';
import 'coach_programs_screen.dart';
import 'coach_analytics_screen.dart';
import 'profil_screen.dart';

class CoachMainScreen extends StatefulWidget {
  final Utilisateur coach;

  const CoachMainScreen({
    Key? key,
    required this.coach,
  }) : super(key: key);

  @override
  State<CoachMainScreen> createState() => _CoachMainScreenState();
}

class _CoachMainScreenState extends State<CoachMainScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      CoachDashboardScreen(coach: widget.coach),
      CoachClientsScreen(coach: widget.coach),
      CoachObjectivesScreen(coach: widget.coach),
      CoachProgramsScreen(coach: widget.coach),
      CoachAnalyticsScreen(coach: widget.coach),
      ProfilScreen(utilisateur: widget.coach),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  Icons.dashboard,
                  'Tableau',
                  0,
                  Colors.blue,
                ),
                _buildNavItem(
                  Icons.people,
                  'Clients',
                  1,
                  Colors.green,
                ),
                _buildNavItem(
                  Icons.track_changes,
                  'Objectifs',
                  2,
                  Colors.orange,
                ),
                _buildNavItem(
                  Icons.fitness_center,
                  'Programmes',
                  3,
                  Colors.purple,
                ),
                _buildNavItem(
                  Icons.analytics,
                  'Analyses',
                  4,
                  Colors.teal,
                ),
                _buildNavItem(
                  Icons.person,
                  'Profil',
                  5,
                  Colors.grey,
                ),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey.shade600,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
