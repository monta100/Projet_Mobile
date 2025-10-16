import 'package:flutter/material.dart';
import '../Entites/utilisateur.dart';
import '../Entites/objectif.dart';
import '../Services/database_helper.dart';
import '../Services/objectif_service.dart';

class UserNutritionTrackingScreen extends StatefulWidget {
  final Utilisateur utilisateur;

  const UserNutritionTrackingScreen({
    Key? key,
    required this.utilisateur,
  }) : super(key: key);

  @override
  State<UserNutritionTrackingScreen> createState() => _UserNutritionTrackingScreenState();
}

class _UserNutritionTrackingScreenState extends State<UserNutritionTrackingScreen>
    with TickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  final ObjectifService _objectifService = ObjectifService();
  
  List<Objectif> _objectifs = [];
  bool _isLoading = true;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    
    _loadObjectifs();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadObjectifs() async {
    setState(() => _isLoading = true);
    try {
      final objectifs = await _db.getObjectifsByUtilisateur(widget.utilisateur.id!);
      setState(() {
        _objectifs = objectifs;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi Nutritionnel'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddObjectiveDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNutritionOverview(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildObjectivesSection(),
                    const SizedBox(height: 24),
                    _buildNutritionTips(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildNutritionOverview() {
    final activeObjectives = _objectifs.where((o) => !o.estAtteint()).toList();
    final completedObjectives = _objectifs.where((o) => o.estAtteint()).toList();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade400,
            Colors.green.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  Icons.restaurant_menu,
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
                      'Votre Suivi Nutritionnel',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Suivez vos objectifs alimentaires',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildOverviewStat(
                  'Objectifs Actifs',
                  '${activeObjectives.length}',
                  Icons.track_changes,
                ),
              ),
              Expanded(
                child: _buildOverviewStat(
                  'Objectifs Atteints',
                  '${completedObjectives.length}',
                  Icons.check_circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions Rapides',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Ajouter un Objectif',
                'Définir un nouveau but',
                Icons.add_circle,
                Colors.blue,
                _showAddObjectiveDialog,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Conseils Nutrition',
                'Découvrir des astuces',
                Icons.lightbulb,
                Colors.orange,
                _showNutritionTips,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObjectivesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mes Objectifs Nutritionnels',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _objectifs.isEmpty
            ? _buildEmptyObjectives()
            : Column(
                children: _objectifs.map((objectif) => _buildObjectiveCard(objectif)).toList(),
              ),
      ],
    );
  }

  Widget _buildEmptyObjectives() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.track_changes,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun objectif défini',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez par définir vos objectifs nutritionnels',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showAddObjectiveDialog,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un objectif'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObjectiveCard(Objectif objectif) {
    final progress = objectif.progression / objectif.valeurCible;
    final isCompleted = objectif.estAtteint();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? Colors.green.shade200 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green : Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle : Icons.track_changes,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      objectif.type,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Objectif: ${objectif.valeurCible}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Atteint !',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted ? Colors.green : Colors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(progress * 100).clamp(0, 100).toInt()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Progression: ${objectif.progression} / ${objectif.valeurCible}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionTips() {
    final tips = [
      {
        'title': 'Hydratation',
        'tip': 'Buvez au moins 8 verres d\'eau par jour',
        'icon': '💧',
        'color': Colors.blue,
      },
      {
        'title': 'Équilibre',
        'tip': 'Mangez 5 portions de fruits et légumes par jour',
        'icon': '🥗',
        'color': Colors.green,
      },
      {
        'title': 'Protéines',
        'tip': 'Incluez des protéines à chaque repas',
        'icon': '🥩',
        'color': Colors.orange,
      },
      {
        'title': 'Régularité',
        'tip': 'Mangez à heures régulières',
        'icon': '⏰',
        'color': Colors.purple,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Conseils Nutrition',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...tips.map((tip) => _buildTipCard(tip)).toList(),
      ],
    );
  }

  Widget _buildTipCard(Map<String, dynamic> tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (tip['color'] as Color).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (tip['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              tip['icon'],
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip['tip'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddObjectiveDialog() {
    final typeController = TextEditingController();
    final valeurController = TextEditingController();
    final progressionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvel Objectif Nutritionnel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: typeController,
              decoration: const InputDecoration(
                labelText: 'Type d\'objectif',
                hintText: 'Ex: Perte de poids, Gain musculaire...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: valeurController,
              decoration: const InputDecoration(
                labelText: 'Valeur cible',
                hintText: 'Ex: 5.0 (kg)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: progressionController,
              decoration: const InputDecoration(
                labelText: 'Progression actuelle',
                hintText: 'Ex: 1.5 (kg)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (typeController.text.isNotEmpty &&
                  valeurController.text.isNotEmpty &&
                  progressionController.text.isNotEmpty) {
                final objectif = Objectif(
                  utilisateurId: widget.utilisateur.id!,
                  type: typeController.text,
                  valeurCible: double.parse(valeurController.text),
                  dateFixee: DateTime.now().add(const Duration(days: 30)),
                  progression: double.parse(progressionController.text),
                );
                
                await _objectifService.creerObjectif(objectif);
                Navigator.pop(context);
                _loadObjectifs();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Objectif créé avec succès !'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _showNutritionTips() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Conseils Nutrition',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildDetailedTip(
                      'Hydratation Optimale',
                      '💧',
                      'Buvez 2-3 litres d\'eau par jour, surtout avant et après l\'exercice. L\'eau aide à réguler la température corporelle et transporte les nutriments.',
                      Colors.blue,
                    ),
                    _buildDetailedTip(
                      'Équilibre Alimentaire',
                      '🥗',
                      'Suivez la règle des 5 portions : 3 portions de légumes et 2 portions de fruits par jour pour un apport optimal en vitamines.',
                      Colors.green,
                    ),
                    _buildDetailedTip(
                      'Protéines Essentielles',
                      '🥩',
                      'Consommez 1.2-1.6g de protéines par kg de poids corporel. Sources : viande, poisson, œufs, légumineuses, produits laitiers.',
                      Colors.orange,
                    ),
                    _buildDetailedTip(
                      'Rythme Alimentaire',
                      '⏰',
                      'Mangez toutes les 3-4 heures pour maintenir un métabolisme stable et éviter les fringales.',
                      Colors.purple,
                    ),
                    _buildDetailedTip(
                      'Glucides Intelligents',
                      '🍞',
                      'Privilégiez les glucides complexes (céréales complètes, légumineuses) plutôt que les sucres simples.',
                      Colors.brown,
                    ),
                    _buildDetailedTip(
                      'Graisses Saines',
                      '🥑',
                      'Incluez des graisses insaturées : avocat, noix, huile d\'olive, poissons gras pour la santé cardiovasculaire.',
                      Colors.teal,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedTip(String title, String emoji, String description, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
