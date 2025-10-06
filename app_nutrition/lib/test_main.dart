import 'package:flutter/material.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test App Nutrition',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const TestHomeScreen(),
    );
  }
}

class TestHomeScreen extends StatelessWidget {
  const TestHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Nutrition - Test'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎉 Implémentation Réussie !',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Votre diagramme UML a été entièrement implémenté avec :',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    const _FeatureItem(
                      icon: Icons.person,
                      title: '3 Entités complètes',
                      subtitle:
                          'Utilisateur, Objectif, Rappel avec toutes leurs méthodes',
                    ),
                    const _FeatureItem(
                      icon: Icons.storage,
                      title: 'Base de données SQLite',
                      subtitle: 'Tables avec relations et méthodes CRUD',
                    ),
                    const _FeatureItem(
                      icon: Icons.business_center,
                      title: 'Services métier',
                      subtitle: 'UserService, ObjectifService, RappelService',
                    ),
                    const _FeatureItem(
                      icon: Icons.phone_android,
                      title: 'Écrans Flutter',
                      subtitle: 'Login, Register, Home avec navigation',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 Structure du Projet',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('📁 lib/Entites/ - Modèles de données'),
                    const Text('📁 lib/Services/ - Logique métier'),
                    const Text('📁 lib/Screens/ - Interface utilisateur'),
                    const Text('📁 lib/Routs/ - Navigation'),
                    const Text('📁 lib/Theme/ - Couleurs et styles'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Prochaines étapes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('1. Résoudre le problème de build Android'),
                    const Text('2. Tester la base de données'),
                    const Text('3. Implémenter les écrans détaillés'),
                    const Text('4. Ajouter des fonctionnalités avancées'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
