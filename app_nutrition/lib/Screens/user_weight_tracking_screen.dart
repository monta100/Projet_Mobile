import 'package:flutter/material.dart';
import '../Entites/utilisateur.dart';
import '../Entites/progress_tracking.dart';
import '../Services/progress_service.dart';

class UserWeightTrackingScreen extends StatefulWidget {
  final Utilisateur utilisateur;

  const UserWeightTrackingScreen({
    Key? key,
    required this.utilisateur,
  }) : super(key: key);

  @override
  State<UserWeightTrackingScreen> createState() => _UserWeightTrackingScreenState();
}

class _UserWeightTrackingScreenState extends State<UserWeightTrackingScreen>
    with TickerProviderStateMixin {
  final ProgressService _progressService = ProgressService();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _bodyFatController = TextEditingController();
  final TextEditingController _muscleMassController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<ProgressTracking> _weightEntries = [];
  bool _isLoading = true;
  bool _isRecording = false;

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
    
    _loadWeightHistory();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _weightController.dispose();
    _bodyFatController.dispose();
    _muscleMassController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadWeightHistory() async {
    setState(() => _isLoading = true);
    try {
      final entries = await _progressService.getUserProgress(
        widget.utilisateur.id!,
        type: 'weight',
      );
      
      setState(() {
        _weightEntries = entries;
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

  Future<void> _recordWeight() async {
    final weightText = _weightController.text.trim();
    if (weightText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir votre poids')),
      );
      return;
    }

    final weight = double.tryParse(weightText);
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un poids valide')),
      );
      return;
    }

    setState(() => _isRecording = true);

    try {
      final bodyFat = _bodyFatController.text.trim().isNotEmpty 
          ? double.tryParse(_bodyFatController.text.trim()) 
          : null;
      final muscleMass = _muscleMassController.text.trim().isNotEmpty 
          ? double.tryParse(_muscleMassController.text.trim()) 
          : null;
      final notes = _notesController.text.trim().isNotEmpty 
          ? _notesController.text.trim() 
          : null;

      await _progressService.recordWeight(
        widget.utilisateur.id!,
        weight,
        bodyFat: bodyFat,
        muscleMass: muscleMass,
        notes: notes,
      );

      // Vider les champs
      _weightController.clear();
      _bodyFatController.clear();
      _muscleMassController.clear();
      _notesController.clear();

      // Recharger l'historique
      await _loadWeightHistory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Poids enregistré avec succès !')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'enregistrement: $e')),
        );
      }
    } finally {
      setState(() => _isRecording = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Suivi du Poids'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWeightHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 30),
                    _buildWeightInputForm(),
                    const SizedBox(height: 30),
                    _buildCurrentStats(),
                    const SizedBox(height: 30),
                    _buildWeightHistory(),
                  ],
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.monitor_weight,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Suivi du Poids',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Enregistrez vos mesures corporelles',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightInputForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nouvelle Mesure',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildInputField(
            controller: _weightController,
            label: 'Poids (kg)',
            icon: Icons.monitor_weight,
            isRequired: true,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _bodyFatController,
            label: 'Masse grasse (%)',
            icon: Icons.pie_chart,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _muscleMassController,
            label: 'Masse musculaire (kg)',
            icon: Icons.fitness_center,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _notesController,
            label: 'Notes (optionnel)',
            icon: Icons.note,
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isRecording ? null : _recordWeight,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isRecording
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Enregistrer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        prefixIcon: Icon(icon, color: Colors.green),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildCurrentStats() {
    final weightEntries = _weightEntries.where((e) => e.metric == 'weight').toList();
    if (weightEntries.isEmpty) {
      return _buildEmptySection('Aucune donnée de poids disponible');
    }

    final latestWeight = weightEntries.first;
    final previousWeight = weightEntries.length > 1 ? weightEntries[1] : null;
    final weightChange = previousWeight != null 
        ? latestWeight.value - previousWeight.value 
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistiques Actuelles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Poids Actuel',
                  '${latestWeight.value.toStringAsFixed(1)} kg',
                  Icons.monitor_weight,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Dernière Mesure',
                  _formatDate(latestWeight.date),
                  Icons.calendar_today,
                  Colors.blue,
                ),
              ),
            ],
          ),
          if (weightChange != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: weightChange > 0 ? Colors.red.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: weightChange > 0 ? Colors.red.shade200 : Colors.green.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    weightChange > 0 ? Icons.trending_up : Icons.trending_down,
                    color: weightChange > 0 ? Colors.red : Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Changement depuis la dernière mesure',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '${weightChange > 0 ? '+' : ''}${weightChange.toStringAsFixed(1)} kg',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: weightChange > 0 ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeightHistory() {
    if (_weightEntries.isEmpty) {
      return _buildEmptySection('Aucun historique de poids disponible');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Historique',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._weightEntries.take(10).map((entry) => _buildHistoryCard(entry)).toList(),
      ],
    );
  }

  Widget _buildHistoryCard(ProgressTracking entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getMetricIcon(entry.metric),
              color: Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  entry.formattedValue,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (entry.notes != null && entry.notes!.isNotEmpty)
                  Text(
                    entry.notes!,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            _formatDate(entry.date),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySection(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.monitor_weight,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMetricIcon(String metric) {
    switch (metric) {
      case 'weight':
        return Icons.monitor_weight;
      case 'body_fat':
        return Icons.pie_chart;
      case 'muscle_mass':
        return Icons.fitness_center;
      default:
        return Icons.straighten;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Aujourd\'hui';
    } else if (difference == 1) {
      return 'Hier';
    } else if (difference < 7) {
      return 'Il y a $difference jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
