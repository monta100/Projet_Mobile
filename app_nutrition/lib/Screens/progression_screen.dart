import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // ✅ pour RenderRepaintBoundary
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

// PDF
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../Entities/progression.dart';
import '../Services/session_service.dart';

const Color mainGreen = Color(0xFF2ECC71);
const Color darkGreen = Color(0xFF1E8449);
const Color lightGray = Color(0xFFF5F6F8);

class ProgressionScreen extends StatefulWidget {
  const ProgressionScreen({super.key});

  @override
  State<ProgressionScreen> createState() => _ProgressionScreenState();
}

class _ProgressionScreenState extends State<ProgressionScreen> {
  final SessionService _sessionService = SessionService();

  // Clé pour capturer le graphique (barres d’intensité) dans le PDF
  final GlobalKey _chartKey = GlobalKey();

  List<Progression> _all = [];
  List<Progression> _view = [];
  String _range = "Mois"; // Semaine | Mois | Année

  int _totalCalories = 0;
  int _totalDuree = 0;

  static const int _monthlyGoalKcal = 5000;

  @override
  void initState() {
    super.initState();
    _rebuildFromSessions();
  }

  Future<void> _rebuildFromSessions() async {
    final sessions = await _sessionService.getAllSessions();

    if (sessions.isEmpty) {
      setState(() {
        _all = [];
        _view = [];
        _totalCalories = 0;
        _totalDuree = 0;
      });
      return;
    }

    final now = DateTime.now();
    final List<Progression> built = [];

    for (int i = 0; i < sessions.length; i++) {
      final s = sessions[i];
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      built.add(
        Progression(
          date: DateFormat('yyyy-MM-dd').format(date),
          caloriesBrulees: s.calories,
          dureeTotale: s.duree,
          commentaire: "Séance ${s.typeActivite} (${s.intensite})",
          sessionId: s.id ?? 0,
        ),
      );
    }

    built.sort((a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));

    setState(() {
      _all = built;
    });

    _applyRange();
  }

  void _applyRange() {
    if (_all.isEmpty) {
      setState(() {
        _view = [];
        _totalCalories = 0;
        _totalDuree = 0;
      });
      return;
    }

    final now = DateTime.now();
    List<Progression> out;

    if (_range == "Semaine") {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // lundi
      out = _all.where((p) {
        final d = DateTime.parse(p.date);
        return !d.isBefore(DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day));
      }).toList();
    } else if (_range == "Année") {
      out = _all.where((p) => DateTime.parse(p.date).year == now.year).toList();
    } else {
      out = _all.where((p) {
        final d = DateTime.parse(p.date);
        return d.year == now.year && d.month == now.month;
      }).toList();
    }

    out.sort((a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));

