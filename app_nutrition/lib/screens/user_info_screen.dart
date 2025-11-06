import 'package:flutter/material.dart';
import 'training_plan_screen.dart';
import 'saved_plans_screen.dart';

const Color primaryGreen = Color(0xFF2ECC71);
const Color darkGreen = Color(0xFF27AE60);
const Color lightGreen = Color(0xFFD5F4E6);
const Color accentGreen = Color(0xFF1ABC9C);

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  double? currentWeight;
  double? targetWeight;
  double? height;
  int? age;
  String? gender;
  String? activityLevel;
  late AnimationController _animationController;

  final List<String> activityLevels = [
    'Sédentaire',
    'Léger',
    'Modéré',
    'Très Actif',
    'Extra Actif',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vos Informations'),
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [lightGreen, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Remplissez vos informations',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pour créer votre plan personnalisé',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 32),
                  _buildInputField(
                    label: 'Poids actuel (kg)',
                    icon: Icons.scale,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre poids';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      currentWeight = double.tryParse(value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    label: 'Poids cible (kg)',
                    icon: Icons.flag,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre poids cible';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      targetWeight = double.tryParse(value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    label: 'Taille (cm)',
                    icon: Icons.straighten,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre taille';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      height = double.tryParse(value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    label: 'Âge',
                    icon: Icons.cake,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre âge';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      age = int.tryParse(value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    label: 'Sexe',
                    icon: Icons.person,
                    items: ['Homme', 'Femme', 'Autre'],
                    onChanged: (value) {
                      setState(() {
                        gender = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Veuillez sélectionner votre sexe';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    label: 'Niveau d\'activité',
                    icon: Icons.fitness_center,
                    items: activityLevels,
                    onChanged: (value) {
                      setState(() {
                        activityLevel = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Veuillez sélectionner votre niveau d\'activité';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TrainingPlanScreen(
                              currentWeight: currentWeight!,
                              targetWeight: targetWeight!,
                              height: height!,
                              age: age!,
                              gender: gender!,
                              activityLevel: activityLevel!,
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 6,
                      shadowColor: primaryGreen.withOpacity(0.4),
                    ),
                    child: const Text(
                      'Suivant',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SavedPlansScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('Voir mes plans'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryGreen,
                      side: const BorderSide(color: primaryGreen, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
    required String? Function(String?)? validator,
    required void Function(String?)? onSaved,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryGreen),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: primaryGreen.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2.5),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        labelStyle: const TextStyle(color: darkGreen),
        floatingLabelStyle: const TextStyle(color: primaryGreen),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
      keyboardType: keyboardType,
      validator: validator,
      onSaved: onSaved,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?)? onChanged,
    required String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryGreen),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: primaryGreen.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2.5),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        labelStyle: const TextStyle(color: darkGreen),
        floatingLabelStyle: const TextStyle(color: primaryGreen),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
      items: items
          .map((label) => DropdownMenuItem(value: label, child: Text(label)))
          .toList(),
      onChanged: onChanged,
      validator: validator,
      icon: const Icon(Icons.expand_more, color: primaryGreen),
    );
  }
}
