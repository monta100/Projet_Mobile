import 'package:flutter/material.dart';
import '../Entites/utilisateur.dart';
import 'user_main_screen.dart';

class HomeUserScreen extends StatelessWidget {
  final Utilisateur utilisateur;
  const HomeUserScreen({Key? key, required this.utilisateur}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return UserMainScreen(utilisateur: utilisateur);
  }
}
