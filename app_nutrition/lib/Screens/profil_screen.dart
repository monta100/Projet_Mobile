import 'package:flutter/material.dart';
import '../Entites/utilisateur.dart';
import '../Services/user_service.dart';
import '../Services/theme_service.dart';
import '../main.dart';
import '../Services/social_auth_service.dart';
import '../Services/session_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import '../Routs/app_routes.dart';
import '../l10n/app_localizations.dart';
// Bitmoji (SnapKit) intentionally not imported: user requested no login flow

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
          content: Text(
            ok
                ? (AppLocalizations.of(context)?.updateSuccess ??
                      'Profil mis à jour')
                : (AppLocalizations.of(context)?.updateFailed ??
                      'Échec de la mise à jour'),
          ),
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

  // ignore: unused_element
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

  Future<String> _downloadDiceBearAvatar(
    String seed, {
    Map<String, String>? options,
  }) async {
    // Détecter si l'on passe des options spécifiques à Avataaars (v6)
    final avataaarsKeys = <String>{
      'topType',
      'hairColor',
      'accessoriesType',
      'facialHairType',
      'facialHairColor',
      'clotheType',
      'clotheColor',
      'eyeType',
      'eyebrowType',
      'mouthType',
      'skinColor',
    };
    final hasAvataaarsOptions =
        options != null &&
        options.isNotEmpty &&
        options.keys.any((k) => avataaarsKeys.contains(k));

    // Forcer avataaars en v6 si des options avataaars sont présentes,
    // sinon utiliser adventurer en v7 (aucune option custom v6 passée)
    final style = hasAvataaarsOptions ? 'avataaars' : 'adventurer';
    final version = hasAvataaarsOptions ? '6.x' : '7.x';
    String urlString =
        'https://api.dicebear.com/$version/$style/png?seed=${Uri.encodeComponent(seed)}&size=256';
    if (hasAvataaarsOptions) {
      // N'ajouter des paramètres que pour avataaars (v6)
      final validParams = options.entries
          .where(
            (e) =>
                avataaarsKeys.contains(e.key) &&
                e.value != 'Blank' &&
                e.value != 'NoHair' &&
                e.value.isNotEmpty,
          )
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
    final fileName =
        'dicebear_${seed.hashCode}_${DateTime.now().millisecondsSinceEpoch}.png';
    final filePath = path.join(appDir.path, fileName);
    final file = File(filePath);
    await file.writeAsBytes(resp.bodyBytes);
    return file.path;
  }

  // Generic downloader removed since Bitmoji flow (no-login) is not supported

  Future<void> _showAvatarPicker() async {
    // Using username/seed from existing data; first/last name not required here.

    // Liste de seeds prédéfinis pour des avatars variés et rapides
    final List<String> predefinedSeeds = [
      'Ava',
      'Bella',
      'Charlie',
      'Diana',
      'Emma',
      'Felix',
      'Grace',
      'Henry',
      'Iris',
      'Jack',
      'Kate',
      'Luna',
      'Max',
      'Nora',
      'Oscar',
      'Penny',
      'Quinn',
      'Ruby',
      'Sam',
      'Tina',
      'Uma',
      'Victor',
      'Wendy',
      'Xander',
      'Yara',
      'Zoe',
      'Alex',
      'Ben',
      'Cora',
      'Drew',
      'Eve',
      'Finn',
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
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
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
                              child: const Icon(
                                Icons.person,
                                size: 32,
                                color: Colors.grey,
                              ),
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

  // Bitmoji flow removed: using Bitmoji assets without Snap login is not supported by Snap.

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
                        icon: Icon(
                          obscureOld ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () =>
                            setDialogState(() => obscureOld = !obscureOld),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[50],
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Requis' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newCtrl,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'Nouveau mot de passe',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNew ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () =>
                            setDialogState(() => obscureNew = !obscureNew),
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
                        icon: Icon(
                          obscureConfirm
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () => setDialogState(
                          () => obscureConfirm = !obscureConfirm,
                        ),
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
                      if (v != newCtrl.text)
                        return 'Les mots de passe ne correspondent pas';
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
        title: Text(AppLocalizations.of(context)?.profileTitle ?? 'Mon profil'),
        elevation: 0,
        actions: [
          IconButton(
            tooltip:
                AppLocalizations.of(context)?.logoutTooltip ?? 'Déconnexion',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Se déconnecter ?'),
                  content: const Text(
                    'Vous allez être déconnecté de votre session.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Déconnexion'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                // Sign out any social sessions (Google)
                try {
                  await SocialAuthService().signOutGoogle();
                } catch (_) {}
                // Clear persisted session
                try {
                  await SessionService().clear();
                } catch (_) {}
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (r) => false,
                );
              }
            },
          ),
        ],
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
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7),
          ],
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
          child: CircleAvatar(radius: 35, backgroundImage: FileImage(file)),
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
                Icon(
                  Icons.person_outline,
                  color: Theme.of(context).primaryColor,
                ),
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
                Icon(
                  Icons.photo_camera_outlined,
                  color: Theme.of(context).primaryColor,
                ),
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
            Center(child: _buildAvatar()),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 8.0;
                final maxWidth = constraints.maxWidth;
                // Try 3 per row first; if too tight, fall back to 2; else full width
                double itemWidth = (maxWidth - spacing * 2) / 3;
                if (itemWidth < 120) {
                  itemWidth = (maxWidth - spacing) / 2; // 2 per row
                  if (itemWidth < 140) {
                    itemWidth = maxWidth; // 1 per row on very small screens
                  }
                }

                ButtonStyle primaryBtnStyle = ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                );

                final buttons = <Widget>[
                  SizedBox(
                    width: itemWidth,
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_library, size: 18),
                      label: const Text('Galerie'),
                      style: primaryBtnStyle,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: ElevatedButton.icon(
                      onPressed: _showAvatarPicker,
                      icon: const Icon(Icons.grid_view, size: 18),
                      label: const Text('Avatars'),
                      style: primaryBtnStyle,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: OutlinedButton.icon(
                      onPressed: _deleteAvatar,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Supprimer'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ];

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  alignment: WrapAlignment.center,
                  children: buttons,
                );
              },
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
              : (isDark ? Colors.grey[800] : Colors.transparent),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (isDark ? Colors.white : Theme.of(context).primaryColor)
                : (isDark ? Colors.grey[600]! : Colors.grey[300]!),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? (isDark ? Colors.white : Theme.of(context).primaryColor)
                  : (isDark ? Colors.grey[300]! : Colors.grey[600]!),
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
                      : (isDark ? Colors.white : null),
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
            'Thème changé en ${mode == ThemeMode.light
                ? 'clair'
                : mode == ThemeMode.dark
                ? 'sombre'
                : 'système'}',
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
                Icon(
                  Icons.security_outlined,
                  color: Theme.of(context).primaryColor,
                ),
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
              subtitle: const Text(
                'Mettez à jour votre mot de passe pour sécuriser votre compte',
              ),
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
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                AppLocalizations.of(context)?.saveChanges ??
                    'Enregistrer les modifications',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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
          width: 1,
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
                  color: isDark ? Colors.red[400] : Colors.red[700],
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
                    color: isDark ? Colors.red[400]! : Colors.red[700]!,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)?.deleteMyAccount ??
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
