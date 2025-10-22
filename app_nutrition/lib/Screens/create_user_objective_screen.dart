import 'package:flutter/material.dart';
import '../Entites/utilisateur.dart';
import '../Entites/user_objective.dart';
import '../Services/database_helper.dart';
import '../Services/user_service.dart';

class CreateUserObjectiveScreen extends StatefulWidget {
  final Utilisateur utilisateur;

  const CreateUserObjectiveScreen({
    Key? key,
    required this.utilisateur,
  }) : super(key: key);

  @override
  State<CreateUserObjectiveScreen> createState() => _CreateUserObjectiveScreenState();
}

class _CreateUserObjectiveScreenState extends State<CreateUserObjectiveScreen>
    with TickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  final UserService _userService = UserService();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final _formKey = GlobalKey<FormState>();
  final _poidsActuelController = TextEditingController();
  final _poidsCibleController = TextEditingController();
  final _tailleController = TextEditingController();
  final _ageController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedObjectiveType = '';
  String _selectedActivityLevel = '';
  int _selectedDuration = 12;
  int _selectedCoachId = 0;
  
  List<Utilisateur> _coaches = [];
  bool _isLoading = true;
  bool _isCreating = false;
  
  final List<Map<String, dynamic>> _objectiveTypes = [
    {
      'id': 'perte_poids',
      'title': 'Perte de poids',
      'description': 'Perdre du poids de manière saine et durable',
      'icon': '🔥',
      'color': Colors.orange,
    },
    {
      'id': 'prise_masse',
      'title': 'Prise de masse',
      'description': 'Gagner du muscle et de la masse corporelle',
      'icon': '💪',
      'color': Colors.blue,
    },
    {
      'id': 'tonification',
      'title': 'Tonification',
      'description': 'Affiner et tonifier votre silhouette',
      'icon': '✨',
      'color': Colors.purple,
    },
    {
      'id': 'endurance',
      'title': 'Amélioration endurance',
      'description': 'Développer votre capacité cardiovasculaire',
      'icon': '🏃',
      'color': Colors.green,
    },
    {
      'id': 'flexibilite',
      'title': 'Flexibilité',
      'description': 'Améliorer votre souplesse et mobilité',
      'icon': '🧘',
      'color': Colors.teal,
    },
    {
      'id': 'sante_generale',
      'title': 'Santé générale',
      'description': 'Maintenir une bonne santé globale',
      'icon': '❤️',
      'color': Colors.red,
    },
  ];
  
  final List<Map<String, dynamic>> _activityLevels = [
    {
      'id': 'sedentaire',
      'title': 'Sédentaire',
      'description': 'Peu ou pas d\'exercice',
      'icon': '🪑',
      'color': Colors.grey,
    },
    {
      'id': 'leger',
      'title': 'Léger',
      'description': '1-3 séances par semaine',
      'icon': '🚶',
      'color': Colors.blue,
    },
    {
      'id': 'modere',
      'title': 'Modéré',
      'description': '3-5 séances par semaine',
      'icon': '🏃',
      'color': Colors.green,
    },
    {
      'id': 'intense',
      'title': 'Intense',
      'description': '6-7 séances par semaine',
      'icon': '💪',
      'color': Colors.orange,
    },
    {
      'id': 'extreme',
      'title': 'Extrême',
      'description': 'Plus de 7 séances par semaine',
      'icon': '🔥',
      'color': Colors.red,
    },
  ];
  
  final List<Map<String, dynamic>> _durations = [
    {'weeks': 4, 'label': '1 mois'},
    {'weeks': 8, 'label': '2 mois'},
    {'weeks': 12, 'label': '3 mois'},
    {'weeks': 16, 'label': '4 mois'},
    {'weeks': 24, 'label': '6 mois'},
    {'weeks': 52, 'label': '1 an'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _loadCoaches();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _poidsActuelController.dispose();
    _poidsCibleController.dispose();
    _tailleController.dispose();
    _ageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCoaches() async {
    try {
      final allUsers = await _db.getAllUtilisateurs();
      final coaches = allUsers.where((user) => user.role.toLowerCase() == 'coach').toList();
      setState(() {
        _coaches = coaches;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des coaches: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Créer un Objectif'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 30),
                        _buildObjectiveTypeSection(),
                        const SizedBox(height: 30),
                        _buildPersonalInfoSection(),
                        const SizedBox(height: 30),
                        _buildActivityLevelSection(),
                        const SizedBox(height: 30),
                        _buildDurationSection(),
                        const SizedBox(height: 30),
                        _buildCoachSelectionSection(),
                        const SizedBox(height: 30),
                        _buildNotesSection(),
                        const SizedBox(height: 40),
                        _buildCreateButton(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade400,
            Colors.green.shade600,
            Colors.teal.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.track_changes,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Créer votre Objectif',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Définissez vos objectifs personnalisés',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildObjectiveTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type d\'Objectif',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: _objectiveTypes.length,
          itemBuilder: (context, index) {
            final objective = _objectiveTypes[index];
            final isSelected = _selectedObjectiveType == objective['id'];
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedObjectiveType = objective['id'];
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? objective['color'] : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? objective['color'] : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected 
                          ? objective['color'].withOpacity(0.3)
                          : Colors.grey.withOpacity(0.1),
                      blurRadius: isSelected ? 10 : 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      objective['icon'],
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      objective['title'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      objective['description'],
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? Colors.white70 : Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informations Personnelles',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _poidsActuelController,
                label: 'Poids actuel (kg)',
                icon: Icons.monitor_weight,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Poids requis';
                  }
                  final poids = double.tryParse(value);
                  if (poids == null || poids <= 0) {
                    return 'Poids invalide';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _poidsCibleController,
                label: 'Poids cible (kg)',
                icon: Icons.flag,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Poids cible requis';
                  }
                  final poids = double.tryParse(value);
                  if (poids == null || poids <= 0) {
                    return 'Poids invalide';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _tailleController,
                label: 'Taille (m)',
                icon: Icons.height,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Taille requise';
                  }
                  final taille = double.tryParse(value);
                  if (taille == null || taille <= 0) {
                    return 'Taille invalide';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _ageController,
                label: 'Âge',
                icon: Icons.cake,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Âge requis';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age <= 0) {
                    return 'Âge invalide';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildActivityLevelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Niveau d\'Activité',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._activityLevels.map((level) => _buildActivityLevelCard(level)).toList(),
      ],
    );
  }

  Widget _buildActivityLevelCard(Map<String, dynamic> level) {
    final isSelected = _selectedActivityLevel == level['id'];
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedActivityLevel = level['id'];
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? level['color'] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? level['color'] : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? level['color'].withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              level['icon'],
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level['title'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    level['description'],
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Durée de l\'Objectif',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                '$_selectedDuration semaines',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              Slider(
                value: _selectedDuration.toDouble(),
                min: 4,
                max: 52,
                divisions: 12,
                activeColor: Colors.green,
                inactiveColor: Colors.grey.shade300,
                onChanged: (value) {
                  setState(() {
                    _selectedDuration = value.round();
                  });
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '1 mois',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '1 an',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoachSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choisir votre Coach',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _coaches.isEmpty
            ? Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Aucun coach disponible',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            : Column(
                children: _coaches.map((coach) => _buildCoachCard(coach)).toList(),
              ),
      ],
    );
  }

  Widget _buildCoachCard(Utilisateur coach) {
    final isSelected = _selectedCoachId == coach.id;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCoachId = coach.id!;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? Colors.green.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: isSelected ? Colors.white : Colors.green,
              child: Text(
                coach.prenom[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.green : Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${coach.prenom} ${coach.nom}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    coach.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes (Optionnel)',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Ajoutez des notes ou commentaires',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isCreating ? null : _createObjective,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 5,
        ),
        child: _isCreating
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Créer l\'Objectif',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _createObjective() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedObjectiveType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un type d\'objectif')),
      );
      return;
    }
    
    if (_selectedActivityLevel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner votre niveau d\'activité')),
      );
      return;
    }
    
    if (_selectedCoachId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un coach')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final selectedObjective = _objectiveTypes.firstWhere(
        (obj) => obj['id'] == _selectedObjectiveType,
      );
      
      final selectedActivity = _activityLevels.firstWhere(
        (act) => act['id'] == _selectedActivityLevel,
      );

      final now = DateTime.now();
      final objective = UserObjective(
        utilisateurId: widget.utilisateur.id!,
        typeObjectif: selectedObjective['title'],
        description: selectedObjective['description'],
        poidsActuel: double.parse(_poidsActuelController.text),
        poidsCible: double.parse(_poidsCibleController.text),
        taille: double.parse(_tailleController.text),
        age: int.parse(_ageController.text),
        niveauActivite: selectedActivity['title'],
        dureeObjectif: _selectedDuration,
        coachId: _selectedCoachId,
        dateCreation: now,
        dateDebut: now,
        dateFin: now.add(Duration(days: _selectedDuration * 7)),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      await _db.insertUserObjective(objective);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Objectif créé avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isCreating = false);
    }
  }
}
