import 'package:flutter/material.dart';
import 'dart:io';
import '../Entites/utilisateur.dart';
import '../Routs/app_routes.dart';
import 'user_exercise_programs_screen.dart';
import 'user_dashboard_screen.dart';
import 'user_achievements_screen.dart';
import 'user_nutrition_tracking_screen.dart';
import 'user_reminders_screen.dart';
import 'user_main_screen.dart';
import '../Services/exercise_service.dart';

class HomeUserScreen extends StatelessWidget {
  final Utilisateur utilisateur;
  const HomeUserScreen({Key? key, required this.utilisateur}) : super(key: key);

  Widget _buildSmallAvatar(BuildContext context) {
    if (utilisateur.avatarPath != null && utilisateur.avatarPath!.isNotEmpty) {
      final file = File(utilisateur.avatarPath!);
      if (file.existsSync())
        return CircleAvatar(radius: 18, backgroundImage: FileImage(file));
    }
    final initials =
        (utilisateur.avatarInitials != null &&
            utilisateur.avatarInitials!.isNotEmpty)
        ? utilisateur.avatarInitials!.toUpperCase()
        : ((utilisateur.prenom.isNotEmpty ? utilisateur.prenom[0] : '') +
                  (utilisateur.nom.isNotEmpty ? utilisateur.nom[0] : ''))
              .toUpperCase();
    return CircleAvatar(
      radius: 18,
      child: Text(initials, style: const TextStyle(color: Colors.white)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Accès direct aux nouvelles fonctionnalités avec navigation par onglets
    return UserMainScreen(utilisateur: utilisateur);
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<dynamic>> _loadUserProgramsData() async {
    try {
      final exerciseService = ExerciseService();
      final userPlans = await exerciseService.getUserPlans(utilisateur.id!);
      return [userPlans.isNotEmpty, userPlans.length];
    } catch (e) {
      return [false, 0];
    }
  }
}
