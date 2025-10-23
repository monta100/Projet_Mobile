import 'package:flutter/material.dart';
import '../Entites/utilisateur.dart';
import 'user_dashboard_screen.dart';
import 'user_achievements_screen.dart';
import 'user_nutrition_tracking_screen.dart';
import 'user_reminders_screen.dart';
import 'user_progress_dashboard_screen.dart';
import 'profil_screen.dart';

class UserMainScreen extends StatefulWidget {
  final Utilisateur utilisateur;

  const UserMainScreen({
    Key? key,
    required this.utilisateur,
  }) : super(key: key);

  @override
  State<UserMainScreen> createState() => _UserMainScreenState();
}

class _UserMainScreenState extends State<UserMainScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      UserDashboardScreen(utilisateur: widget.utilisateur),
      UserProgressDashboardScreen(utilisateur: widget.utilisateur),
      UserAchievementsScreen(utilisateurId: widget.utilisateur.id!),
      UserNutritionTrackingScreen(utilisateur: widget.utilisateur),
      UserRemindersScreen(utilisateur: widget.utilisateur),
      ProfilScreen(utilisateur: widget.utilisateur),
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
                  'Accueil',
                  0,
                  Colors.blue,
                ),
                _buildNavItem(
                  Icons.trending_up,
                  'Progression',
                  1,
                  Colors.purple,
                ),
                _buildNavItem(
                  Icons.emoji_events,
                  'Récompenses',
                  2,
                  Colors.amber,
                ),
                _buildNavItem(
                  Icons.restaurant_menu,
                  'Nutrition',
                  3,
                  Colors.green,
                ),
                _buildNavItem(
                  Icons.notifications,
                  'Rappels',
                  4,
                  Colors.indigo,
                ),
                _buildNavItem(
                  Icons.person,
                  'Profil',
                  5,
                  Colors.teal,
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
              color: isSelected ? color : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
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
