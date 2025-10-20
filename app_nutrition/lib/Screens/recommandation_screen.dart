import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:video_player/video_player.dart';

const Color mainGreen = Color(0xFF2ECC71);
const Color darkGreen = Color(0xFF1E8449);

class RecommandationScreen extends StatefulWidget {
  const RecommandationScreen({super.key});

  @override
  State<RecommandationScreen> createState() => _RecommandationScreenState();
}

class _RecommandationScreenState extends State<RecommandationScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _exercises = [];
  List<Map<String, dynamic>> _favorites = [];
  bool _loading = false;
  late Database _db;

  static const String _rapidApiKey =
      "9f76bdb9c4msh3d753e9081360e6p19aeb3jsn056d495db4d4";
  static const String _pexelsApiKey =
      "ZHzqshCx46ZLPO7LubxHf2z6hIBY3ke8dtukNqNJatJulqjYjUG1L8nx";

  String _selectedFilter = "bodyPart";
  final Map<String, String> _filterLabels = {
    "bodyPart": "Partie du corps",
    "target": "Muscle ciblé",
    "equipment": "Équipement",
  };

  // ✅ Suggestions statiques selon le filtre
  final Map<String, List<String>> _filterSuggestions = {
    "bodyPart": [
      "back",
      "cardio",
      "chest",
      "lower arms",
      "lower legs",
      "neck",
      "shoulders",
      "upper arms",
      "upper legs",
      "waist"
    ],
    "target": [
      "abs",
      "biceps",
      "triceps",
      "glutes",
      "calves",
      "hamstrings",
      "quadriceps",
      "traps",
      "delts",
      "lats",
      "pectorals",
      "adductors",
      "abductors",
      "forearms"
    ],
    "equipment": [
      "body weight",
      "barbell",
      "dumbbell",
      "kettlebell",
      "resistance band",
      "cable",
      "smith machine",
      "leverage machine",
      "medicine ball",
      "stability ball",
      "assisted",
      "rope"
    ]
  };

  final Map<String, Map<String, String>> _videoCache = {};

  @override
  void initState() {
    super.initState();
    _initDb();
  }

  Future<void> _initDb() async {
    final path = p.join(await getDatabasesPath(), 'favorites.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE favorites (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            target TEXT,
            equipment TEXT,
            bodyPart TEXT,
            gifUrl TEXT
          )
        ''');
      },
    );
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final data = await _db.query('favorites');
    setState(() {
      _favorites = data.cast<Map<String, dynamic>>();
    });
  }

  Future<void> _toggleFavorite(Map<String, dynamic> exercise) async {
    final exists = _favorites.any((f) => f['name'] == exercise['name']);
    if (exists) {
      await _db.delete('favorites', where: 'name = ?', whereArgs: [exercise['name']]);
    } else {
      await _db.insert('favorites', {
        'name': exercise['name'] ?? '',
        'target': exercise['target'] ?? '',
        'equipment': exercise['equipment'] ?? '',
        'bodyPart': exercise['bodyPart'] ?? '',
        'gifUrl': exercise['gifUrl'] ?? '',
      });
    }
    _loadFavorites();
  }

  bool _isFavorite(String name) => _favorites.any((f) => f['name'] == name);

  Future<void> fetchExercises(String query) async {
    if (query.isEmpty) return;
    setState(() => _loading = true);

    const host = "exercisedb.p.rapidapi.com";
    final url = Uri.parse("https://$host/exercises/$_selectedFilter/${query.toLowerCase()}");
    final headers = {
      "X-RapidAPI-Key": _rapidApiKey,
      "X-RapidAPI-Host": host,
    };

    try {
      final res = await http.get(url, headers: headers);
      if (res.statusCode == 200) {
        setState(() => _exercises = json.decode(res.body));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur API : ${res.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<Map<String, String>?> _fetchPexelsVideo(String query) async {
    final q = Uri.encodeQueryComponent("$query exercise");
    final url = Uri.parse("https://api.pexels.com/videos/search?query=$q&per_page=1");
    try {
      final res = await http.get(url, headers: {"Authorization": _pexelsApiKey});
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data["videos"] is List && data["videos"].isNotEmpty) {
          final v = data["videos"][0];
          return {"thumb": v["image"], "url": v["video_files"][0]["link"]};
        }
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, String>?> _getVideoForExercise(Map<String, dynamic> ex) async {
    final name = (ex['name'] ?? '').toString();
    if (name.isEmpty) return null;
    if (_videoCache.containsKey(name)) return _videoCache[name];
    final media = await _fetchPexelsVideo(name);
    if (media != null) _videoCache[name] = media;
    return media;
  }

  void _showFavoritesDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("❤️ Mes favoris"),
        content: _favorites.isEmpty
            ? const Text("Aucun favori enregistré.")
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _favorites.length,
                  itemBuilder: (context, index) {
                    final fav = _favorites[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: mainGreen.withOpacity(0.1),
                        backgroundImage: fav['gifUrl'] != null &&
                                fav['gifUrl'].toString().isNotEmpty
                            ? NetworkImage(
                                "https://api.allorigins.win/raw?url=${Uri.encodeComponent(fav['gifUrl'])}")
                            : null,
                        child: fav['gifUrl'] == null ||
                                fav['gifUrl'].toString().isEmpty
                            ? const Icon(Icons.fitness_center, color: mainGreen)
                            : null,
                      ),
                      title: Text(fav['name'] ?? 'Exercice'),
                      subtitle:
                          Text("Muscle : ${fav['target']} • ${fav['equipment']}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await _db.delete('favorites',
                              where: 'name = ?', whereArgs: [fav['name']]);
                          _loadFavorites();
                        },
                      ),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fermer"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _filterSuggestions[_selectedFilter]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Recommandations d'exercices"),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.white),
            onPressed: _showFavoritesDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      return suggestions.where((s) => s
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (String selection) {
                      _searchController.text = selection;
                      fetchExercises(selection);
                    },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      _searchController.text = controller.text;
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText:
                              "Rechercher (${_filterLabels[_selectedFilter]})",
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search, color: mainGreen),
                            onPressed: () => fetchExercises(controller.text.trim()),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onSubmitted: (v) => fetchExercises(v.trim()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _selectedFilter,
                  items: _filterLabels.entries
                      .map((e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedFilter = v!),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator(color: mainGreen)),
              )
            else
              Expanded(
                child: _exercises.isEmpty
                    ? const Center(
                        child: Text("Aucun exercice trouvé.",
                            style: TextStyle(color: Colors.black54)),
                      )
                    : ListView.builder(
                        itemCount: _exercises.length,
                        itemBuilder: (context, index) {
                          final ex = _exercises[index] as Map<String, dynamic>;
                          final isFav = _isFavorite(ex['name'] ?? '');
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            elevation: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FutureBuilder<Widget>(
                                  future: _loadExerciseMedia(ex),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return _placeholderMedia();
                                    }
                                    return snapshot.data ?? _placeholderMedia();
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              (ex['name'] ?? 'Exercice')
                                                  .toString()
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: darkGreen,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              isFav
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: isFav
                                                  ? Colors.red
                                                  : Colors.grey,
                                            ),
                                            onPressed: () =>
                                                _toggleFavorite(ex),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                          "🎯 Muscle : ${ex['target'] ?? 'Non spécifié'}"),
                                      Text(
                                          "⚙️ Équipement : ${ex['equipment'] ?? 'Aucun'}"),
                                      Text(
                                          "💪 Partie du corps : ${ex['bodyPart'] ?? 'Général'}"),
                                    ],
                                  ),
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

  Future<Widget> _loadExerciseMedia(Map<String, dynamic> ex) async {
    final gifUrl = ex['gifUrl'] ?? '';
    if (gifUrl.isNotEmpty) {
      final proxyUrl =
          "https://api.allorigins.win/raw?url=${Uri.encodeComponent(gifUrl)}";
      return ClipRRect(
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(16)),
        child: Image.network(
          proxyUrl,
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return FutureBuilder(
              future: _buildVideoThumb(ex),
              builder: (context, snap) =>
                  snap.data ?? _placeholderMedia(),
            );
          },
        ),
      );
    }
    return await _buildVideoThumb(ex);
  }

  Future<Widget> _buildVideoThumb(Map<String, dynamic> ex) async {
    final video = await _getVideoForExercise(ex);
    if (video == null) return _placeholderMedia();
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
          child: Image.network(video['thumb']!,
              height: 220, width: double.infinity, fit: BoxFit.cover),
        ),
        Positioned(
          child: InkWell(
            onTap: () => _showVideoPopup(video['url']!),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.play_arrow, color: Colors.white, size: 38),
            ),
          ),
        ),
      ],
    );
  }

  void _showVideoPopup(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        backgroundColor: Colors.black,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: _VideoPlayerPopup(url: url),
      ),
    );
  }

  Widget _placeholderMedia() => Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        alignment: Alignment.center,
        child:
            const Icon(Icons.image_not_supported, color: Colors.grey, size: 50),
      );
}

// --- popup lecteur vidéo ---
class _VideoPlayerPopup extends StatefulWidget {
  final String url;
  const _VideoPlayerPopup({required this.url});

  @override
  State<_VideoPlayerPopup> createState() => _VideoPlayerPopupState();
}

class _VideoPlayerPopupState extends State<_VideoPlayerPopup> {
  late VideoPlayerController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() => _ready = true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _ready ? _controller.value.aspectRatio : 16 / 9,
      child: _ready
          ? Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_controller),
                Positioned(
                  bottom: 10,
                  child: IconButton(
                    icon: Icon(
                      _controller.value.isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill,
                      color: Colors.white,
                      size: 50,
                    ),
                    onPressed: () {
                      setState(() {
                        _controller.value.isPlaying
                            ? _controller.pause()
                            : _controller.play();
                      });
                    },
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
    );
  }
}
