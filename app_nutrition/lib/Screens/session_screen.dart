import 'package:flutter/material.dart';
import '../Entities/session.dart';
import '../Services/session_service.dart';

const Color mainGreen = Color(0xFF2ECC71);
const Color darkGreen = Color(0xFF1E8449);
const Color lightGray = Color(0xFFF5F6F8);

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final SessionService _service = SessionService();
  List<Session> _sessions = [];
  List<Session> _filtered = [];

  final _typeCtrl = TextEditingController();
  final _dureeCtrl = TextEditingController();
  final _intensiteCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  double userWeight = 70;
  String _sortOption = "Aucun";
  String _conseil = "";

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _service.getAllSessions();
    setState(() {
      _sessions = data;
      _filtered = data;
      _generateConseil();
    });
  }

  double _calculateCalories(String intensite, int duree, double poids) {
    double facteur =
        intensite == "Forte" ? 8 : intensite == "Moyenne" ? 6 : 4;
    return poids * facteur * duree / 60;
  }

  void _generateConseil() {
    if (_sessions.isEmpty) {
      _conseil = "Commencez votre première séance aujourd’hui 💪";
      return;
    }
    int moyenne = _sessions.where((s) => s.intensite == "Moyenne").length;
    int forte = _sessions.where((s) => s.intensite == "Forte").length;

    if (moyenne > forte) {
      _conseil = "🔥 Essayez une séance plus intense cette semaine !";
    } else {
      _conseil = "🌟 Excellent rythme, continuez comme ça !";
    }
  }

  Future<void> _addOrEdit({Session? existing}) async {
    if (_typeCtrl.text.isEmpty ||
        _dureeCtrl.text.isEmpty ||
        _intensiteCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Veuillez remplir tous les champs")),
      );
      return;
    }

    int duree = int.parse(_dureeCtrl.text);
    double calories = _calculateCalories(_intensiteCtrl.text, duree, userWeight);

    final session = Session(
      id: existing?.id,
      typeActivite: _typeCtrl.text.trim(),
      duree: duree,
      intensite: _intensiteCtrl.text.trim(),
      calories: calories.round(),
    );

    if (existing == null) {
      await _service.insertSession(session);
    } else {
      await _service.updateSession(session);
    }

    _clearFields();
    _load();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(existing == null
              ? "✅ Séance ajoutée avec succès !"
              : "✏️ Séance modifiée avec succès !")),
    );
  }

  void _clearFields() {
    _typeCtrl.clear();
    _dureeCtrl.clear();
    _intensiteCtrl.clear();
  }

  Color _colorByIntensity(String intensity) {
    switch (intensity.toLowerCase()) {
      case "faible":
        return Colors.blueAccent;
      case "moyenne":
        return Colors.orangeAccent;
      case "forte":
        return Colors.redAccent;
      default:
        return mainGreen;
    }
  }

  void _showAddDialog({Session? existing}) {
    if (existing != null) {
      _typeCtrl.text = existing.typeActivite;
      _dureeCtrl.text = existing.duree.toString();
      _intensiteCtrl.text = existing.intensite;
    } else {
      _clearFields();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(existing == null ? "Nouvelle séance" : "Modifier séance",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field("Type d’activité", _typeCtrl),
            _field("Durée (min)", _dureeCtrl, number: true),
            _dropdownIntensity(),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler")),
          ElevatedButton.icon(
            icon: const Icon(Icons.check, color: Colors.white),
            label: Text(existing == null ? "Ajouter" : "Modifier"),
            style: ElevatedButton.styleFrom(
                backgroundColor: mainGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              Navigator.pop(context);
              _addOrEdit(existing: existing);
            },
          ),
        ],
      ),
    );
  }

  void _filterSessions(String query) {
    setState(() {
      _filtered = _sessions
          .where((s) =>
              s.typeActivite.toLowerCase().contains(query.toLowerCase()) ||
              s.intensite.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _sortSessions(String option) {
    setState(() {
      _sortOption = option;
      if (option == "Durée") {
        _filtered.sort((a, b) => a.duree.compareTo(b.duree));
      } else if (option == "Calories") {
        _filtered.sort((a, b) => a.calories.compareTo(b.calories));
      } else if (option == "Intensité") {
        _filtered.sort(
            (a, b) => a.intensite.toLowerCase().compareTo(b.intensite.toLowerCase()));
      } else {
        _filtered = List.from(_sessions);
      }
    });
  }

  // ✅ Résumé général des séances
  Widget _buildSummaryCard() {
    if (_sessions.isEmpty) return const SizedBox.shrink();

    int totalMinutes = _sessions.fold(0, (sum, s) => sum + s.duree);
    int totalCalories = _sessions.fold(0, (sum, s) => sum + s.calories);
    int count = _sessions.length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black12.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Résumé de vos séances",
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: darkGreen)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryItem(Icons.timer, "$totalMinutes min", "Durée totale"),
              _summaryItem(Icons.local_fire_department, "$totalCalories kcal",
                  "Calories totales"),
              _summaryItem(Icons.fitness_center, "$count", "Séances"),
            ],
          )
        ],
      ),
    );
  }

  Widget _summaryItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: mainGreen),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black87)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: mainGreen,
        onPressed: () => _showAddDialog(),
        label: const Text("Nouvelle séance"),
        icon: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            // 🌿 HEADER
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [mainGreen, darkGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.fitness_center,
                      color: Colors.white, size: 30),
                  const SizedBox(height: 8),
                  const Text("Mes Séances 🏋️‍♀️",
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 6),
                  Text(_conseil,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white)),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Modifier le poids"),
                          content: TextField(
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: "Poids (kg)"),
                            onSubmitted: (v) {
                              setState(() {
                                userWeight = double.tryParse(v) ?? userWeight;
                              });
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.monitor_weight, color: Colors.white),
                    label: Text("$userWeight kg",
                        style: const TextStyle(color: Colors.white)),
                  )
                ],
              ),
            ),

            // ✅ Résumé des séances
            _buildSummaryCard(),

            // 🔍 Recherche et tri
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: "Rechercher une séance...",
                        prefixIcon:
                            const Icon(Icons.search, color: mainGreen),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: _filterSessions,
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _sortOption,
                    items: ["Aucun", "Durée", "Calories", "Intensité"]
                        .map((e) =>
                            DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => _sortSessions(val!),
                  ),
                ],
              ),
            ),

            // 📋 Liste des séances
            _filtered.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 30),
                      child: Text("Aucune séance trouvée",
                          style:
                              TextStyle(color: Colors.grey, fontSize: 16)),
                    ),
                  )
                : Column(
                    children: _filtered.map((s) {
                      final color = _colorByIntensity(s.intensite);
                      IconData icon = s.intensite == "Forte"
                          ? Icons.fitness_center
                          : s.intensite == "Moyenne"
                              ? Icons.directions_run
                              : Icons.self_improvement;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black12.withOpacity(0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 3))
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  shape: BoxShape.circle),
                              child: Icon(icon, color: color, size: 26),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.typeActivite,
                                      style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text("${s.duree} min • ${s.calories} kcal",
                                      style: const TextStyle(fontSize: 13)),
                                  Text("Intensité : ${s.intensite}",
                                      style: TextStyle(
                                          color: color, fontSize: 13)),
                                ],
                              ),
                            ),
                            IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.orangeAccent),
                                onPressed: () =>
                                    _showAddDialog(existing: s)),
                            IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent),
                                onPressed: () async {
                                  await _service.deleteSession(s.id!);
                                  _load();
                                }),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
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
          prefixIcon: const Icon(Icons.edit, color: mainGreen),
          filled: true,
          fillColor: lightGray,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _dropdownIntensity() {
    final intensities = ["Faible", "Moyenne", "Forte"];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: "Intensité",
          prefixIcon: const Icon(Icons.bolt, color: mainGreen),
          filled: true,
          fillColor: lightGray,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        value: _intensiteCtrl.text.isEmpty ? null : _intensiteCtrl.text,
        items: intensities
            .map((val) => DropdownMenuItem(value: val, child: Text(val)))
            .toList(),
        onChanged: (val) => _intensiteCtrl.text = val ?? "",
      ),
    );
  }
}
