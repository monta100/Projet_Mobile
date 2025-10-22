// ignore_for_file: use_super_parameters, library_private_types_in_public_api, deprecated_member_use

import 'package:flutter/material.dart';
import '../Theme/app_colors.dart' as theme_colors;
import 'repas_list_screen.dart';
import 'my_recettes_screen.dart';
import 'recettes_global_screen.dart';
import 'chatbot_repas_screen.dart';
import 'analyze_image_test.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  // Suppression des contrôleurs inutiles

  final List<Widget> _screens = [
    const RepasListScreen(),
    const MyRecettesScreen(),
    const RecettesGlobalScreen(),
    const ChatbotRepasScreen(),
    AnalyzeImageTest(),
  ];

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.restaurant,
      activeIcon: Icons.restaurant,
      label: 'Repas',
      color: theme_colors.AppColors.primaryColor,
    ),
    NavigationItem(
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book,
      label: 'Mes Recettes',
      color: theme_colors.AppColors.primaryDark,
    ),
    NavigationItem(
      icon: Icons.public_outlined,
      activeIcon: Icons.public,
      label: 'Global',
      color: theme_colors.AppColors.secondaryColor,
    ),
    NavigationItem(
      icon: Icons.smart_toy_outlined, // 🤖 icône de chatbot
      activeIcon: Icons.smart_toy,
      label: 'Assistant IA',
      color: theme_colors.AppColors.accentColor,
    ),
    NavigationItem(
      icon: Icons.image_search_outlined, // 🖼️ icône pour VisionAI
      activeIcon: Icons.image_search,
      label: 'VisionAI',
      color: theme_colors.AppColors.accentLight,
    ),
  ];

  @override
  void initState() {
    super.initState();
  }

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
              color: theme_colors.AppColors.primaryColor.withOpacity(0.1),
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
            unselectedItemColor: theme_colors.AppColors.textSecondary.withOpacity(0.5),
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

  // Suppression des méthodes custom de barre de navigation
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
