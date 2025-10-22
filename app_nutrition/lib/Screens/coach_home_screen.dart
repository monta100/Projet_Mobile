import 'dart:io';
import 'package:flutter/material.dart';
import '../Entites/utilisateur.dart';
import '../Services/user_service.dart';
import '../Routs/app_routes.dart';
import '../Services/message_service.dart';
import '../Entites/message.dart';
import 'chat_screen.dart';
import 'coach_plans_screen.dart';
import 'exercise_library_screen.dart';
import 'coach_progress_tracking_screen.dart';
import 'coach_main_screen.dart';

class CoachHomeScreen extends StatefulWidget {
  final Utilisateur coach;
  const CoachHomeScreen({Key? key, required this.coach}) : super(key: key);

  @override
  State<CoachHomeScreen> createState() => _CoachHomeScreenState();
}

class _CoachHomeScreenState extends State<CoachHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return CoachMainScreen(coach: widget.coach);
  }
}