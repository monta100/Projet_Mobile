import 'package:flutter/material.dart';
import 'repas_list_screen.dart';
import 'recettes_global_screen.dart';
import 'assistance_ia_screen.dart';
import 'analyse_image_ia_screen.dart';

class RepasModuleMainScreen extends StatefulWidget {
  const RepasModuleMainScreen({Key? key}) : super(key: key);

  @override
  State<RepasModuleMainScreen> createState() => _RepasModuleMainScreenState();
}

class _RepasModuleMainScreenState extends State<RepasModuleMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    RepasListScreen(),
    RecettesGlobalScreen(),
    AssistanceIAScreen(),
    AnalyseImageIAScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.fastfood), label: 'Repas'),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Recettes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.support_agent),
            label: 'Assistance IA',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Analyse Image',
          ),
        ],
      ),
    );
  }
}
