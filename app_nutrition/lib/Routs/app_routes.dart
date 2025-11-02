import 'package:flutter/material.dart';
import '../Screens/login_screen.dart';
import '../Screens/register_screen.dart';
import '../Screens/home_screen.dart';
import '../Screens/home_user_screen.dart';
import '../Screens/nouveau_objectif_screen.dart';
import '../Screens/mes_objectifs_screen.dart';
import '../Screens/profil_screen.dart';
import '../Screens/test_database_screen.dart';
import '../Entites/utilisateur.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String profil = '/profil';
  static const String objectifs = '/objectifs';
  static const String objectifsNouveau = '/objectifs/nouveau';
  static const String testDatabase = '/test-database';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      home: (context) {
        final utilisateur =
            ModalRoute.of(context)!.settings.arguments as Utilisateur?;
        if (utilisateur != null) {
          return HomeUserScreen(utilisateur: utilisateur);
        }
        // If no user provided, redirect to login
        return const LoginScreen();
      },
      // Routes pour objectifs
      profil: (context) {
        final utilisateur =
            ModalRoute.of(context)!.settings.arguments as Utilisateur?;
        if (utilisateur != null) return ProfilScreen(utilisateur: utilisateur);
        return const LoginScreen();
      },
      objectifs: (context) {
        final utilisateur =
            ModalRoute.of(context)!.settings.arguments as Utilisateur?;
        if (utilisateur != null)
          return MesObjectifsScreen(utilisateur: utilisateur);
        return const LoginScreen();
      },
      objectifsNouveau: (context) {
        final arg = ModalRoute.of(context)!.settings.arguments;
        // If a simple Utilisateur is passed, allow (user creating own objective)
        if (arg is Utilisateur) {
          return NouveauObjectifScreen(utilisateur: arg);
        }
        // If a map with requester/target is passed, only allow when requester == target
        if (arg is Map) {
          final target = arg['target'] as Utilisateur?;
          final requester = arg['requester'] as Utilisateur?;
          if (target != null && requester != null) {
            if (target.id == requester.id) {
              return NouveauObjectifScreen(utilisateur: target);
            }
            // Deny coach creation of objective for another user
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Accès refusé: Seul l\'utilisateur peut créer ses objectifs.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            );
          }
        }
        // Si pas d'utilisateur, rediriger vers login
        return const LoginScreen();
      },
      testDatabase: (context) => const TestDatabaseScreen(),
    };
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (context) => const LoginScreen());

      case register:
        return MaterialPageRoute(builder: (context) => const RegisterScreen());

      case home:
        final utilisateur = settings.arguments as Utilisateur?;
        if (utilisateur != null) {
          return MaterialPageRoute(
            builder: (context) => HomeUserScreen(utilisateur: utilisateur),
          );
        }
        // Redirect to login if no user
        return MaterialPageRoute(builder: (context) => const LoginScreen());

      case profil:
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(child: Text('Écran Profil - À implémenter')),
          ),
        );

      case objectifs:
        final utilisateur = settings.arguments as Utilisateur?;
        if (utilisateur != null) {
          return MaterialPageRoute(
            builder: (context) => MesObjectifsScreen(utilisateur: utilisateur),
          );
        }
        return MaterialPageRoute(builder: (context) => const LoginScreen());

      case objectifsNouveau:
        final arg = settings.arguments;
        if (arg is Utilisateur) {
          return MaterialPageRoute(
            builder: (context) => NouveauObjectifScreen(utilisateur: arg),
          );
        }
        if (arg is Map) {
          final target = arg['target'] as Utilisateur?;
          final requester = arg['requester'] as Utilisateur?;
          if (target != null && requester != null) {
            if (target.id == requester.id) {
              return MaterialPageRoute(
                builder: (context) =>
                    NouveauObjectifScreen(utilisateur: target),
              );
            }
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Accès refusé: Seul l\'utilisateur peut créer ses objectifs.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            );
          }
        }
        return MaterialPageRoute(builder: (context) => const LoginScreen());

      case testDatabase:
        return MaterialPageRoute(
          builder: (context) => const TestDatabaseScreen(),
        );

      default:
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(child: Text('Route inconnue: ${settings.name}')),
          ),
        );
    }
  }
}

class RouteGuard {
  /// Vérifie si l'utilisateur est connecté avant d'accéder à une route protégée
  static bool isAuthenticated(BuildContext context) {
    // TODO: Implémenter la logique d'authentification
    // Par exemple, vérifier si un token est stocké en local
    return false;
  }

  /// Redirige vers la page de connexion si non authentifié
  static void redirectToLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }
}
