import 'package:flutter/material.dart';
import '../Entites/utilisateur.dart';
import 'user_dashboard_screen.dart';
import 'user_achievements_screen.dart';
import 'profil_screen.dart';
import '../l10n/app_localizations.dart';

class UserMainScreen extends StatefulWidget {
  final Utilisateur utilisateur;

  const UserMainScreen({Key? key, required this.utilisateur}) : super(key: key);

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
      UserAchievementsScreen(utilisateurId: widget.utilisateur.id!),
      ProfilScreen(utilisateur: widget.utilisateur),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.white,
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
                  AppLocalizations.of(context)?.navHome ?? 'Accueil',
                  0,
                  Colors.blue,
                ),
                _buildNavItem(
                  Icons.emoji_events,
                  AppLocalizations.of(context)?.navRewards ?? 'Récompenses',
                  1,
                  Colors.amber,
                ),
                _buildNavItem(
                  Icons.person,
                  AppLocalizations.of(context)?.navProfile ?? 'Profil',
                  2,
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
