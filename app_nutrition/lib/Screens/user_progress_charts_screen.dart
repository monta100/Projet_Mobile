import 'package:flutter/material.dart';
import '../Entites/utilisateur.dart';
import '../Entites/progress_stats.dart';
import '../Services/progress_service.dart';

class UserProgressChartsScreen extends StatefulWidget {
  final Utilisateur utilisateur;

  const UserProgressChartsScreen({
    Key? key,
    required this.utilisateur,
  }) : super(key: key);

  @override
  State<UserProgressChartsScreen> createState() => _UserProgressChartsScreenState();
}

class _UserProgressChartsScreenState extends State<UserProgressChartsScreen>
    with TickerProviderStateMixin {
  final ProgressService _progressService = ProgressService();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  ProgressStats? _weeklyStats;
  ProgressStats? _monthlyStats;
  String _selectedPeriod = 'week';
  String _selectedChart = 'weight';
  bool _isLoading = true;

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
    
    _loadChartData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadChartData() async {
    setState(() => _isLoading = true);
    try {
      final weeklyStats = await _progressService.getProgressStats(widget.utilisateur.id!, 'week');
      final monthlyStats = await _progressService.getProgressStats(widget.utilisateur.id!, 'month');
      
      setState(() {
        _weeklyStats = weeklyStats;
        _monthlyStats = monthlyStats;
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

  ProgressStats? get _currentStats {
    return _selectedPeriod == 'week' ? _weeklyStats : _monthlyStats;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Graphiques de Progression'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChartData,
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
                    _buildPeriodSelector(),
                    const SizedBox(height: 20),
                    _buildChartSelector(),
                    const SizedBox(height: 20),
                    _buildSelectedChart(),
                    const SizedBox(height: 30),
                    _buildSummaryCards(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
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
      child: Row(
        children: [
          Expanded(
            child: _buildPeriodTab('week', 'Cette semaine'),
          ),
          Expanded(
            child: _buildPeriodTab('month', 'Ce mois'),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(String period, String label) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildChartSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
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
      child: Row(
        children: [
          Expanded(
            child: _buildChartTab('weight', 'Poids', Icons.monitor_weight),
          ),
          Expanded(
            child: _buildChartTab('workout', 'Entraînements', Icons.fitness_center),
          ),
          Expanded(
            child: _buildChartTab('consistency', 'Consistance', Icons.trending_up),
          ),
        ],
      ),
    );
  }

  Widget _buildChartTab(String chart, String label, IconData icon) {
    final isSelected = _selectedChart == chart;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChart = chart;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedChart() {
    final stats = _currentStats;
    if (stats == null) {
      return _buildEmptyChart();
    }

    switch (_selectedChart) {
      case 'weight':
        return _buildWeightChart(stats);
      case 'workout':
        return _buildWorkoutChart(stats);
      case 'consistency':
        return _buildConsistencyChart(stats);
      default:
        return _buildEmptyChart();
    }
  }

  Widget _buildWeightChart(ProgressStats stats) {
    if (stats.weightTrends.isEmpty) {
      return _buildEmptyChart('Aucune donnée de poids disponible');
    }

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
          Row(
            children: [
              Icon(Icons.monitor_weight, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Évolution du Poids',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 200,
            child: _buildSimpleLineChart(stats.weightTrends.map((t) => t.weight).toList()),
          ),
          const SizedBox(height: 16),
          _buildWeightChartLegend(stats),
        ],
      ),
    );
  }

  Widget _buildWorkoutChart(ProgressStats stats) {
    if (stats.workoutTrends.isEmpty) {
      return _buildEmptyChart('Aucune donnée d\'entraînement disponible');
    }

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
          Row(
            children: [
              Icon(Icons.fitness_center, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Fréquence des Entraînements',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 200,
            child: _buildBarChart(stats.workoutTrends.map((t) => t.duration).toList()),
          ),
          const SizedBox(height: 16),
          _buildWorkoutChartLegend(stats),
        ],
      ),
    );
  }

  Widget _buildConsistencyChart(ProgressStats stats) {
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
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.blue, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Consistance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildConsistencyRadialChart(stats),
          const SizedBox(height: 16),
          _buildConsistencyStats(stats),
        ],
      ),
    );
  }

  Widget _buildSimpleLineChart(List<double> values) {
    if (values.isEmpty) return const SizedBox();
    
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;
    
    return CustomPaint(
      size: const Size(double.infinity, 200),
      painter: LineChartPainter(
        values: values,
        maxValue: maxValue,
        minValue: minValue,
        range: range,
        color: Colors.green,
      ),
    );
  }

  Widget _buildBarChart(List<double> values) {
    if (values.isEmpty) return const SizedBox();
    
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    
    return CustomPaint(
      size: const Size(double.infinity, 200),
      painter: BarChartPainter(
        values: values,
        maxValue: maxValue,
        color: Colors.orange,
      ),
    );
  }

  Widget _buildConsistencyRadialChart(ProgressStats stats) {
    return Container(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: CircularProgressIndicator(
              value: (stats.consistencyRate / 100).clamp(0.0, 1.0),
              strokeWidth: 12,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                stats.consistencyRate >= 70 ? Colors.green : 
                stats.consistencyRate >= 50 ? Colors.orange : Colors.red,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${stats.consistencyRate.toInt()}%',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              Text(
                'Consistance',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeightChartLegend(ProgressStats stats) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem('Début', '${stats.startWeight?.toStringAsFixed(1) ?? 'N/A'} kg', Colors.grey),
        _buildLegendItem('Actuel', '${stats.endWeight?.toStringAsFixed(1) ?? 'N/A'} kg', Colors.green),
        _buildLegendItem('Changement', stats.weightChangeFormatted, 
          stats.isWeightLoss ? Colors.green : stats.isWeightGain ? Colors.red : Colors.grey),
      ],
    );
  }

  Widget _buildWorkoutChartLegend(ProgressStats stats) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem('Total', '${stats.totalWorkouts}', Colors.orange),
        _buildLegendItem('Durée moy.', stats.averageDurationFormatted, Colors.blue),
        _buildLegendItem('Calories', '${stats.totalCaloriesBurned.toInt()}', Colors.red),
      ],
    );
  }

  Widget _buildConsistencyStats(ProgressStats stats) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem('Jours actifs', '${stats.workoutDays}', Colors.blue),
        _buildLegendItem('Série actuelle', '${stats.currentStreak}', Colors.red),
        _buildLegendItem('Plus longue', '${stats.longestStreak}', Colors.green),
      ],
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    final stats = _currentStats;
    if (stats == null) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Résumé',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Entraînements',
                '${stats.totalWorkouts}',
                Icons.fitness_center,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Calories',
                '${stats.totalCaloriesBurned.toInt()}',
                Icons.local_fire_department,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Durée',
                stats.durationFormatted,
                Icons.timer,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Consistance',
                '${stats.consistencyRate.toInt()}%',
                Icons.trending_up,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
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

  Widget _buildEmptyChart([String? message]) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.show_chart,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message ?? 'Aucune donnée disponible',
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
}

// Painters personnalisés pour les graphiques
class LineChartPainter extends CustomPainter {
  final List<double> values;
  final double maxValue;
  final double minValue;
  final double range;
  final Color color;

  LineChartPainter({
    required this.values,
    required this.maxValue,
    required this.minValue,
    required this.range,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    final stepX = size.width / (values.length - 1);

    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final normalizedValue = range > 0 ? (values[i] - minValue) / range : 0.5;
      final y = size.height - (normalizedValue * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Dessiner les points
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final normalizedValue = range > 0 ? (values[i] - minValue) / range : 0.5;
      final y = size.height - (normalizedValue * size.height);

      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class BarChartPainter extends CustomPainter {
  final List<double> values;
  final double maxValue;
  final Color color;

  BarChartPainter({
    required this.values,
    required this.maxValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final barWidth = size.width / values.length;
    final barSpacing = barWidth * 0.2;

    for (int i = 0; i < values.length; i++) {
      final barHeight = maxValue > 0 ? (values[i] / maxValue) * size.height : 0;
      final x = i * barWidth + barSpacing;
      final y = size.height - barHeight;

      final rect = Rect.fromLTWH(x, y, barWidth - 2 * barSpacing, barHeight.toDouble());
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
