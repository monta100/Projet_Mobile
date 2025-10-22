import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';
import '../Entites/utilisateur.dart';
import '../Entites/objectif.dart';
import '../Services/objectif_service.dart';
import '../Services/rappel_service.dart';
import '../Services/user_service.dart';
import '../Routs/app_routes.dart';
import '../Theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  final Utilisateur utilisateur;
  
  const HomeScreen({super.key, required this.utilisateur});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ObjectifService _objectifService = ObjectifService();
  final RappelService _rappelService = RappelService();

  int _selectedIndex = 0;
  int _nombreRappelsNonLus = 0;
  double _progressionGlobale = 0.0;
  String _city = "";
  double? _temp;
  String _weatherDesc = "";
  String _quote = "";
  bool _loading = true;

  static const String _weatherKey = "5fd0004d433043c4aed98c1defc9528d";

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    final nombreRappels = await _rappelService.compterRappelsNonLus();
    final progression = await _objectifService.calculerProgressionGlobale();

    setState(() {
      _nombreRappelsNonLus = nombreRappels;
      _progressionGlobale = progression;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _loadData();
  }

  Future<void> _loadData() async {
    await _getWeather();
    await _getQuote();
    setState(() => _loading = false);
  }

  // --- ðŸŒ API MÃ©tÃ©o forcÃ©e sur Tunis ---
  Future<void> _getWeather() async {
    try {
      // Localisation forcÃ©e : Tunis ðŸ‡¹ðŸ‡³
      const double latitude = 36.8065;
      const double longitude = 10.1815;

      print("ðŸ“ Localisation forcÃ©e : $latitude, $longitude (Tunis)");

      final url = Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$_weatherKey&units=metric&lang=fr",
      );

      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          _city = data["name"];
          _temp = data["main"]["temp"].toDouble();
          _weatherDesc = data["weather"][0]["description"];
        });
      } else {
        setState(() {
          _city = "Tunis";
          _temp = 25;
          _weatherDesc = "ciel dÃ©gagÃ©";
        });
      }
    } catch (e) {
      print("âŒ Erreur mÃ©tÃ©o : $e");
      setState(() {
        _city = "Tunis";
        _temp = 25;
        _weatherDesc = "ciel dÃ©gagÃ©";
      });
    }
  }

  // --- ðŸ’¬ API Citations + traduction franÃ§aise ---
  Future<void> _getQuote() async {
    try {
      final url = Uri.parse("https://zenquotes.io/api/random");
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        String quote = data[0]["q"] + " â€” " + data[0]["a"];

        // Traduction automatique ðŸ‡«ðŸ‡·
        final translator = GoogleTranslator();
        var translation = await translator.translate(quote, to: 'fr');
        setState(() => _quote = translation.text);
      } else {
        _quote = "Le corps accomplit ce que lâ€™esprit croit ðŸ’«";
      }
    } catch (_) {
      _quote = "Fais un pas aujourdâ€™hui, ton futur te remerciera ðŸŒŸ";
    }
  }

  // --- ðŸ‹ï¸ Message de motivation selon mÃ©tÃ©o ---
  String _getMotivation() {
    if (_temp == null) return "PrÃ©pare-toi Ã  t'entraÃ®ner ! ðŸ’ª";
    if (_temp! >= 25) return "â˜€ï¸ ${_temp!.round()}Â°C - IdÃ©al pour courir dehors !";
    if (_temp! < 15) return "â„ï¸ ${_temp!.round()}Â°C - EntraÃ®ne-toi en intÃ©rieur ðŸ”¥";
    if (_weatherDesc.contains("pluie")) return "ðŸŒ§ï¸ Pluie - Opte pour une sÃ©ance indoor.";
    return "ðŸ’ª ${_temp!.round()}Â°C - Conditions parfaites pour bouger !";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.profil,
              arguments: widget.utilisateur,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildSmallAvatar(),
          ),
        ),
        title: Text('Bonjour, ${widget.utilisateur.prenom}'),
        actions: [
          // Badge pour les rappels
          if (_nombreRappelsNonLus > 0)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.rappels,
                      arguments: widget.utilisateur,
                    );
                  },
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_nombreRappelsNonLus',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            )
          else
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.rappels,
                  arguments: widget.utilisateur,
                );
              },
            ),

          // Menu profil
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'profil':
                  Navigator.pushNamed(
                    context,
                    AppRoutes.profil,
                    arguments: widget.utilisateur,
                  );
                  break;
                case 'supprimer':
                  // Confirm and delete
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Supprimer le compte'),
                      content: const Text(
                        'Voulez-vous vraiment supprimer votre compte ? Cette action est irrÃ©versible.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Supprimer'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    final us = UserService();
                    final success = await us.supprimerUtilisateur(
                      widget.utilisateur.id!,
                    );
                    if (success) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Compte supprimÃ©.')),
                        );
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.login,
                          (r) => false,
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ã‰chec de la suppression.'),
                          ),
                        );
                      }
                    }
                  }
                  break;
                case 'deconnexion':
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'profil',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Mon Profil'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'supprimer',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'Supprimer le compte',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'deconnexion',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('DÃ©connexion'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _getBodyContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: 'Objectifs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Rappels',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Statistiques',
          ),
        ],
      ),
    );
  }

  Widget _getBodyContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildObjectifsView();
      case 2:
        return _buildRappelsView();
      case 3:
        return _buildStatistiquesView();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte de bienvenue
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tableau de bord',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'RÃ´le: ${widget.utilisateur.role}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Progression globale
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Progression globale',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _progressionGlobale / 100,
                    backgroundColor: Colors.grey[300],
                  ),
                  const SizedBox(height: 8),
                  Text('${_progressionGlobale.toStringAsFixed(1)}%'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Actions rapides
          Text(
            'Actions rapides',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildActionCard(
                  'Nouvel Objectif',
                  Icons.add_task,
                  Colors.blue,
                  () => Navigator.pushNamed(
                    context,
                    AppRoutes.objectifsNouveau,
                    arguments: widget.utilisateur,
                  ),
                ),
                _buildActionCard(
                  'Nouveau Rappel',
                  Icons.add_alarm,
                  Colors.orange,
                  () => Navigator.pushNamed(
                    context,
                    AppRoutes.rappelsNouveau,
                    arguments: widget.utilisateur,
                  ),
                ),
                _buildActionCard(
                  'Mes Objectifs',
                  Icons.list_alt,
                  Colors.green,
                  () => Navigator.pushNamed(
                    context,
                    AppRoutes.objectifs,
                    arguments: widget.utilisateur,
                  ),
                ),
                // Show 'Mes clients' for common coach-role variants
                (() {
                  final role = widget.utilisateur.role.toLowerCase().trim();
                  final coachAliases = {
                    'coach',
                    'coatch',
                    'entraÃ®neur',
                    'entraineur',
                    'trainer',
                  };
                  return coachAliases.contains(role)
                      ? _buildActionCard(
                          'Mes Clients',
                          Icons.group,
                          Colors.teal,
                          () => Navigator.pushNamed(
                            context,
                            AppRoutes.mesClients,
                            arguments: widget.utilisateur,
                          ),
                        )
                      : const SizedBox.shrink();
                }()),
                _buildActionCard(
                  'Mes Rappels',
                  Icons.notifications_active,
                  Colors.purple,
                  () => Navigator.pushNamed(
                    context,
                    AppRoutes.rappels,
                    arguments: widget.utilisateur,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallAvatar() {
    // Small avatar for the AppBar
    if (widget.utilisateur.avatarPath != null &&
        widget.utilisateur.avatarPath!.isNotEmpty) {
      final file = File(widget.utilisateur.avatarPath!);
      if (file.existsSync()) {
        return CircleAvatar(radius: 18, backgroundImage: FileImage(file));
      }
    }

    final prenomValue = widget.utilisateur.prenom.trim();
    final nomValue = widget.utilisateur.nom.trim();
    final initials =
        (widget.utilisateur.avatarInitials != null &&
            widget.utilisateur.avatarInitials!.trim().isNotEmpty)
        ? widget.utilisateur.avatarInitials!.trim().toUpperCase()
        : ((prenomValue.isNotEmpty ? prenomValue[0] : '') +
                  (nomValue.isNotEmpty ? nomValue[0] : ''))
              .toUpperCase();
    final colorHex =
        widget.utilisateur.avatarColor ??
        _generateColorFromName('$prenomValue $nomValue');
    Color bg;
    try {
      bg = Color(int.parse('0xff' + colorHex.replaceFirst('#', '')));
    } catch (e) {
      bg = Colors.blueGrey;
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: bg,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _generateColorFromName(String name) {
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    final r = (hash & 0xFF0000) >> 16;
    final g = (hash & 0x00FF00) >> 8;
    final b = hash & 0x0000FF;
    return '#${(r & 0xFF).toRadixString(16).padLeft(2, '0')}${(g & 0xFF).toRadixString(16).padLeft(2, '0')}${(b & 0xFF).toRadixString(16).padLeft(2, '0')}';
  }

  Widget _buildObjectifsView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tÃªte avec bouton d'ajout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mes Objectifs',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.pushNamed(
                    context,
                    AppRoutes.objectifsNouveau,
                    arguments: widget.utilisateur,
                  );

                  // Si un objectif a Ã©tÃ© crÃ©Ã©, recharger les donnÃ©es
                  if (result == true) {
                    _chargerDonnees();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Nouvel Objectif'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Liste des objectifs (pour l'instant, un placeholder)
          Expanded(
            child: FutureBuilder<List<Objectif>>(
              future: _objectifService.obtenirObjectifsParUtilisateur(
                widget.utilisateur.id!,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }

                final objectifs = snapshot.data ?? [];

                if (objectifs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.track_changes,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun objectif dÃ©fini',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Commencez par crÃ©er votre premier objectif !',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: objectifs.length,
                  itemBuilder: (context, index) {
                    final objectif = objectifs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            '${(objectif.progression / objectif.valeurCible * 100).round()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          objectif.type,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cible: ${objectif.valeurCible}'),
                            Text('Progression: ${objectif.progression}'),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value:
                                  objectif.progression / objectif.valeurCible,
                              backgroundColor: Colors.grey[300],
                            ),
                          ],
                        ),
                        trailing: Text(
                          '${objectif.dateFixee.day}/${objectif.dateFixee.month}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRappelsView() {
    return const Center(child: Text('Vue des Rappels - Ã€ implÃ©menter'));
  }

  Widget _buildStatistiquesView() {
    return const Center(child: Text('Vue des Statistiques - Ã€ implÃ©menter'));
  }

  // --- ðŸŒ¤ï¸ IcÃ´ne mÃ©tÃ©o dynamique ---
  IconData _getWeatherIcon(String desc) {
    if (desc.contains("nuage")) return Icons.cloud;
    if (desc.contains("pluie")) return Icons.umbrella;
    if (desc.contains("orage")) return Icons.bolt;
    if (desc.contains("neige")) return Icons.ac_unit;
    if (desc.contains("soleil") || desc.contains("dÃ©gagÃ©")) return Icons.wb_sunny;
    return Icons.wb_cloudy;
  }
}
