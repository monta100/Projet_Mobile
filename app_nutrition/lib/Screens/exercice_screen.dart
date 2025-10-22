import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../Entites/exercice.dart';
import '../Entites/programme.dart';
import '../Services/exercice_service.dart';
import '../Services/programme_service.dart';

const Color mainGreen = Color(0xFF2ECC71);
const Color darkGreen = Color(0xFF1E8449);
const Color lightGray = Color(0xFFF5F6F8);

class ExerciceScreen extends StatefulWidget {
  const ExerciceScreen({super.key});

  @override
  State<ExerciceScreen> createState() => _ExerciceScreenState();
}

class _ExerciceScreenState extends State<ExerciceScreen> {
  final ExerciceService _service = ExerciceService();
  final ProgrammeService _programmeService = ProgrammeService();
  List<Exercice> _exercices = [];
  List<Exercice> _filtered = [];
  List<Programme> _programmes = [];

  final _nomCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _repsCtrl = TextEditingController();
  String? _imagePath;
  String? _videoPath;
  final _picker = ImagePicker();

  final _searchCtrl = TextEditingController();
  String _selectedMuscle = "Tous";
  String _sortOption = "Aucun";
  int? _selectedProgrammeId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadProgrammes();
    await _loadExercices();
  }

  Future<void> _loadProgrammes() async {
    final data = await _programmeService.getAllProgrammes();
    setState(() {
      _programmes = data;
      // Sélectionner le premier programme par défaut s'il existe
      if (data.isNotEmpty && _selectedProgrammeId == null) {
        _selectedProgrammeId = data.first.id;
      }
    });
  }

  Future<void> _loadExercices() async {
    final data = await _service.getAllExercices();
    setState(() {
      _exercices = data;
      _filtered = data;
    });
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imagePath = picked.path);
  }

  Future<void> _pickVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) setState(() => _videoPath = picked.path);
  }

  void _filterExercices(String query) {
    setState(() {
      _filtered = _exercices.where((e) {
        final matchText = e.nom.toLowerCase().contains(query.toLowerCase());
        final matchMuscle = _selectedMuscle == "Tous" ||
            e.description.toLowerCase().contains(_selectedMuscle.toLowerCase());
        return matchText && matchMuscle;
      }).toList();
    });
  }

  void _sortExercices(String option) {
    setState(() {
      _sortOption = option;
      if (option == "Nom") {
        _filtered.sort((a, b) => a.nom.compareTo(b.nom));
      } else if (option == "Répétitions") {
        _filtered.sort((a, b) => a.repetitions.compareTo(b.repetitions));
      } else {
        _filtered = List.from(_exercices);
      }
    });
  }

  Future<void> _addOrEditExercice({Exercice? existing}) async {
    if (_nomCtrl.text.isEmpty || _repsCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Remplis tous les champs nécessaires")),
      );
      return;
    }

    // Vérifier qu'un programme est sélectionné
    if (_selectedProgrammeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Veuillez d'abord créer un programme !"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final exercice = Exercice(
      id: existing?.id,
      nom: _nomCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      repetitions: int.parse(_repsCtrl.text),
      imagePath: _imagePath ?? existing?.imagePath ?? '',
      videoPath: _videoPath ?? existing?.videoPath ?? '',
      programmeId: _selectedProgrammeId!,
    );

    if (existing == null) {
      await _service.insertExercice(exercice);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Exercice ajouté avec succès !")));
    } else {
      await _service.updateExercice(exercice);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✏️ Exercice modifié avec succès !")));
    }

    _nomCtrl.clear();
    _descCtrl.clear();
    _repsCtrl.clear();
    _imagePath = null;
    _videoPath = null;
    _loadExercices();
  }

  Future<void> _deleteExercice(int id) async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("🗑 Supprimer cet exercice ?"),
        content: const Text("Cette action est irréversible."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _service.deleteExercice(id);
      _loadExercices();
    }
  }

  void _showAddOrEditDialog(BuildContext ctx, {Exercice? existing}) {
    if (existing != null) {
      _nomCtrl.text = existing.nom;
      _descCtrl.text = existing.description;
      _repsCtrl.text = existing.repetitions.toString();
      _imagePath = existing.imagePath;
      _videoPath = existing.videoPath;
      _selectedProgrammeId = existing.programmeId;
    } else {
      _nomCtrl.clear();
      _descCtrl.clear();
      _repsCtrl.clear();
      _imagePath = null;
      _videoPath = null;
      // Le programme par défaut est déjà défini dans _loadProgrammes()
    }

    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(existing == null ? "Nouvel exercice" : "Modifier l’exercice"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _field("Nom", _nomCtrl),
              _field("Description (ex: Bras, Jambes...)", _descCtrl),
              _field("Répétitions", _repsCtrl, number: true),
              const SizedBox(height: 16),
              // Dropdown pour sélectionner le programme
              if (_programmes.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Aucun programme disponible.\nCréez d\'abord un programme dans l\'onglet "Plans".',
                          style: TextStyle(color: Colors.orange, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: mainGreen),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: _selectedProgrammeId,
                      hint: const Text('Sélectionner un programme'),
                      icon: const Icon(Icons.arrow_drop_down, color: mainGreen),
                      items: _programmes.map((prog) {
                        return DropdownMenuItem<int>(
                          value: prog.id,
                          child: Text(
                            prog.nom,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedProgrammeId = value;
                        });
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image, color: Colors.white),
                label: const Text("Choisir une image", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: mainGreen),
              ),
              if (_imagePath != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Image.file(File(_imagePath!), width: 100, height: 100),
                ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _pickVideo,
                icon: const Icon(Icons.video_library, color: Colors.white),
                label: const Text("Choisir une vidéo", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: darkGreen),
              ),
              if (_videoPath != null)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Icon(Icons.check_circle, color: mainGreen),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: mainGreen),
            onPressed: () {
              Navigator.pop(ctx);
              _addOrEditExercice(existing: existing);
            },
            child: Text(existing == null ? "Ajouter" : "Modifier",
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _startTimer(String exerciceNom) {
    showDialog(
      context: context,
      builder: (_) => _TimerDialog(exerciceNom: exerciceNom),
    );
  }

  void _openVideo(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VideoPlayerScreen(videoPath: path)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: mainGreen,
        onPressed: () => _showAddOrEditDialog(context),
        label: const Text("Nouvel exercice"),
        icon: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [mainGreen, darkGreen]),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.fitness_center, color: Colors.white, size: 30),
                  SizedBox(height: 8),
                  Text("Mes Exercices 🏋️‍♀️",
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),

            // Recherche + tri + filtres
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: "Rechercher un exercice...",
                        prefixIcon: const Icon(Icons.search, color: mainGreen),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      onChanged: _filterExercices,
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _sortOption,
                    items: ["Aucun", "Nom", "Répétitions"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => _sortExercices(val!),
                  ),
                ],
              ),
            ),

            // Filtres muscles
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  for (var m in ["Tous", "Bras", "Jambes","Epaules", "Dos", "Abdos", "Poitrine"])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(m),
                        selected: _selectedMuscle == m,
                        selectedColor: mainGreen,
                        onSelected: (_) {
                          setState(() => _selectedMuscle = m);
                          _filterExercices(_searchCtrl.text);
                        },
                      ),
                    ),
                ],
              ),
            ),

            // Liste
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(child: Text("Aucun exercice trouvé"))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final e = _filtered[i];
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3))
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: e.imagePath.isNotEmpty
                                        ? Image.file(File(e.imagePath),
                                            width: 60, height: 60, fit: BoxFit.cover)
                                        : Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey.shade200,
                                            child:
                                                const Icon(Icons.image_outlined, color: Colors.grey)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(e.nom,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold, color: darkGreen, fontSize: 17)),
                                        Text(e.description, style: const TextStyle(fontSize: 13)),
                                        Text("${e.repetitions} répétitions",
                                            style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.orangeAccent),
                                      onPressed: () => _showAddOrEditDialog(context, existing: e)),
                                  IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                                      onPressed: () => _deleteExercice(e.id!)),
                                ],
                              ),
                              if (e.videoPath.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8, left: 5),
                                  child: GestureDetector(
                                    onTap: () => _openVideo(e.videoPath),
                                    child: const Text("🎬 Voir la vidéo",
                                        style: TextStyle(
                                            color: mainGreen,
                                            decoration: TextDecoration.underline)),
                                  ),
                                ),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed: () => _startTimer(e.nom),
                                icon: const Icon(Icons.timer, color: Colors.white),
                                label: const Text("Démarrer le timer",
                                    style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(backgroundColor: mainGreen),
                              ),
                            ],
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

  Widget _field(String label, TextEditingController ctrl, {bool number = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: ctrl,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.edit, color: mainGreen),
          filled: true,
          fillColor: lightGray,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

// ✅ Timer stable
class _TimerDialog extends StatefulWidget {
  final String exerciceNom;
  const _TimerDialog({required this.exerciceNom});

  @override
  State<_TimerDialog> createState() => __TimerDialogState();
}

class __TimerDialogState extends State<_TimerDialog> {
  int seconds = 0;
  bool running = false;
  Timer? _timer;

  void _startStop() {
    if (running) {
      _timer?.cancel();
      setState(() => running = false);
    } else {
      setState(() => running = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || !running) return;
        setState(() => seconds++);
      });
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      running = false;
      seconds = 0;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("⏱ ${widget.exerciceNom}"),
      content: Text(
        "${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}",
        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
      ),
      actions: [
        TextButton(onPressed: _reset, child: const Text("Réinitialiser")),
        TextButton(
            onPressed: _startStop,
            child: Text(running ? "Pause" : "Démarrer", style: const TextStyle(color: mainGreen))),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fermer")),
      ],
    );
  }
}

// 🎬 Écran lecteur vidéo
class VideoPlayerScreen extends StatefulWidget {
  final String videoPath;
  const VideoPlayerScreen({super.key, required this.videoPath});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("🎥 Vidéo de l'exercice"), backgroundColor: mainGreen),
      body: Center(
        child: _controller.value.isInitialized
            ? GestureDetector(
                onTap: () {
                  setState(() {
                    _controller.value.isPlaying ? _controller.pause() : _controller.play();
                  });
                },
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              )
            : const CircularProgressIndicator(color: mainGreen),
      ),
    );
  }
}
