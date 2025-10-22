import 'package:flutter/material.dart';

class AppColors {
  // Couleurs principales - Palette de verts harmonieuse
  static const Color primaryColor = Color(0xFF43A047); // Vert principal - élégant
  static const Color primaryDark = Color(0xFF2E7D32); // Vert foncé - profond
  static const Color primaryLight = Color(0xFF66BB6A); // Vert clair - doux
  
  static const Color secondaryColor = Color(0xFF81C784); // Vert secondaire - frais
  static const Color secondaryLight = Color(0xFFA5D6A7); // Vert très clair - pastel
  
  // Couleur d'accent - Vert vif pour les éléments importants
  static const Color accentColor = Color(0xFF4CAF50); // Vert accent - vibrant
  static const Color accentLight = Color(0xFF8BC34A); // Vert lime - énergique
  
  // Couleurs de fond et surfaces
  static const Color backgroundColor = Color(0xFFF1F8F4); // Fond vert très pâle
  static const Color surfaceColor = Color(0xFFFFFFFF); // Blanc pur
  static const Color cardColor = Color(0xFFFAFDFB); // Blanc avec nuance verte
  
  // Couleurs de texte
  static const Color textColor = Color(0xFF1B5E20); // Vert très foncé pour le texte
  static const Color textSecondary = Color(0xFF558B2F); // Vert moyen pour texte secondaire
  static const Color textLight = Color(0xFF7CB342); // Vert clair pour texte léger
  
  // Couleurs utilitaires avec nuances vertes
  static const Color successColor = Color(0xFF66BB6A); // Vert succès
  static const Color warningColor = Color(0xFF9CCC65); // Vert-jaune avertissement
  static const Color errorColor = Color(0xFFEF5350); // Rouge erreur
  static const Color infoColor = Color(0xFF81C784); // Vert info
  
  // Dégradés verts prédéfinis
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient lightGradient = LinearGradient(
    colors: [primaryLight, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentColor, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
