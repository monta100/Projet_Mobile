import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../Entities/exercice.dart';
import '../Services/exercice_service.dart';

class ExerciceScreen extends StatefulWidget {
  const ExerciceScreen({super.key});

  @override
  State<ExerciceScreen> createState() => _ExerciceScreenState();
}

class _ExerciceScreenState extends State<ExerciceScreen> {
  final ExerciceService _service = ExerciceService();
  List<Exercice> _exercices = [];

  final _nomCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _repsCtrl = TextEditingController();
  String? _imagePath;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadExercices();
  }

  Future<void> _loadExercices() async {
    final data = await _service.getAllExercices();
    setState(() => _exercices = data);
  }

  Future<void> _addExercice() async {
    if (_nomCtrl.text.isEmpty || _repsCtrl.text.isEmpty) return;

    await _service.insertExercice(Exercice(
      nom: _nomCtrl.text,
      description: _descCtrl.text,
      repetitions: int.parse(_repsCtrl.text),
      imagePath: _imagePath ?? '',
      videoPath: '',
      programmeId: 1, // ✅ valeur par défaut temporaire (à relier plus tard)
    ));

    _nomCtrl.clear();
    _descCtrl.clear();
    _repsCtrl.clear();
    _imagePath = null;
    _loadExercices();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imagePath = picked.path);
    }
  }

  Future<void> _deleteExercice(int id) async {
    await _service.deleteExercice(id);
    _loadExercices();
  }

  @override
  Widget build(BuildContext context) {
    const mainGreen = Color(0xFF2ECC71);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: mainGreen,
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: mainGreen,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Mes Exercices",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Ajoutez vos exercices personnalisés",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            // LISTE
            Expanded(
              child: _exercices.isEmpty
                  ? const Center(
                      child: Text(
                        "Aucun exercice enregistré",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _exercices.length,
                      itemBuilder: (_, i) {
                        final e = _exercices[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 4,
                          child: ListTile(
                            leading: e.imagePath.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(e.imagePath),
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(Icons.image_not_supported,
                                    color: Colors.grey, size: 50),
                            title: Text(
                              e.nom,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: mainGreen,
                              ),
                            ),
                            subtitle: Text(
                              "${e.description}\nRépétitions : ${e.repetitions}",
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteExercice(e.id!),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // 🟢 POPUP D’AJOUT
  void _showAddDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text("Nouvel exercice"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _field("Nom", _nomCtrl),
              _field("Description", _descCtrl),
              _field("Répétitions", _repsCtrl, number: true),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ECC71),
                    ),
                    icon: const Icon(Icons.image),
                    label: const Text("Choisir image"),
                    onPressed: _pickImage,
                  ),
                  const SizedBox(width: 10),
                  if (_imagePath != null)
                    const Icon(Icons.check_circle, color: Colors.green)
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2ECC71),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _addExercice();
            },
            child: const Text("Ajouter"),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {bool number = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: ctrl,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
