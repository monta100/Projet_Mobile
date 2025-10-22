import 'package:flutter/material.dart';
import '../Entites/utilisateur.dart';
import 'home_page.dart';

class CoachHomeScreen extends StatefulWidget {
  final Utilisateur coach;
  const CoachHomeScreen({Key? key, required this.coach}) : super(key: key);

  @override
  State<CoachHomeScreen> createState() => _CoachHomeScreenState();
}

class _CoachHomeScreenState extends State<CoachHomeScreen> {
  @override
  Widget build(BuildContext context) {
    // Redirection vers la page d'accueil centrale avec choix de modules
    return HomePage(utilisateur: widget.coach);
  }
}