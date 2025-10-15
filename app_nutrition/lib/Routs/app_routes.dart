import 'package:flutter/material.dart';
import '../Screens/login_screen.dart';
import '../Screens/register_screen.dart';
import '../Screens/home_screen.dart';
import '../Screens/nouveau_objectif_screen.dart';
import '../Screens/mes_objectifs_screen.dart';
import '../Screens/mes_rappels_screen.dart';
import '../Screens/nouveau_rappel_screen.dart';
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
  static const String rappels = '/rappels';
  static const String rappelsNouveau = '/rappels/nouveau';
  static const String testDatabase = '/test-database';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      home: (context) {
        // Restore original behavior: always show the classic HomeScreen
        final utilisateur =
            ModalRoute.of(context)!.settings.arguments as Utilisateur?;
        if (utilisateur != null) return HomeScreen(utilisateur: utilisateur);
        // If no user provided, redirect to login
        return const LoginScreen();
      },
      // Routes pour objectifs et rappels
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
        final utilisateur =
            ModalRoute.of(context)!.settings.arguments as Utilisateur?;
        if (utilisateur != null) {
          return NouveauObjectifScreen(utilisateur: utilisateur);
        }
        // Si pas d'utilisateur, rediriger vers login
        return const LoginScreen();
      },
      rappels: (context) {
        final utilisateur =
            ModalRoute.of(context)!.settings.arguments as Utilisateur?;
        if (utilisateur != null)
          return MesRappelsScreen(utilisateur: utilisateur);
        return const LoginScreen();
      },
      rappelsNouveau: (context) {
        final utilisateur =
            ModalRoute.of(context)!.settings.arguments as Utilisateur?;
        if (utilisateur != null)
          return NouveauRappelScreen(utilisateur: utilisateur);
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
          // Always use the original HomeScreen for the main route
          return MaterialPageRoute(
            builder: (context) => HomeScreen(utilisateur: utilisateur),
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
        final utilisateur = settings.arguments as Utilisateur?;
        if (utilisateur != null) {
          return MaterialPageRoute(
            builder: (context) =>
                NouveauObjectifScreen(utilisateur: utilisateur),
          );
        }
        return MaterialPageRoute(builder: (context) => const LoginScreen());

      case rappels:
        final utilisateur = settings.arguments as Utilisateur?;
        if (utilisateur != null) {
          return MaterialPageRoute(
            builder: (context) => MesRappelsScreen(utilisateur: utilisateur),
          );
        }
        return MaterialPageRoute(builder: (context) => const LoginScreen());

      case rappelsNouveau:
        final utilisateur = settings.arguments as Utilisateur?;
        if (utilisateur != null) {
          return MaterialPageRoute(
            builder: (context) => NouveauRappelScreen(utilisateur: utilisateur),
          );
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
