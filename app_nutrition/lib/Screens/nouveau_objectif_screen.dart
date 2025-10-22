import 'package:flutter/material.dart';
import '../Entites/objectif.dart';
import '../Entites/utilisateur.dart';
import '../Services/objectif_service.dart';

class NouveauObjectifScreen extends StatefulWidget {
  final Utilisateur utilisateur;
  final Objectif? initial; // optional for edit

  const NouveauObjectifScreen({
    Key? key,
    required this.utilisateur,
    this.initial,
  }) : super(key: key);

  @override
  State<NouveauObjectifScreen> createState() => _NouveauObjectifScreenState();
}

class _NouveauObjectifScreenState extends State<NouveauObjectifScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valeurCibleController = TextEditingController();
  final ObjectifService _objectifService = ObjectifService();

  String _typeSelectionne = 'Perte de poids';
  DateTime _dateFixee = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;

  bool get _isEditMode => widget.initial != null;

  // Types d'objectifs prédéfinis
  final List<String> _typesObjectifs = [
    'Perte de poids',
    'Prise de poids',
    'Maintien du poids',
    'Augmentation masse musculaire',
    'Réduction masse graisseuse',
    'Amélioration endurance',
    'Équilibre nutritionnel',
    'Hydratation quotidienne',
    'Consommation fruits/légumes',
    'Réduction sucre',
    'Réduction sel',
    'Augmentation protéines',
  ];

  @override
  void dispose() {
    _valeurCibleController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // If editing, prefill fields
    if (_isEditMode) {
      final init = widget.initial!;
      _typeSelectionne = init.type;
      _valeurCibleController.text = init.valeurCible.toString();
      _dateFixee = init.dateFixee;
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateFixee,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null && picked != _dateFixee) {
      setState(() {
        _dateFixee = picked;
      });
    }
  }

  String _getUniteParType(String type) {
    switch (type) {
      case 'Perte de poids':
      case 'Prise de poids':
      case 'Maintien du poids':
      case 'Augmentation masse musculaire':
      case 'Réduction masse graisseuse':
        return 'kg';
      case 'Hydratation quotidienne':
        return 'litres/jour';
      case 'Consommation fruits/légumes':
        return 'portions/jour';
      case 'Augmentation protéines':
        return 'g/jour';
      case 'Amélioration endurance':
        return 'minutes/jour';
      case 'Réduction sucre':
      case 'Réduction sel':
        return 'g/jour maximum';
      default:
        return 'unités';
    }
  }

  String _getDescriptionParType(String type) {
    switch (type) {
      case 'Perte de poids':
        return 'Nombre de kilos à perdre';
      case 'Prise de poids':
        return 'Nombre de kilos à prendre';
      case 'Maintien du poids':
        return 'Poids à maintenir';
      case 'Augmentation masse musculaire':
        return 'Masse musculaire à gagner';
      case 'Réduction masse graisseuse':
        return 'Masse graisseuse à perdre';
      case 'Amélioration endurance':
        return 'Minutes d\'exercice par jour';
      case 'Hydratation quotidienne':
        return 'Litres d\'eau par jour';
      case 'Consommation fruits/légumes':
        return 'Portions par jour';
      case 'Augmentation protéines':
        return 'Grammes de protéines par jour';
      case 'Réduction sucre':
        return 'Maximum de sucre par jour';
      case 'Réduction sel':
        return 'Maximum de sel par jour';
      default:
        return 'Valeur cible';
    }
  }

  Future<void> _creerObjectif() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (_isEditMode) {
          final edited = widget.initial!;
          edited.modifierObjectif(
            nouveauType: _typeSelectionne,
            nouvelleValeurCible: double.parse(_valeurCibleController.text),
            nouvelleDateFixee: _dateFixee,
          );
          await _objectifService.modifierObjectif(edited);
        } else {
          final objectif = Objectif(
            utilisateurId: widget.utilisateur.id,
            type: _typeSelectionne,
            valeurCible: double.parse(_valeurCibleController.text),
            dateFixee: _dateFixee,
            progression: 0.0,
          );

          await _objectifService.creerObjectif(objectif);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditMode
                    ? 'Objectif modifié avec succès !'
                    : 'Objectif créé avec succès !',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          // Retour à l'écran précédent
          Navigator.pop(
            context,
            true,
          ); // true indique qu'un objectif a été créé/édité
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la création: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvel Objectif'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec icône
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.flag,
                        size: 48,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Définir un nouvel objectif',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choisissez votre objectif et fixez-vous un défi !',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Type d'objectif
                Text(
                  'Type d\'objectif',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _typeSelectionne,
                      isExpanded: true,
                      items: _typesObjectifs.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _typeSelectionne = newValue;
                            _valeurCibleController
                                .clear(); // Reset la valeur quand on change de type
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Description du type sélectionné
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getDescriptionParType(_typeSelectionne),
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Valeur cible
                Text(
                  'Valeur cible (${_getUniteParType(_typeSelectionne)})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _valeurCibleController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ex: 5.0',
                    suffixText: _getUniteParType(_typeSelectionne),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.track_changes),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez saisir une valeur cible';
                    }
                    final number = double.tryParse(value);
                    if (number == null) {
                      return 'Veuillez saisir un nombre valide';
                    }
                    if (number <= 0) {
                      return 'La valeur doit être positive';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Date limite
                Text(
                  'Date limite',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectDate,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 12),
                        Text(
                          '${_dateFixee.day}/${_dateFixee.month}/${_dateFixee.year}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Spacer(),
                        Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Temps restant: ${_dateFixee.difference(DateTime.now()).inDays} jours',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 32),

                // Bouton de création
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _creerObjectif,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Créer l\'objectif',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Bouton annuler
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.pop(context);
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                      side: BorderSide(color: Theme.of(context).primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
