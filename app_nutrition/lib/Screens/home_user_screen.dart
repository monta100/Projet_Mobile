import 'package:flutter/material.dart';
import '../Entites/utilisateur.dart';
import 'home_page.dart';

/// Écran d'accueil pour les utilisateurs normaux
/// Redirige vers la page d'accueil centrale avec choix de modules
class HomeUserScreen extends StatelessWidget {
  final Utilisateur utilisateur;
  const HomeUserScreen({Key? key, required this.utilisateur}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return HomePage(utilisateur: utilisateur);
  }
}