    setState(() {
      _view = out;
      _totalCalories = _view.fold(0, (sum, p) => sum + p.caloriesBrulees);
      _totalDuree = _view.fold(0, (sum, p) => sum + p.dureeTotale);
    });
  }

  // === CARTES ===

  Widget _monthlyGoalCard() {
    final now = DateTime.now();
    final monthCalories = _all.where((p) {
      final d = DateTime.parse(p.date);
      return d.year == now.year && d.month == now.month;
    }).fold<int>(0, (sum, p) => sum + p.caloriesBrulees);

    final ratio = (_monthlyGoalKcal == 0) ? 0.0 : (monthCalories / _monthlyGoalKcal).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Objectif du mois",
              style: TextStyle(color: darkGreen, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: ratio,
            color: mainGreen,
            backgroundColor: Colors.grey.shade200,
            minHeight: 10,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 8),
          Text("$monthCalories / $_monthlyGoalKcal kcal", style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _lastPerformanceCard() {
    if (_all.isEmpty) return const SizedBox.shrink();
    final last = _all.last;
    final d = DateFormat('dd/MM/yyyy').format(DateTime.parse(last.date));
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: mainGreen.withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.military_tech, color: mainGreen),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Dernière performance",
                    style: TextStyle(fontWeight: FontWeight.bold, color: darkGreen)),
                const SizedBox(height: 4),
                Text("$d • ${last.dureeTotale} min • ${last.caloriesBrulees} kcal",
                    style: const TextStyle(color: Colors.black87, fontSize: 13)),
                Text(last.commentaire,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _computePerformanceScore() {
    if (_all.isEmpty) return 0;
    final total = _all.fold(0, (s, p) => s + p.caloriesBrulees);
    final duree = _all.fold(0, (s, p) => s + p.dureeTotale);
    final freq = _all.length;
    return ((total / 100) * 0.4 + (duree / 10) * 0.4 + freq * 0.2).round();
  }

  Widget _performanceScoreCard() {
    final score = _computePerformanceScore();
    final color = score > 80
        ? Colors.green
        : score > 50
            ? Colors.orange
            : Colors.redAccent;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Icon(Icons.star, color: color, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Score de performance : $score / 100",
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _achievementBadges() {
    final achievements = <String>[];
    if (_totalCalories > 3000) achievements.add("🔥 Brûleur de calories");
    if (_totalDuree > 500) achievements.add("⏱ Endurant");
    if (_view.length >= 10) achievements.add("🏋️‍♀️ Régulier");

    if (achievements.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Vos badges 🏅",
              style: TextStyle(color: darkGreen, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: achievements
                .map((b) => Chip(
                      label: Text(b),
                      backgroundColor: mainGreen.withOpacity(0.15),
                      labelStyle: const TextStyle(color: darkGreen, fontWeight: FontWeight.bold),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _forecastCard() {
    if (_view.isEmpty) return const SizedBox.shrink();
    final avgPerDay = _view.fold(0, (s, p) => s + p.caloriesBrulees) / _view.length;
    final daysInMonth = DateUtils.getDaysInMonth(DateTime.now().year, DateTime.now().month);
    final forecast = (avgPerDay * daysInMonth).round();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Text(
        "📈 Si tu gardes ce rythme, tu atteindras environ $forecast kcal ce mois-ci !",
        style: const TextStyle(color: darkGreen, fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Widget _intensityChart() {
    if (_all.isEmpty) return const SizedBox.shrink();

    final low = _all.where((p) => p.commentaire.contains("Faible")).fold<int>(0, (s, p) => s + p.caloriesBrulees);
    final mid = _all.where((p) => p.commentaire.contains("Moyenne")).fold<int>(0, (s, p) => s + p.caloriesBrulees);
    final high = _all.where((p) => p.commentaire.contains("Forte")).fold<int>(0, (s, p) => s + p.caloriesBrulees);

    // On enveloppe le chart avec RepaintBoundary pour la capture PDF
    return RepaintBoundary(
      key: _chartKey,
      child: Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black12.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 3)),
          ],
        ),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    switch (v.toInt()) {
                      case 0:
                        return const Text("Faible");
                      case 1:
                        return const Text("Moyenne");
                      case 2:
                        return const Text("Forte");
                    }
                    return const Text("");
                  },
                ),
              ),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            barGroups: [
              BarChartGroupData(x: 0, barRods: [
                BarChartRodData(toY: low.toDouble(), color: Colors.blueAccent, width: 18),
              ]),
              BarChartGroupData(x: 1, barRods: [
                BarChartRodData(toY: mid.toDouble(), color: Colors.orangeAccent, width: 18),
              ]),
              BarChartGroupData(x: 2, barRods: [
                BarChartRodData(toY: high.toDouble(), color: Colors.redAccent, width: 18),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // === ELEMENTS DIVERS ===

  Widget _statPill(IconData icon, String big, String label) {
    return Column(
      children: [
        Icon(icon, color: mainGreen),
        const SizedBox(height: 6),
        Text(big, style: const TextStyle(color: darkGreen, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
      ],
    );
  }

  Widget _rangeChips() {
    final items = const ["Semaine", "Mois", "Année"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items.map((e) {
        final sel = _range == e;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(
            label: Text(e),
            selected: sel,
            selectedColor: mainGreen,
            labelStyle: TextStyle(color: sel ? Colors.white : Colors.black87),
            onSelected: (_) {
              setState(() => _range = e);
              _applyRange();
            },
          ),
        );
      }).toList(),
    );
  }

  // === EXPORT PDF ===

  Future<Uint8List?> _captureChartPngBytes() async {
    try {
      final context = _chartKey.currentContext;
      if (context == null) return null;

      final renderObject = context.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) return null;

      final boundary = renderObject as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _exportPDF() async {
    final doc = pw.Document();
    final nowStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final chartBytes = await _captureChartPngBytes();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Suivi de progression', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.Text(nowStr, style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Divider(),

          // Stats
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _pdfStat('Calories', '$_totalCalories kcal'),
              _pdfStat('Durée', '$_totalDuree min'),
              _pdfStat('Séances', '${_view.length}'),
              _pdfStat('Score', '${_computePerformanceScore()} / 100'),
            ],
          ),

          pw.SizedBox(height: 16),
          pw.Text('Objectif du mois: $_monthlyGoalKcal kcal',
              style: pw.TextStyle(fontSize: 12, color: PdfColors.green900)),

          pw.SizedBox(height: 16),

          // Graphique
          if (chartBytes != null) ...[
            pw.Text('Répartition par intensité', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Image(pw.MemoryImage(chartBytes), height: 220, fit: pw.BoxFit.contain),
            pw.SizedBox(height: 16),
          ],

          // Liste
          pw.Text('Détails', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          ..._view.map((p) {
            final d = DateFormat('dd/MM/yyyy').format(DateTime.parse(p.date));
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(child: pw.Text('$d  •  ${p.commentaire}', style: const pw.TextStyle(fontSize: 10))),
                  pw.Text('${p.dureeTotale} min  •  ${p.caloriesBrulees} kcal', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            );
          }),
        ],
      ),
    );

    await Printing.sharePdf(bytes: await doc.save(), filename: 'progression_${DateTime.now().millisecondsSinceEpoch}.pdf');
  }

  pw.Widget _pdfStat(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.SizedBox(height: 2),
          pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
        ],
      ),
    );
  }

  // === BUILD ===

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: mainGreen,
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text("Exporter PDF"),
        onPressed: _exportPDF,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _rebuildFromSessions,
          child: ListView(
            children: [
              // HEADER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [mainGreen, darkGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.show_chart, color: Colors.white, size: 30),
                    SizedBox(height: 8),
                    Text("Suivi de Progression",
                        style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                    SizedBox(height: 6),
                    Text("Vos progrès sont calculés automatiquement",
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),

              // Stats
              if (_view.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(color: Colors.black12.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statPill(Icons.local_fire_department, "$_totalCalories", "Calories"),
                      _statPill(Icons.timer, "$_totalDuree", "Durée (min)"),
                      _statPill(Icons.fitness_center, "${_view.length}", "Séances"),
                    ],
                  ),
                ),

              // Filtres + cartes
              Padding(padding: const EdgeInsets.only(bottom: 6), child: _rangeChips()),
              _monthlyGoalCard(),
              _performanceScoreCard(),
              _achievementBadges(),
              _forecastCard(),
              _lastPerformanceCard(),

              // Graphique barres intensité (capturé pour PDF)
              _intensityChart(),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
