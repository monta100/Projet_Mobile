import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../water/water_page.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          _buildHeader(context),
          
          // Stats Overview (Optional - you can add metrics here)
          _buildQuickStats(context),
          
          // Features Grid
          Expanded(
            child: _buildFeaturesGrid(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bonjour !',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Comment vous sentez-vous aujourd\'hui ?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(context, 'Hydraté', '87%', Icons.water_drop),
          _buildStatItem(context, 'Énergie', '75%', Icons.energy_savings_leaf),
          _buildStatItem(context, 'Sommeil', '6.5h', Icons.night_shelter),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

 Widget _buildFeaturesGrid(BuildContext context) {
  final features = [
    _FeatureItem(
      title: 'Suivi Santé',
      subtitle: 'Suivi quotidien', // Shortened
      icon: Icons.health_and_safety,
      color: Colors.blue,
      route: '/journal',
    ),
    _FeatureItem(
      title: 'Hydratation',
      subtitle: 'Gérez votre eau',
      icon: Icons.water_drop,
      color: Colors.lightBlue,
      page: const WaterPage(),
    ),
    _FeatureItem(
      title: 'Métabolisme',
      subtitle: 'Votre profil', // Shortened
      icon: Icons.person,
      color: Colors.green,
      route: '/profile',
    ),
    _FeatureItem(
      title: 'Note Book',
      subtitle: 'Bien-être mental',
      icon: Icons.self_improvement,
      color: Colors.purple,
      route: '/wellbeing',
    ),
    _FeatureItem(
      title: 'AI Doctor',
      subtitle: 'Assistance IA', // Shortened
      icon: Icons.perm_device_information_rounded,
      color: Colors.orange,
      route: '/ai-doctor',
    ),
    
  ];

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2, // Increased from 1.1 to give more vertical space
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        return _FeatureCard(feature: features[index]);
      },
    ),
  );
}
  // Old tile method kept for reference, but we're using the new grid system
  Widget _tile(BuildContext ctx, String title, IconData icon, String? route, {Widget? page}) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => route != null
            ? Navigator.pushNamed(ctx, route)
            : Navigator.push(ctx, MaterialPageRoute(builder: (_) => page!)),
      ),
    );
  }
}

class _FeatureItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? route;
  final Widget? page;

  _FeatureItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.route,
    this.page,
  });
}

class _FeatureCard extends StatelessWidget {
  final _FeatureItem feature;

  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (feature.route != null) {
            Navigator.pushNamed(context, feature.route!);
          } else if (feature.page != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => feature.page!),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon with background
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: feature.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  feature.icon,
                  size: 24,
                  color: feature.color,
                ),
              ),
              
              // Text content
             // In the _FeatureCard build method, update the text section:
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      feature.title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      maxLines: 2, // Ensure max 2 lines
      overflow: TextOverflow.ellipsis,
    ),
    const SizedBox(height: 4),
    Text(
      feature.subtitle,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      maxLines: 2, // Ensure max 2 lines
      overflow: TextOverflow.ellipsis,
    ),
  ],
),
            ],
          ),
        ),
      ),
    );
  }
}