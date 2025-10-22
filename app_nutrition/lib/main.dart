import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'Screens/login_screen.dart';
import 'Screens/register_screen.dart';
import 'Services/email_service.dart';
import 'Services/user_service.dart';
import 'Services/database_helper.dart';
import 'Services/exercise_service.dart';
import 'Routs/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Try to load .env first via flutter_dotenv; if that fails (File not present
  // on host), try to load the .env from the asset bundle (useful when running
  // on device/emulator where .env is packaged as an asset).
  final localEnv = <String, String>{};
  try {
    await dotenv.load(fileName: '.env');
    localEnv.addAll(dotenv.env);
  } catch (e) {
    // ignore: avoid_print
    print('No local .env file found on host: $e — trying asset bundle...');
    try {
      final content = await rootBundle.loadString('.env');
      for (final raw in content.split(RegExp(r'\r?\n'))) {
        final line = raw.trim();
        if (line.isEmpty) continue;
        if (line.startsWith('#')) continue;
        final idx = line.indexOf('=');
        if (idx <= 0) continue;
        final k = line.substring(0, idx).trim();
        var v = line.substring(idx + 1).trim();
        if ((v.startsWith('"') && v.endsWith('"')) ||
            (v.startsWith("'") && v.endsWith("'"))) {
          v = v.substring(1, v.length - 1);
        }
        localEnv[k] = v;
      }
      // ignore: avoid_print
      print(
        'Loaded .env from asset bundle (keys: ${localEnv.keys.join(', ')})',
      );
    } catch (e2) {
      // ignore: avoid_print
      print('No .env in asset bundle either: $e2');
    }
  }

  // Configure EmailService if we have the required keys
  final smtpHost = localEnv['SMTP_HOST'];
  final smtpPort = int.tryParse(localEnv['SMTP_PORT'] ?? '');
  final smtpUser = localEnv['SMTP_USER'];
  final smtpPass = localEnv['SMTP_PASS'];
  final smtpSsl = (localEnv['SMTP_SSL'] ?? 'false').toLowerCase() == 'true';

  if (smtpHost != null &&
      smtpPort != null &&
      smtpUser != null &&
      smtpPass != null) {
    UserService.defaultEmailService = EmailService(
      smtpHost: smtpHost,
      smtpPort: smtpPort,
      username: smtpUser,
      password: smtpPass,
      useSsl: smtpSsl,
    );
    // Diagnostic (do not print password)
    // ignore: avoid_print
    print(
      'SMTP config loaded: host=$smtpHost port=$smtpPort user=$smtpUser ssl=$smtpSsl',
    );
  }

  // Initialize in-memory test data so the app has a default user for quick testing
  try {
    // Initialize database and test data
    await DatabaseHelper().initTestData();
    // Initialize demo exercises
    await ExerciseService().initializeDemoExercises();
  } catch (e) {
    // ignore: avoid_print
    print('Warning: failed to init test data: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Nutrition',
      debugShowCheckedModeBanner: false,
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

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(
                        Icons.restaurant_menu,
                        size: 80,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Titre
                    const Text(
                      'App Nutrition',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sous-titre
                    const Text(
                      'Gérez vos objectifs nutritionnels\net vos rappels quotidiens',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                    const SizedBox(height: 64),

                    // Bouton Connexion
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Se Connecter',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bouton Inscription
                    SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'S\'inscrire',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Texte supplémentaire
                    const Text(
                      'Commencez votre parcours\nvers une meilleure nutrition',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ),
          ),
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    // args is expected to be a Utilisateur when navigating after login
    final user = args is Map && args['email'] != null
        ? args['email'] as String?
        : args as dynamic;
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Nutrition - Projet UML'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
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
              // Delete account button (visible when user is provided)
              if (user != null)
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Supprimer le compte',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(color: Colors.red),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Confirmer la suppression'),
                                content: const Text(
                                  'Voulez-vous vraiment supprimer votre compte ? Cette action est irréversible.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Annuler'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text('Supprimer'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              // We don't have typed user object here; try to find by email
                              try {
                                // If UserService was updated to return Utilisateur by email, use it; else, iterate
                                final us = UserService();
                                await us.authentifier(user.toString(), '');
                                // If authentifier requires password, try to lookup by database directly
                                // Fallback: attempt to find by email through DatabaseHelper
                                final db = DatabaseHelper();
                                final u = await db.getUtilisateurByEmail(
                                  user.toString(),
                                );
                                if (u != null) {
                                  final res = await db.deleteUtilisateur(u.id!);
                                  if (res > 0) {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const WelcomeScreen(),
                                      ),
                                      (r) => false,
                                    );
                                  }
                                }
                              } catch (e) {
                                // ignore: avoid_print
                                print('Erreur suppression compte: $e');
                              }
                            }
                          },
                          child: const Text('Supprimer mon compte'),
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
                      const Text('1. Tester les écrans de connexion'),
                      const Text('2. Valider la base de données'),
                      const Text('3. Implémenter les écrans détaillés'),
                      const Text('4. Ajouter des fonctionnalités avancées'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Boutons d'action
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🚀 Actions disponibles',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // TODO: Naviguer vers l'écran de connexion
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Écran de connexion - À implémenter',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.login),
                              label: const Text('Connexion'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // TODO: Naviguer vers l'écran d'inscription
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Écran d\'inscription - À implémenter',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.person_add),
                              label: const Text('Inscription'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Naviguer vers l'écran de test de base de données
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Test base de données - À implémenter',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.storage),
                          label: const Text('Tester la base de données'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
