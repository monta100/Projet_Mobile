import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../Entities/programme.dart';
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
  final _formKeyProgramme = GlobalKey<FormState>();

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
    final start = _safeParse(p.dateDebut);
    final end = _safeParse(p.dateFin);
    final now = DateTime.now();

    if (now.isBefore(start)) return 0.0;
    if (now.isAfter(end)) return 1.0;

    final total = end.difference(start).inDays;
    final done = now.difference(start).inDays;
    return total > 0 ? done / total : 0.0;
  }

  void _filterProgrammes(String query) {
    setState(() {
      _filtered = _programmes
          .where(
            (p) =>
                p.nom.toLowerCase().contains(query.toLowerCase()) ||
                p.objectif.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  void _sortProgrammes(String option) {
    setState(() {
      _sortOption = option;
      if (option == "Date") {
        _filtered.sort(
          (a, b) => _safeParse(a.dateDebut).compareTo(_safeParse(b.dateDebut)),
        );
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
    // Double validation côté logique en plus du Form
    if (_nomCtrl.text.trim().isEmpty ||
        _objectifCtrl.text.trim().isEmpty ||
        _dateDebut == null ||
        _dateFin == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("⚠️ Champs requis")));
      return;
    }
    if (_dateFin!.isBefore(_dateDebut!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ La date de fin doit être après la date de début"),
        ),
      );
      return;
    }
    if (_dateFin!.difference(_dateDebut!).inDays > 365) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("⚠️ Durée max 365 jours")));
      return;
    }

    final programme = Programme(
      id: existing?.id,
      nom: _nomCtrl.text.trim(),
      objectif: _objectifCtrl.text.trim(),
      dateDebut: _dateDebut!.toIso8601String().split('T').first,
      dateFin: _dateFin!.toIso8601String().split('T').first,
    );

    if (existing == null) {
      await _service.insertProgramme(programme);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("✅ Programme ajouté !")));
    } else {
      await _service.updateProgramme(programme);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("✏️ Programme modifié !")));
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
            child: const Text("Annuler"),
          ),
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
    final finished = _programmes
        .where((p) => _calculateProgress(p) >= 1.0)
        .length;

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
            offset: const Offset(0, 3),
          ),
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
        Text(
          "$value",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }

  Widget _buildProgrammeCard(Programme p) {
    final progress = _calculateProgress(p);
    final debut = _fmt.format(_safeParse(p.dateDebut));
    final fin = _fmt.format(_safeParse(p.dateFin));

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
            offset: const Offset(0, 3),
          ),
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
                child: Text(
                  p.nom,
                  style: const TextStyle(
                    color: darkGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.orangeAccent),
                onPressed: () => _showAddOrEditDialog(existing: p),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () => _delete(p.id!),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Objectif : ${p.objectif}",
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          Text(
            "$debut → $fin",
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            color: mainGreen,
            backgroundColor: Colors.grey.shade200,
            minHeight: 6,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 4),
          Text(
            "${(progress * 100).toStringAsFixed(0)}% complété",
            style: TextStyle(
              fontSize: 12,
              color: progress == 1 ? Colors.redAccent : mainGreen,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddOrEditDialog({Programme? existing}) {
    if (existing != null) {
      _nomCtrl.text = existing.nom;
      _objectifCtrl.text = existing.objectif;
      _dateDebut = _safeParse(existing.dateDebut);
      _dateFin = _safeParse(existing.dateFin);
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
        title: Text(
          existing == null ? "Nouveau programme" : "Modifier le programme",
        ),
        content: SingleChildScrollView(
          child: Form(
            key: _formKeyProgramme,
            child: Column(
              children: [
                _field(
                  "Nom du programme",
                  _nomCtrl,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return "Nom requis";
                    if (v.trim().length > 50) return "50 caractères max";
                    return null;
                  },
                ),
                _field(
                  "Objectif",
                  _objectifCtrl,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return "Objectif requis";
                    if (v.trim().length > 120) return "120 caractères max";
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                _dateButton("Date de début", _dateDebut, true),
                const SizedBox(height: 8),
                _dateButton("Date de fin", _dateFin, false),
                if (_dateDebut != null && _dateFin != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "Durée: ${_dateFin!.difference(_dateDebut!).inDays} jours",
                      style: TextStyle(
                        color: _dateFin!.isBefore(_dateDebut!)
                            ? Colors.redAccent
                            : (_dateFin!.difference(_dateDebut!).inDays > 365
                                  ? Colors.orange
                                  : mainGreen),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: mainGreen),
            onPressed: () {
              final valid = _formKeyProgramme.currentState?.validate() ?? false;
              if (!valid) return;
              Navigator.pop(context);
              _addOrEdit(existing: existing);
            },
            child: const Text("Valider", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: ctrl,
        validator: validator,
        inputFormatters: [
          LengthLimitingTextInputFormatter(
            label.contains("Objectif") ? 120 : 50,
          ),
        ],
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
    // Simplify color logic to avoid deeply nested ternaries
    Color borderColor;
    if (date == null) {
      borderColor = Colors.redAccent.withOpacity(0.4);
    } else if (isStart) {
      borderColor = mainGreen.withOpacity(0.4);
    } else if (_dateDebut != null &&
        _dateFin != null &&
        _dateFin!.isBefore(_dateDebut!)) {
      borderColor = Colors.redAccent;
    } else {
      borderColor = mainGreen.withOpacity(0.4);
    }

    return InkWell(
      onTap: () => _selectDate(context, isStart),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: lightGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: mainGreen, size: 18),
            const SizedBox(width: 10),
            Text(
              date == null ? label : "$label : ${_fmt.format(date)}",
              style: const TextStyle(color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = _filtered.where((p) => _calculateProgress(p) < 1).toList();
    final finished = _filtered
        .where((p) => _calculateProgress(p) >= 1)
        .toList();

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
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        color: Colors.white,
                        size: 30,
                      ),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Rafraîchir',
                            onPressed: _load,
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Accueil',
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(
                              Icons.home,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Mes Programmes 💪",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Suivez vos plans et vos progrès sportifs",
                    style: TextStyle(color: Colors.white70),
                  ),
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
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
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
                child: Text(
                  "Aucun programme trouvé",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...list.map(_buildProgrammeCard),
        ],
      ),
    );
  }
}
