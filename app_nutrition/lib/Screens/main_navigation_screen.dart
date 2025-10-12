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
      color: theme_colors.AppColors.accentColor,
    ),
    NavigationItem(
      icon: Icons.public_outlined,
      activeIcon: Icons.public,
      label: 'Global',
      color: Colors.teal,
    ),
    NavigationItem(
      icon: Icons.smart_toy_outlined, // 🤖 icône de chatbot
      activeIcon: Icons.smart_toy,
      label: 'Assistant IA',
      color: Colors.deepOrange, // couleur qui ressort bien
    ),
    NavigationItem(
      icon: Icons.image_search_outlined, // 🖼️ icône pour VisionAI
      activeIcon: Icons.image_search,
      label: 'VisionAI', // Nom créatif pour l'analyse d'image
      color: Colors.purple,
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _navigationItems[_currentIndex].color,
        unselectedItemColor: theme_colors.AppColors.textColor.withOpacity(0.6),
        showUnselectedLabels: true,
        items: _navigationItems
            .map(
              (item) => BottomNavigationBarItem(
                icon: Icon(item.icon),
                activeIcon: Icon(item.activeIcon),
                label: item.label,
                backgroundColor: Colors.white,
              ),
            )
            .toList(),
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
