import 'package:flutter/material.dart';
import 'Screens/session_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color mainGreen = Color(0xFF2ECC71); // 💚 Vert principal

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Suivi des Activités Physiques',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: mainGreen),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Accueil - App Nutrition'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    SessionScreen(), // 📋 Page des séances
    Placeholder(),   // Tu pourras remplacer plus tard par ProgrammeScreen()
    Placeholder(),   // Tu pourras remplacer plus tard par ExerciceScreen()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color mainGreen = Color(0xFF2ECC71);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: mainGreen,
        centerTitle: true,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: mainGreen,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Séances',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Programmes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timer),
            label: 'Exercices',
          ),
        ],
      ),
    );
  }
}
