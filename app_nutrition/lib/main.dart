// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'Widgets/floating_chat_bubble.dart';
import 'Services/navigation_service.dart';
import 'l10n/app_localizations.dart';
import 'Screens/login_screen.dart';
import 'Screens/register_screen.dart';
import 'Theme/app_colors.dart';
import 'Services/email_service.dart';
import 'Services/user_service.dart';
import 'Services/database_helper.dart';
import 'Services/theme_service.dart';
import 'Routs/app_routes.dart';
import 'Services/session_service.dart';
import 'Screens/home_user_screen.dart';

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
      logoUrl: localEnv['APP_LOGO_URL'] ?? localEnv['EMAIL_LOGO_URL'],
    );
    // Diagnostic (do not print password)
    // ignore: avoid_print
    print(
      'SMTP config loaded: host=$smtpHost port=$smtpPort user=$smtpUser ssl=$smtpSsl',
    );
  }

  // Initialize in-memory test data so the app has a default user for quick testing
  try {
    // Optional dev reset: if RESET_DB=true in .env, drop and recreate the local DB
    final resetDb = (localEnv['RESET_DB'] ?? 'false').toLowerCase() == 'true';
    if (resetDb) {
      // ignore: avoid_print
      print('RESET_DB=true detected — recreating local database...');
      await DatabaseHelper().recreateDatabase();
    }
    // Initialize database and test data
    await DatabaseHelper().initTestData();
  } catch (e) {
    // ignore: avoid_print
    print('Warning: failed to init test data: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  void changeThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
    ThemeService.setThemeMode(mode);
  }

  Future<void> _loadThemeMode() async {
    final themeMode = await ThemeService.getThemeMode();
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Enregistrer l'état pour permettre le changement de thème depuis d'autres écrans
    AppThemeNotifier.register(this);

    return MaterialApp(
      title: 'App Nutrition',
      debugShowCheckedModeBanner: false,
      navigatorKey: NavigationService.navKey,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      theme: ThemeService.getLightTheme(),
      darkTheme: ThemeService.getDarkTheme(),
      themeMode: _themeMode,
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) Positioned.fill(child: child),
            const _ChatBubbleOverlay(),
          ],
        );
      },
      home: const SessionGate(),
      routes: AppRoutes.getRoutes(),
    );
  }
}

// Classe statique pour permettre l'accès au changement de thème depuis n'importe où
class AppThemeNotifier {
  static _MyAppState? _appState;

  static void register(_MyAppState state) {
    _appState = state;
  }

  static void changeTheme(ThemeMode mode) {
    _appState?.changeThemeMode(mode);
  }
}

// FR uniquement: AppLanguageNotifier supprimé

// Overlay wrapper to keep the chat bubble on top of all routes
class _ChatBubbleOverlay extends StatelessWidget {
  const _ChatBubbleOverlay();
  @override
  Widget build(BuildContext context) => const Align(
    alignment: Alignment.bottomRight,
    child: Padding(
      padding: EdgeInsets.only(bottom: 90),
      child: FloatingChatBubble(),
    ),
  );
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.8),
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
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(
                        Icons.restaurant_menu,
                        size: 80,
                        color: isDark
                            ? AppColors.primaryColor
                            : Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Titre
                    Text(
                      'App Nutrition',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sous-titre
                    Text(
                      AppLocalizations.of(context)?.welcomeSubtitle ??
                          'Gérez vos objectifs nutritionnels\net suivez votre progression',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.9)
                            : Colors.white70,
                      ),
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
                          backgroundColor: isDark
                              ? AppColors.primaryColor
                              : (Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : Colors.white),
                          foregroundColor: isDark
                              ? Colors.white
                              : Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          AppLocalizations.of(context)?.loginButton ??
                              'Se connecter',
                          style: const TextStyle(
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
                          foregroundColor: isDark
                              ? AppColors.primaryColor
                              : Colors.white,
                          side: BorderSide(
                            color: isDark
                                ? AppColors.primaryColor
                                : (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : Colors.white),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)?.signUp ?? 'S\'inscrire',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Texte supplémentaire
                    Text(
                      AppLocalizations.of(context)?.welcomeTagline ??
                          'Commencez votre parcours\nvers une meilleure nutrition',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SessionGate extends StatelessWidget {
  const SessionGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: SessionService().getLoggedInUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user != null) {
          return HomeUserScreen(utilisateur: user);
        }
        return const WelcomeScreen();
      },
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
                        title: 'Entités complètes',
                        subtitle:
                            'Utilisateur, Objectif avec toutes leurs méthodes',
                      ),
                      const _FeatureItem(
                        icon: Icons.storage,
                        title: 'Base de données SQLite',
                        subtitle: 'Tables avec relations et méthodes CRUD',
                      ),
                      const _FeatureItem(
                        icon: Icons.business_center,
                        title: 'Services métier',
                        subtitle: 'UserService, ObjectifService',
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
                              try {
                                final us = UserService();
                                final u = await us.obtenirUtilisateurParEmail(
                                  user.toString(),
                                );
                                if (u != null && u.id != null) {
                                  final ok = await us.supprimerUtilisateur(
                                    u.id!,
                                  );
                                  if (ok) {
                                    // Navigate back to welcome
                                    // ignore: use_build_context_synchronously
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
