import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Entites/programme.dart';
import '../Services/programme_service.dart';

const Color mainGreen = Color(0xFF2ECC71);
const Color darkGreen = Color(0xFF1E8449);
const Color lightGray = Color(0xFFF8F9FA);

class ProgrammeScreen extends StatefulWidget {
  const ProgrammeScreen({super.key});

  @override
  State<ProgrammeScreen> createState() => _ProgrammeScreenState();
}

class _ProgrammeScreenState extends State<ProgrammeScreen>
    with SingleTickerProviderStateMixin {
  final ProgrammeService _service = ProgrammeService();
  List<Programme> _programmes = [];
  List<Programme> _filtered = [];

  final _nomCtrl = TextEditingController();
  final _objectifCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  DateTime? _dateDebut;
  DateTime? _dateFin;

  final DateFormat _fmt = DateFormat('dd/MM/yyyy');
  String _sortOption = "Aucun";

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomCtrl.dispose();
    _objectifCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await _service.getAllProgrammes();
    setState(() {
      _programmes = data;
      _filtered = data;
    });
  }

  DateTime _safeParse(String date) {
    try {
      return DateTime.parse(date);
    } catch (_) {
      try {
        return DateFormat('d/M/yyyy').parse(date);
      } catch (_) {
        return DateTime.now();
      }
    }
  }

  double _calculateProgress(Programme p) {
    try {
      final start = DateTime.parse(p.dateDebut);
      final end = DateTime.parse(p.dateFin);
      final now = DateTime.now();

      if (now.isBefore(start)) return 0.0;
      if (now.isAfter(end)) return 1.0;

      final total = end.difference(start).inDays;
      final done = now.difference(start).inDays;
      return total > 0 ? done / total : 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  void _filterProgrammes(String query) {
    setState(() {
      _filtered = _programmes
          .where((p) =>
              p.nom.toLowerCase().contains(query.toLowerCase()) ||
              p.objectif.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _sortProgrammes(String option) {
    setState(() {
      _sortOption = option;
      if (option == "Date") {
        _filtered.sort((a, b) =>
            a.dateDebut.compareTo(b.dateDebut));
      } else if (option == "Nom") {
        _filtered.sort((a, b) => a.nom.compareTo(b.nom));
      } else {
        _filtered = List.from(_programmes);
      }
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      locale: const Locale('fr', 'FR'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: mainGreen,
            onPrimary: Colors.white,
            onSurface: Colors.black87,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => isStart ? _dateDebut = picked : _dateFin = picked);
    }
  }

  Future<void> _addOrEdit({Programme? existing}) async {
    if (_nomCtrl.text.isEmpty ||
        _objectifCtrl.text.isEmpty ||
        _dateDebut == null ||
        _dateFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("⚠️ Veuillez remplir tous les champs")));
      return;
    }

    final programme = Programme(
      id: existing?.id,
      nom: _nomCtrl.text.trim(),
      objectif: _objectifCtrl.text.trim(),
      dateDebut: DateFormat('yyyy-MM-dd').format(_dateDebut!),
      dateFin: DateFormat('yyyy-MM-dd').format(_dateFin!),
    );

    if (existing == null) {
      await _service.insertProgramme(programme);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("✅ Programme ajouté !")));
    } else {
      await _service.updateProgramme(programme);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("✏️ Programme modifié !")));
    }

    _nomCtrl.clear();
    _objectifCtrl.clear();
    _dateDebut = null;
    _dateFin = null;
    _load();
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("🗑 Supprimer le programme"),
        content: const Text("Confirmer la suppression ?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _service.deleteProgramme(id);
      _load();
    }
  }

  Widget _buildSummary() {
    if (_programmes.isEmpty) return const SizedBox.shrink();

    final active = _programmes.where((p) => _calculateProgress(p) < 1.0).length;
    final finished =
        _programmes.where((p) => _calculateProgress(p) >= 1.0).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem(Icons.play_circle_fill, active, "Actifs"),
          _summaryItem(Icons.check_circle, finished, "Terminés"),
          _summaryItem(Icons.list_alt, _programmes.length, "Total"),
        ],
      ),
    );
  }

  Widget _summaryItem(IconData icon, int value, String label) {
    return Column(
      children: [
        Icon(icon, color: mainGreen, size: 26),
        const SizedBox(height: 6),
        Text("$value",
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black87)),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }

  Widget _buildProgrammeCard(Programme p) {
    final progress = _calculateProgress(p);
    final debut = _fmt.format(DateTime.parse(p.dateDebut));
    final fin = _fmt.format(DateTime.parse(p.dateFin));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black12.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.track_changes, color: mainGreen),
              const SizedBox(width: 10),
              Expanded(
                child: Text(p.nom,
                    style: const TextStyle(
                        color: darkGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 17)),
              ),
              IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orangeAccent),
                  onPressed: () => _showAddOrEditDialog(existing: p)),
              IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _delete(p.id!)),
            ],
          ),
          const SizedBox(height: 6),
          Text("Objectif : ${p.objectif}",
              style: const TextStyle(fontSize: 13, color: Colors.black87)),
          Text("$debut → $fin",
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            color: mainGreen,
            backgroundColor: Colors.grey.shade200,
            minHeight: 6,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 4),
          Text("${(progress * 100).toStringAsFixed(0)}% complété",
              style: TextStyle(
                  fontSize: 12,
                  color: progress == 1 ? Colors.redAccent : mainGreen)),
        ],
      ),
    );
  }

  void _showAddOrEditDialog({Programme? existing}) {
    if (existing != null) {
      _nomCtrl.text = existing.nom;
      _objectifCtrl.text = existing.objectif;
      _dateDebut = DateTime.parse(existing.dateDebut);
      _dateFin = DateTime.parse(existing.dateFin);
    } else {
      _nomCtrl.clear();
      _objectifCtrl.clear();
      _dateDebut = null;
      _dateFin = null;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(existing == null
            ? "Nouveau programme"
            : "Modifier le programme"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _field("Nom du programme", _nomCtrl),
              _field("Objectif", _objectifCtrl),
              const SizedBox(height: 8),
              _dateButton("Date de début", _dateDebut, true),
              const SizedBox(height: 8),
              _dateButton("Date de fin", _dateFin, false),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: mainGreen),
            onPressed: () {
              Navigator.pop(context);
              _addOrEdit(existing: existing);
            },
            child: const Text("Valider", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: ctrl,
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

  Widget _dateButton(String label, DateTime? date, bool isStart) {
    return InkWell(
      onTap: () => _selectDate(context, isStart),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: lightGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: mainGreen, size: 18),
            const SizedBox(width: 10),
            Text(
              date == null ? label : "$label : ${_fmt.format(date)}",
              style: const TextStyle(color: Colors.black87),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = _filtered.where((p) => _calculateProgress(p) < 1).toList();
    final finished = _filtered.where((p) => _calculateProgress(p) >= 1).toList();

    return Scaffold(
      backgroundColor: lightGray,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: mainGreen,
        onPressed: () => _showAddOrEditDialog(),
        label: const Text("Nouveau programme"),
        icon: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [mainGreen, darkGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.calendar_month, color: Colors.white, size: 30),
                  SizedBox(height: 8),
                  Text("Mes Programmes 💪",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text("Suivez vos plans et vos progrès sportifs",
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              indicatorColor: mainGreen,
              labelColor: darkGreen,
              tabs: const [
                Tab(text: "Actifs"),
                Tab(text: "Terminés"),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProgrammeList(active),
                  _buildProgrammeList(finished),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgrammeList(List<Programme> list) {
    return ListView(
      children: [
        _buildSummary(),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: "Rechercher un programme...",
                    prefixIcon: const Icon(Icons.search, color: mainGreen),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: _filterProgrammes,
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _sortOption,
                items: ["Aucun", "Nom", "Date"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => _sortProgrammes(val!),
              ),
            ],
          ),
        ),
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(
                child: Text("Aucun programme trouvé",
                    style: TextStyle(color: Colors.grey))),
          )
        else
          ...list.map(_buildProgrammeCard),
      ],
    );
  }
}
