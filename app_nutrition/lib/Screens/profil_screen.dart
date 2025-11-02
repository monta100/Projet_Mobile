import 'package:flutter/material.dart';
import '../Entites/utilisateur.dart';
import '../Services/user_service.dart';
import '../Services/theme_service.dart';
import '../main.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import '../Routs/app_routes.dart';

class ProfilScreen extends StatefulWidget {
  final Utilisateur utilisateur;
  const ProfilScreen({Key? key, required this.utilisateur}) : super(key: key);

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();

  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _emailController;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.utilisateur.nom);
    _prenomController = TextEditingController(text: widget.utilisateur.prenom);
    _emailController = TextEditingController(text: widget.utilisateur.email);
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final edited = widget.utilisateur;
    edited.nom = _nomController.text.trim();
    edited.prenom = _prenomController.text.trim();
    edited.role = 'User'; // Toujours 'User' maintenant
    final ok = await _userService.modifierUtilisateur(edited);
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Profil mis à jour' : 'Échec de la mise à jour'),
        ),
      );
      if (ok) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (picked == null) return;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName =
          'avatar_${widget.utilisateur.id ?? DateTime.now().millisecondsSinceEpoch}${path.extension(picked.path)}';
      final destPath = '${appDir.path}/$fileName';
      final savedFile = await File(picked.path).copy(destPath);

      setState(() {
        widget.utilisateur.avatarPath = savedFile.path;
        widget.utilisateur.avatarColor ??= _generateColorFromName(
          widget.utilisateur.prenom + ' ' + widget.utilisateur.nom,
        );
      });
      await _userService.modifierUtilisateur(widget.utilisateur);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur en enregistrant l\'image: $e')),
        );
    }
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

  Color _hexToColor(String colorHex) {
    try {
      return Color(int.parse('0xff' + colorHex.replaceFirst('#', '')));
    } catch (e) {
      return Colors.blueGrey;
    }
  }

  Widget _buildAvatar() {
    if (widget.utilisateur.avatarPath != null &&
        widget.utilisateur.avatarPath!.isNotEmpty) {
      final file = File(widget.utilisateur.avatarPath!);
      if (file.existsSync()) {
        return CircleAvatar(radius: 40, backgroundImage: FileImage(file));
      }
    }

    final prenomValue = _prenomController.text.trim().isNotEmpty
        ? _prenomController.text.trim()
        : widget.utilisateur.prenom.trim();
    final nomValue = _nomController.text.trim().isNotEmpty
        ? _nomController.text.trim()
        : widget.utilisateur.nom.trim();

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
      radius: 40,
      backgroundColor: bg,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<String> _downloadDiceBearAvatar(String seed, {Map<String, String>? options}) async {
    final style = options != null && options.isNotEmpty ? 'avataaars' : 'adventurer';
    // Construire l'URL avec les options de personnalisation - utiliser v6 pour avataaars
    final version = (options != null && options.isNotEmpty && style == 'avataaars') ? '6.x' : '7.x';
    String urlString = 'https://api.dicebear.com/$version/$style/png?seed=${Uri.encodeComponent(seed)}&size=256';
    if (options != null && options.isNotEmpty) {
          final validParams = options.entries
          .where((e) => 
              e.value != 'blank' &&
              e.value != 'noHair' &&
              e.value.isNotEmpty)
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .toList();
      if (validParams.isNotEmpty) {
        urlString += '&${validParams.join('&')}';
      }
    }
    final url = Uri.parse(urlString);
    final resp = await http.get(url).timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200)
      throw Exception('Bad response ${resp.statusCode}');
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'dicebear_${seed.hashCode}_${DateTime.now().millisecondsSinceEpoch}.png';
    final filePath = path.join(appDir.path, fileName);
    final file = File(filePath);
    await file.writeAsBytes(resp.bodyBytes);
    return file.path;
  }

  Future<void> _showAvatarPicker() async {
    final prenom = _prenomController.text.trim().isNotEmpty
        ? _prenomController.text.trim()
        : widget.utilisateur.prenom.trim();
    final nom = _nomController.text.trim().isNotEmpty
        ? _nomController.text.trim()
        : widget.utilisateur.nom.trim();

    // Liste de seeds prédéfinis pour des avatars variés et rapides
    final List<String> predefinedSeeds = [
      'Ava', 'Bella', 'Charlie', 'Diana', 'Emma', 'Felix', 'Grace', 'Henry',
      'Iris', 'Jack', 'Kate', 'Luna', 'Max', 'Nora', 'Oscar', 'Penny',
      'Quinn', 'Ruby', 'Sam', 'Tina', 'Uma', 'Victor', 'Wendy', 'Xander',
      'Yara', 'Zoe', 'Alex', 'Ben', 'Cora', 'Drew', 'Eve', 'Finn',
    ];

    final chosenSeed = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
        return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
          title: const Text('Choisir un avatar'),
          content: SizedBox(
            width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.6,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
                  itemCount: predefinedSeeds.length,
              itemBuilder: (c, index) {
                    final seed = predefinedSeeds[index];
                    // Utiliser une taille plus petite (128 au lieu de 256) pour charger plus rapidement
                final url =
                        'https://api.dicebear.com/6.x/adventurer/png?seed=${Uri.encodeComponent(seed)}&size=128';
                return GestureDetector(
                  onTap: () => Navigator.of(ctx).pop(seed),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey[300]!, width: 1),
                        ),
                  child: ClipOval(
                    child: Image.network(
                      url,
                            width: 80,
                            height: 80,
                      fit: BoxFit.cover,
                            cacheWidth: 128, // Cache avec résolution optimisée
                            cacheHeight: 128,
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                              final value = progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                  : null;
                        return Container(
                                width: 80,
                                height: 80,
                          alignment: Alignment.center,
                                child: CircularProgressIndicator(
                            strokeWidth: 2,
                                  value: value,
                          ),
                        );
                      },
                      errorBuilder: (ctx, err, st) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[200],
                              child: const Icon(Icons.person, size: 32, color: Colors.grey),
                            ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Annuler'),
            ),
          ],
            );
          },
        );
      },
    );

    if (chosenSeed == null) return;

    try {
      final localPath = await _downloadDiceBearAvatar(chosenSeed);
      setState(() {
        widget.utilisateur.avatarPath = localPath;
        widget.utilisateur.avatarInitials = null;
        widget.utilisateur.avatarColor = null;
      });
      await _userService.modifierUtilisateur(widget.utilisateur);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Avatar mis à jour')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur en téléchargeant l\'avatar: $e')),
        );
    }
  }

  Future<void> _showAvatarCustomizer() async {
    // Options de personnalisation disponibles pour avataaars v7
    // IMPORTANT: Pour v7, utiliser camelCase minuscule (première lettre minuscule)
    // Liste réduite pour éviter la limite de requêtes (429)
    final topTypes = [
      'noHair', 'shortHairShortFlat', 'shortHairShortRound', 'shortHairShortCurly',
      'shortHairFrizzle', 'shortHairShaggyMullet', 'shortHairShortWaved', 'shortHairSides',
      'shortHairTheCaesar', 'shortHairTheCaesarSidePart', 'longHairBob', 'longHairBun',
      'longHairCurly', 'longHairCurvy', 'longHairDreads', 'longHairFrida',
      'longHairFro', 'longHairFroBand', 'longHairNotTooLong', 'longHairMiaWallace',
      'longHairStraight', 'longHairStraight2', 'longHairStraightStrand', 'eyepatch',
      'hat', 'hijab', 'turban', 'winterHat1', 'winterHat2', 'winterHat3', 'winterHat4'
    ];
    
    final hairColors = ['auburn', 'black', 'blonde', 'blondeGolden', 'brown', 'brownDark', 'platinum', 'red', 'silverGray'];
    
    final accessoriesTypes = ['blank', 'kurt', 'prescription01', 'prescription02', 'round', 'sunglasses', 'wayfarers'];
    
    final facialHairTypes = ['blank', 'beardMedium', 'beardLight', 'beardMagestic', 'moustacheFancy', 'moustacheMagnum'];
    
    final facialHairColors = ['auburn', 'black', 'blonde', 'blondeGolden', 'brown', 'brownDark', 'platinum', 'red'];
    
    final clotheTypes = ['blazerShirt', 'blazerSweater', 'collarSweater', 'graphicShirt', 'hoodie', 'overall', 'shirtCrewNeck', 'shirtScoopNeck', 'shirtVNeck'];
    
    final clotheColors = ['black', 'blue01', 'blue02', 'blue03', 'gray01', 'gray02', 'heather', 'pastelBlue', 'pastelGreen', 'pastelOrange', 'pastelRed', 'pastelYellow', 'pink', 'red', 'white'];
    
    final eyeTypes = ['close', 'cry', 'default', 'dizzy', 'eyeRoll', 'happy', 'hearts', 'side', 'squint', 'surprised', 'wink', 'winkWacky'];
    
    final eyebrowTypes = ['angry', 'angryNatural', 'default', 'defaultNatural', 'flatNatural', 'raisedExcited', 'raisedExcitedNatural', 'sadConcerned', 'sadConcernedNatural', 'unibrowNatural', 'upDown', 'upDownNatural'];
    
    final mouthTypes = ['concerned', 'default', 'disbelief', 'eating', 'grimace', 'sad', 'screamOpen', 'serious', 'smile', 'tongue', 'twinkle', 'vomit'];
    
    final skinColors = ['tanned', 'yellow', 'pale', 'light', 'brown', 'darkBrown', 'black'];

    // Valeurs par défaut (camelCase minuscule pour v7)
    String selectedTop = 'shortHairShortFlat';
    String selectedHairColor = 'brown';
    String selectedAccessories = 'blank';
    String selectedFacialHair = 'blank';
    String selectedFacialHairColor = 'brown';
    String selectedClothe = 'shirtCrewNeck';
    String selectedClotheColor = 'blue01';
    String selectedEye = 'default';
    String selectedEyebrow = 'default';
    String selectedMouth = 'smile';
    String selectedSkinColor = 'light';

    final seed = '${widget.utilisateur.prenom}${widget.utilisateur.nom}${DateTime.now().millisecondsSinceEpoch}';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Fonction pour obtenir toutes les options avec leurs valeurs actuelles
            Map<String, String> getAllOptions() {
              final options = <String, String>{};
              // Toujours inclure toutes les options avec leurs valeurs actuelles
              if (selectedTop != 'noHair') {
                options['topType'] = selectedTop;
                options['hairColor'] = selectedHairColor;
              }
              if (selectedAccessories != 'blank') {
                options['accessoriesType'] = selectedAccessories;
              }
              if (selectedFacialHair != 'blank') {
                options['facialHairType'] = selectedFacialHair;
                options['facialHairColor'] = selectedFacialHairColor;
              }
              // Options toujours présentes
              options['clotheType'] = selectedClothe;
              options['clotheColor'] = selectedClotheColor;
              options['eyeType'] = selectedEye;
              options['eyebrowType'] = selectedEyebrow;
              options['mouthType'] = selectedMouth;
              options['skinColor'] = selectedSkinColor;
              return options;
            }
            
            Map<String, String> buildAvatarOptions() {
              return getAllOptions();
            }

            String buildAvatarUrl() {
              final opts = buildAvatarOptions();
              // Utiliser l'API v7 avec PNG (Flutter ne supporte pas SVG nativement)
              String url = 'https://api.dicebear.com/7.x/avataaars/png?seed=${Uri.encodeComponent(seed)}&size=200';
              final validParams = opts.entries
                  .where((e) => 
                      e.value != 'blank' &&
                      e.value != 'noHair' &&
                      e.value.isNotEmpty)
                  .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
                  .toList();
              if (validParams.isNotEmpty) {
                url += '&${validParams.join('&')}';
              }
              debugPrint('Avatar preview URL: $url');
              return url;
            }

            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                width: double.maxFinite,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.edit, color: Colors.white),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Personnaliser votre avatar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(ctx).pop(null),
                          ),
                        ],
                      ),
                    ),
                    // Preview
                    Container(
                      padding: const EdgeInsets.all(20),
                      color: Colors.grey[100],
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey[300]!, width: 2),
                          ),
                          child: ClipOval(
                            child: Image.network(
                              buildAvatarUrl(),
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                              cacheWidth: 200,
                              cacheHeight: 200,
                              key: ValueKey(buildAvatarUrl()), // Force refresh quand l'URL change
                              loadingBuilder: (ctx, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  width: 150,
                                  height: 150,
                                  alignment: Alignment.center,
                                  child: const CircularProgressIndicator(),
                                );
                              },
                              errorBuilder: (ctx, err, st) => Container(
                                width: 150,
                                height: 150,
                                color: Colors.grey[300],
                                child: const Icon(Icons.error, size: 50),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Options scrollables
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildOptionSection(
                              'Cheveux',
                              selectedTop,
                              topTypes,
                              (value) => setDialogState(() => selectedTop = value),
                              setDialogState,
                              optionType: 'topType',
                              seed: seed,
                              getAllOptions: getAllOptions,
                            ),
                            if (selectedTop != 'noHair' && 
                                selectedTop != 'eyepatch' && 
                                selectedTop != 'hat' && 
                                selectedTop != 'hijab' && 
                                selectedTop != 'turban' && 
                                !selectedTop.startsWith('winterHat'))
                              _buildOptionSection(
                                'Couleur des cheveux',
                                selectedHairColor,
                                hairColors,
                                (value) => setDialogState(() => selectedHairColor = value),
                                setDialogState,
                                optionType: 'hairColor',
                                seed: seed,
                                getAllOptions: getAllOptions,
                              ),
                            _buildOptionSection(
                              'Lunettes / Accessoires',
                              selectedAccessories,
                              accessoriesTypes,
                              (value) => setDialogState(() => selectedAccessories = value),
                              setDialogState,
                              optionType: 'accessoriesType',
                              seed: seed,
                              getAllOptions: getAllOptions,
                            ),
                            _buildOptionSection(
                              'Barbe / Moustache',
                              selectedFacialHair,
                              facialHairTypes,
                              (value) => setDialogState(() => selectedFacialHair = value),
                              setDialogState,
                              optionType: 'facialHairType',
                              seed: seed,
                              getAllOptions: getAllOptions,
                            ),
                            if (selectedFacialHair != 'blank')
                              _buildOptionSection(
                                'Couleur barbe/moustache',
                                selectedFacialHairColor,
                                facialHairColors,
                                (value) => setDialogState(() => selectedFacialHairColor = value),
                                setDialogState,
                                optionType: 'facialHairColor',
                                seed: seed,
                                getAllOptions: getAllOptions,
                              ),
                            _buildOptionSection(
                              'Vêtements',
                              selectedClothe,
                              clotheTypes,
                              (value) => setDialogState(() => selectedClothe = value),
                              setDialogState,
                              optionType: 'clotheType',
                              seed: seed,
                              getAllOptions: getAllOptions,
                            ),
                            _buildOptionSection(
                              'Couleur vêtements',
                              selectedClotheColor,
                              clotheColors,
                              (value) => setDialogState(() => selectedClotheColor = value),
                              setDialogState,
                              optionType: 'clotheColor',
                              seed: seed,
                              getAllOptions: getAllOptions,
                            ),
                            _buildOptionSection(
                              'Yeux',
                              selectedEye,
                              eyeTypes,
                              (value) => setDialogState(() => selectedEye = value),
                              setDialogState,
                              optionType: 'eyeType',
                              seed: seed,
                              getAllOptions: getAllOptions,
                            ),
                            _buildOptionSection(
                              'Sourcils',
                              selectedEyebrow,
                              eyebrowTypes,
                              (value) => setDialogState(() => selectedEyebrow = value),
                              setDialogState,
                              optionType: 'eyebrowType',
                              seed: seed,
                              getAllOptions: getAllOptions,
                            ),
                            _buildOptionSection(
                              'Bouche',
                              selectedMouth,
                              mouthTypes,
                              (value) => setDialogState(() => selectedMouth = value),
                              setDialogState,
                              optionType: 'mouthType',
                              seed: seed,
                              getAllOptions: getAllOptions,
                            ),
                            _buildOptionSection(
                              'Couleur de peau',
                              selectedSkinColor,
                              skinColors,
                              (value) => setDialogState(() => selectedSkinColor = value),
                              setDialogState,
                              optionType: 'skinColor',
                              seed: seed,
                              getAllOptions: getAllOptions,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Actions
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.grey[300]!)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(null),
                            child: const Text('Annuler'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(buildAvatarOptions()),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: const Text('Valider'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null || result.isEmpty) return;

    try {
      setState(() => _isLoading = true);
      final localPath = await _downloadDiceBearAvatar(seed, options: result);
      setState(() {
        widget.utilisateur.avatarPath = localPath;
        widget.utilisateur.avatarInitials = null;
        widget.utilisateur.avatarColor = null;
      });
      await _userService.modifierUtilisateur(widget.utilisateur);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar personnalisé mis à jour')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur en téléchargeant l\'avatar: $e')),
        );
      }
    }
  }

  Widget _buildOptionSection(
    String title,
    String selectedValue,
    List<String> options,
    Function(String) onChanged,
    StateSetter setState, {
    String? optionType,
    Map<String, String>? currentOptions,
    String? seed,
    Map<String, String>? allSelectedOptions,
    required Map<String, String> Function() getAllOptions,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: options.length,
              cacheExtent: 200,
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = selectedValue == option;
                
                // Construire l'URL de prévisualisation pour cette option
                // Utiliser une seed simplifiée pour le cache
                final optionSeed = 'prev_$option';
                
                // Obtenir toutes les options actuelles
                final previewOptions = Map<String, String>.from(getAllOptions());
                
                // Remplacer uniquement l'option en cours de prévisualisation
                if (optionType != null) {
                  if (optionType == 'topType') {
                    if (option == 'noHair') {
                      previewOptions.remove('topType');
                      previewOptions.remove('hairColor');
                    } else {
                      previewOptions['topType'] = option;
                      if (!previewOptions.containsKey('hairColor')) {
                        previewOptions['hairColor'] = 'brown';
                      }
                    }
                  } else if (optionType == 'hairColor') {
                    previewOptions['hairColor'] = option;
                    if (!previewOptions.containsKey('topType')) {
                      previewOptions['topType'] = 'shortHairShortFlat';
                    }
                  } else if (optionType == 'accessoriesType') {
                    if (option == 'blank') {
                      previewOptions.remove('accessoriesType');
                    } else {
                      previewOptions['accessoriesType'] = option;
                    }
                  } else if (optionType == 'facialHairType') {
                    if (option == 'blank') {
                      previewOptions.remove('facialHairType');
                      previewOptions.remove('facialHairColor');
                    } else {
                      previewOptions['facialHairType'] = option;
                      if (!previewOptions.containsKey('facialHairColor')) {
                        previewOptions['facialHairColor'] = 'brown';
                      }
                    }
                  } else if (optionType == 'facialHairColor') {
                    previewOptions['facialHairColor'] = option;
                    if (!previewOptions.containsKey('facialHairType')) {
                      previewOptions['facialHairType'] = 'beardMedium';
                    }
                  } else {
                    previewOptions[optionType] = option;
                  }
                }
                
                // S'assurer d'avoir les options de base
                if (!previewOptions.containsKey('clotheType')) previewOptions['clotheType'] = 'shirtCrewNeck';
                if (!previewOptions.containsKey('clotheColor')) previewOptions['clotheColor'] = 'blue01';
                if (!previewOptions.containsKey('eyeType')) previewOptions['eyeType'] = 'default';
                if (!previewOptions.containsKey('eyebrowType')) previewOptions['eyebrowType'] = 'default';
                if (!previewOptions.containsKey('mouthType')) previewOptions['mouthType'] = 'smile';
                if (!previewOptions.containsKey('skinColor')) previewOptions['skinColor'] = 'light';
                
                // Construire l'URL - utiliser l'API v7 avec PNG (Flutter ne supporte pas SVG nativement)
                String previewUrl = 'https://api.dicebear.com/7.x/avataaars/png?seed=${Uri.encodeComponent(optionSeed)}&size=100';
                
                // Construire les paramètres pour v7 (format camelCase minuscule)
                final params = <String>[];
                for (final entry in previewOptions.entries) {
                  final value = entry.value;
                  if (value != 'blank' && 
                      value != 'noHair' &&
                      value.isNotEmpty) {
                    // Pour v7, utiliser le format correct
                    params.add('${entry.key}=${Uri.encodeComponent(value)}');
                  }
                }
                
                if (params.isNotEmpty) {
                  previewUrl += '&${params.join('&')}';
                }
                
                // Debug: afficher l'URL pour les premiers éléments
                if (index < 3) {
                  debugPrint('Preview URL [$index]: $previewUrl');
                }
                
                return GestureDetector(
                  onTap: () {
                    onChanged(option);
                    setState(() {});
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected 
                          ? Theme.of(context).primaryColor 
                          : Colors.grey[300]!,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        ClipOval(
                          child: Image.network(
                            previewUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            cacheWidth: 100,
                            cacheHeight: 100,
                            key: ValueKey('$optionType$option${previewUrl.hashCode}'),
                            loadingBuilder: (ctx, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[200],
                                alignment: Alignment.center,
                                child: const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            },
                            errorBuilder: (ctx, err, st) {
                              // Debug: afficher l'erreur
                              debugPrint('Erreur chargement preview [$optionType][$option]: $err');
                              debugPrint('URL: $previewUrl');
                              return Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person, size: 40, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatOptionName(String option) {
    // Convertir camelCase en texte lisible avec traductions
    final translations = {
      'noHair': 'Sans cheveux',
      'blank': 'Aucun',
      'default': 'Par défaut',
      'defaultNatural': 'Naturel par défaut',
      'smile': 'Sourire',
      'happy': 'Heureux',
      'sad': 'Triste',
      'angry': 'En colère',
      'concerned': 'Inquiet',
      'disbelief': 'Incrédulité',
      'eating': 'Mange',
      'grimace': 'Grimace',
      'screamOpen': 'Crie',
      'serious': 'Sérieux',
      'tongue': 'Langue',
      'twinkle': 'Pétille',
      'vomit': 'Vomit',
      'close': 'Fermé',
      'cry': 'Pleure',
      'dizzy': 'Étourdi',
      'eyeRoll': 'Yeux qui roulent',
      'hearts': 'Cœurs',
      'side': 'Sur le côté',
      'squint': 'Plisse',
      'surprised': 'Surpris',
      'wink': 'Clin d\'œil',
      'winkWacky': 'Clin d\'œil fou',
      'prescription01': 'Lunettes 1',
      'prescription02': 'Lunettes 2',
      'round': 'Rondes',
      'sunglasses': 'Lunettes de soleil',
      'wayfarers': 'Wayfarer',
      'kurt': 'Kurt',
      'beardMedium': 'Barbe moyenne',
      'beardLight': 'Barbe légère',
      'beardMagestic': 'Barbe majestueuse',
      'moustacheFancy': 'Moustache élégante',
      'moustacheMagnum': 'Moustache magnum',
      // Couleurs
      'auburn': 'Auburn',
      'black': 'Noir',
      'blonde': 'Blond',
      'blondeGolden': 'Blond doré',
      'brown': 'Brun',
      'brownDark': 'Brun foncé',
      'platinum': 'Platine',
      'red': 'Rouge',
      'silverGray': 'Gris argenté',
      // Couleurs de vêtements
      'blue01': 'Bleu 1',
      'blue02': 'Bleu 2',
      'blue03': 'Bleu 3',
      'gray01': 'Gris 1',
      'gray02': 'Gris 2',
      'heather': 'Heather',
      'pastelBlue': 'Bleu pastel',
      'pastelGreen': 'Vert pastel',
      'pastelOrange': 'Orange pastel',
      'pastelRed': 'Rouge pastel',
      'pastelYellow': 'Jaune pastel',
      'pink': 'Rose',
      'white': 'Blanc',
      // Couleurs de peau
      'tanned': 'Bronzé',
      'yellow': 'Jaune',
      'pale': 'Pâle',
      'light': 'Clair',
      'darkBrown': 'Brun foncé',
    };
    
    if (translations.containsKey(option)) {
      return translations[option]!;
    }
    
    // Convertir camelCase en texte lisible
    String formatted = option
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) => '${match.group(1)} ${match.group(2)}')
        .toLowerCase();
    
    // Capitaliser la première lettre
    if (formatted.isNotEmpty) {
      formatted = formatted[0].toUpperCase() + formatted.substring(1);
    }
    
    return formatted;
  }

  Future<void> _deleteAvatar() async {
    final currentPath = widget.utilisateur.avatarPath;
    setState(() {
      widget.utilisateur.avatarPath = null;
      widget.utilisateur.avatarInitials = null;
      widget.utilisateur.avatarColor = null;
    });

    try {
      if (currentPath != null && currentPath.isNotEmpty) {
        final f = File(currentPath);
        if (await f.exists()) await f.delete();
      }
      await _userService.modifierUtilisateur(widget.utilisateur);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Avatar supprimé')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: $e')),
        );
    }
  }

  Future<void> _changePassword() async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.lock_outline, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text('Changer le mot de passe'),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
                  TextFormField(
              controller: oldCtrl,
                    obscureText: obscureOld,
                    decoration: InputDecoration(
                labelText: 'Ancien mot de passe',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(obscureOld ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setDialogState(() => obscureOld = !obscureOld),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[50],
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
              controller: newCtrl,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                labelText: 'Nouveau mot de passe',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[50],
                      helperText: 'Au moins 6 caractères',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requis';
                      if (v.length < 6) return 'Minimum 6 caractères';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
              controller: confirmCtrl,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                labelText: 'Confirmer le mot de passe',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[50],
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requis';
                      if (v != newCtrl.text) return 'Les mots de passe ne correspondent pas';
                      return null;
                    },
                  ),
                ],
              ),
            ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
            ElevatedButton(
            onPressed: () {
                if (formKey.currentState!.validate()) {
              Navigator.of(ctx).pop(true);
                }
            },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            child: const Text('Valider'),
          ),
        ],
        ),
      ),
    );

    if (result != true) return;
    setState(() => _isLoading = true);
    final ok = await _userService.changerMotDePasse(
      widget.utilisateur.id!,
      oldCtrl.text,
      newCtrl.text,
    );
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'Mot de passe changé' : 'Échec: mauvais mot de passe',
          ),
        ),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: const Text(
          'Voulez-vous vraiment supprimer votre compte ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    setState(() => _isLoading = true);
    final ok = await _userService.supprimerUtilisateur(widget.utilisateur.id!);
    if (mounted) {
      setState(() => _isLoading = false);
      if (ok) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Compte supprimé')));
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (r) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de la suppression')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
          key: _formKey,
          child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeaderSection(),
                    const SizedBox(height: 24),
                    _buildPersonalInfoSection(),
                    const SizedBox(height: 24),
                    _buildAvatarSection(),
                    const SizedBox(height: 24),
                    _buildThemeSection(),
                    const SizedBox(height: 16),
                    _buildSecuritySection(),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                    const SizedBox(height: 16),
                    _buildDangerZone(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildAvatarLarge(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.utilisateur.prenom} ${widget.utilisateur.nom}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.email, color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      widget.utilisateur.email,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarLarge() {
    if (widget.utilisateur.avatarPath != null &&
        widget.utilisateur.avatarPath!.isNotEmpty) {
      final file = File(widget.utilisateur.avatarPath!);
      if (file.existsSync()) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: CircleAvatar(
            radius: 35,
            backgroundImage: FileImage(file),
          ),
        );
      }
    }

    final prenomValue = _prenomController.text.trim().isNotEmpty
        ? _prenomController.text.trim()
        : widget.utilisateur.prenom.trim();
    final nomValue = _nomController.text.trim().isNotEmpty
        ? _nomController.text.trim()
        : widget.utilisateur.nom.trim();

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

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: CircleAvatar(
        radius: 35,
        backgroundColor: bg,
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Informations personnelles',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
                TextFormField(
                  controller: _nomController,
              decoration: InputDecoration(
                labelText: 'Nom',
                prefixIcon: const Icon(Icons.badge_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[50],
              ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
            const SizedBox(height: 16),
                TextFormField(
                  controller: _prenomController,
              decoration: InputDecoration(
                labelText: 'Prénom',
                prefixIcon: const Icon(Icons.account_circle_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[50],
              ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
            const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[50],
              ),
                  readOnly: true,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                Row(
                  children: [
                Icon(Icons.photo_camera_outlined, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Photo de profil',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Center(
              child: _buildAvatar(),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: const Text('Galerie'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                        ElevatedButton.icon(
                          onPressed: _showAvatarPicker,
                  icon: const Icon(Icons.grid_view, size: 18),
                  label: const Text('Avatars'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAvatarCustomizer,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Personnaliser'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                          onPressed: _deleteAvatar,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Supprimer'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildThemeSection() {
    return FutureBuilder<ThemeMode>(
      future: ThemeService.getThemeMode(),
      builder: (context, snapshot) {
        final currentTheme = snapshot.data ?? ThemeMode.system;
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      currentTheme == ThemeMode.dark 
                          ? Icons.dark_mode 
                          : currentTheme == ThemeMode.light
                              ? Icons.light_mode
                              : Icons.brightness_auto,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Thème',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildThemeOption(
                  'Clair',
                  Icons.light_mode,
                  ThemeMode.light,
                  currentTheme == ThemeMode.light,
                  () => _changeTheme(ThemeMode.light),
                ),
                const SizedBox(height: 12),
                _buildThemeOption(
                  'Sombre',
                  Icons.dark_mode,
                  ThemeMode.dark,
                  currentTheme == ThemeMode.dark,
                  () => _changeTheme(ThemeMode.dark),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    String label,
    IconData icon,
    ThemeMode mode,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? Colors.grey[700]!
                  : Theme.of(context).primaryColor.withOpacity(0.2))
              : (isDark
                  ? Colors.grey[800]
                  : Colors.transparent),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (isDark
                    ? Colors.white
                    : Theme.of(context).primaryColor)
                : (isDark
                    ? Colors.grey[600]!
                    : Colors.grey[300]!),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? (isDark
                      ? Colors.white
                      : Theme.of(context).primaryColor)
                  : (isDark
                      ? Colors.grey[300]!
                      : Colors.grey[600]!),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? (isDark ? Colors.white : Theme.of(context).primaryColor)
                      : (isDark
                          ? Colors.white
                          : null),
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: isDark ? Colors.white : Theme.of(context).primaryColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeTheme(ThemeMode mode) async {
    await ThemeService.setThemeMode(mode);
    AppThemeNotifier.changeTheme(mode);
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Thème changé en ${mode == ThemeMode.light ? 'clair' : mode == ThemeMode.dark ? 'sombre' : 'système'}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildSecuritySection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security_outlined, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Sécurité',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lock_outline),
              title: const Text('Changer le mot de passe'),
              subtitle: const Text('Mettez à jour votre mot de passe pour sécuriser votre compte'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _isLoading ? null : _changePassword,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
                    child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              )
            : const Text(
                'Enregistrer les modifications',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildDangerZone() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 2,
      color: isDark ? Colors.red[900]?.withOpacity(0.3) : Colors.red[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.red[700]! : Colors.red[200]!, 
          width: 1
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded, 
                  color: isDark ? Colors.red[400] : Colors.red[700]
                ),
                const SizedBox(width: 8),
                Text(
                  'Zone de danger',
                  style: TextStyle(
                    color: isDark ? Colors.red[400] : Colors.red[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
                ),
                const SizedBox(height: 12),
            Text(
              'La suppression de votre compte est irréversible. Toutes vos données seront définitivement supprimées.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white : Colors.black87,
                height: 1.4,
              ),
            ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
              child: OutlinedButton(
                    onPressed: _isLoading ? null : _deleteAccount,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(
                    color: isDark ? Colors.red[400]! : Colors.red[700]!
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                    child: Text(
                      'Supprimer mon compte',
                      style: TextStyle(
                        color: isDark ? Colors.red[400] : Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
        ),
      ),
    );
  }
}
