import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'Screens/session_screen.dart';
import 'Screens/programme_screen.dart';
import 'Screens/exercice_screen.dart';
import 'Screens/progression_screen.dart';
import 'Screens/recommandation_screen.dart';
import 'Screens/home_screen.dart'; // ✅ Nouvel écran météo + citation

const Color mainGreen = Color(0xFF2ECC71);
const Color darkGreen = Color(0xFF1E8449);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App Nutrition',
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: mainGreen),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: mainGreen,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 2,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      home: const HomeScreen(), // 🏠 Démarre sur ton accueil météo + citation
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  // ✅ Liste des pages
  final List<Widget> _pages = const [
    SessionScreen(),
    ProgrammeScreen(),
    ExerciceScreen(),
    ProgressionScreen(),
    RecommandationScreen(),
  ];

  final List<String> _titles = const [
    "Séances",
    "Programmes",
    "Exercices",
    "Progression",
    "Recommandations",
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _goToHome(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            tooltip: "Retour à l'accueil",
            onPressed: () => _goToHome(context),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 70,
            backgroundColor: Colors.white,
            indicatorColor: mainGreen.withOpacity(0.15),
            labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>(
              (states) => TextStyle(
                fontWeight: states.contains(MaterialState.selected)
                    ? FontWeight.bold
                    : FontWeight.w500,
                color: states.contains(MaterialState.selected)
                    ? mainGreen
                    : Colors.black54,
                fontSize: 13,
              ),
            ),
            iconTheme: MaterialStateProperty.resolveWith<IconThemeData>(
              (states) => IconThemeData(
                color: states.contains(MaterialState.selected)
                    ? mainGreen
                    : Colors.black45,
                size: states.contains(MaterialState.selected) ? 28 : 24,
              ),
            ),
          ),
          child: NavigationBar(
            animationDuration: const Duration(milliseconds: 450),
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.fitness_center_outlined),
                selectedIcon: Icon(Icons.fitness_center),
                label: 'Séances',
              ),
              NavigationDestination(
                icon: Icon(Icons.list_alt_outlined),
                selectedIcon: Icon(Icons.list_alt),
                label: 'Programmes',
              ),
              NavigationDestination(
                icon: Icon(Icons.sports_gymnastics_outlined),
                selectedIcon: Icon(Icons.sports_gymnastics),
                label: 'Exercices',
              ),
              NavigationDestination(
                icon: Icon(Icons.show_chart_outlined),
                selectedIcon: Icon(Icons.show_chart),
                label: 'Progression',
              ),
              NavigationDestination(
                icon: Icon(Icons.auto_awesome_outlined),
                selectedIcon: Icon(Icons.auto_awesome),
                label: 'Recommandations',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
