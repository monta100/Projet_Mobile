import 'package:flutter/material.dart';
import '../Entites/utilisateur.dart';
import '../Services/user_service.dart';
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
  String _roleSelection = 'Utilisateur';
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.utilisateur.nom);
    _prenomController = TextEditingController(text: widget.utilisateur.prenom);
    _emailController = TextEditingController(text: widget.utilisateur.email);
    _roleSelection = widget.utilisateur.role;
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
    edited.role = _roleSelection;
    final ok = await _userService.modifierUtilisateur(edited);
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Profil mis à jour' : 'Échec de la mise à jour'),
        ),
      );
      if (ok) Navigator.pop(context, true);
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

  Future<String> _downloadDiceBearAvatar(String seed) async {
    final style = 'adventurer';
    final url = Uri.parse(
      'https://api.dicebear.com/6.x/$style/png?seed=${Uri.encodeComponent(seed)}&size=512',
    );
    final resp = await http.get(url).timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200)
      throw Exception('Bad response ${resp.statusCode}');
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'dicebear_${seed.hashCode}.png';
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

    const totalSeeds = 60; // larger list

    final chosenSeed = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Choisir un avatar'),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.65,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: totalSeeds,
              itemBuilder: (c, index) {
                final seed = '$prenom-$nom-$index';
                final url =
                    'https://api.dicebear.com/6.x/adventurer/png?seed=${Uri.encodeComponent(seed)}&size=256';
                return GestureDetector(
                  onTap: () => Navigator.of(ctx).pop(seed),
                  child: ClipOval(
                    child: Image.network(
                      url,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          width: 120,
                          height: 120,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        );
                      },
                      errorBuilder: (ctx, err, st) => Container(
                        width: 120,
                        height: 120,
                        color: Colors.grey[300],
                        child: const Icon(Icons.error, size: 28),
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

    if (chosenSeed == null) return;

    try {
      final localPath = await _downloadDiceBearAvatar(chosenSeed);
      setState(() {
        widget.utilisateur.avatarPath = localPath;
        widget.utilisateur.avatarInitials = null;
        widget.utilisateur.avatarColor = null;
      });
      await _userService.modifierUtilisateur(widget.utilisateur);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Avatar mis à jour')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur en téléchargeant l\'avatar: $e')),
        );
    }
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
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Avatar supprimé')));
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

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Changer le mot de passe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Ancien mot de passe',
              ),
            ),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nouveau mot de passe',
              ),
            ),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmer nouveau mot de passe',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (newCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Les mots de passe ne correspondent pas'),
                  ),
                );
                return;
              }
              Navigator.of(ctx).pop(true);
            },
            child: const Text('Valider'),
          ),
        ],
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
      appBar: AppBar(title: const Text('Mon profil')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nomController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _prenomController,
                  decoration: const InputDecoration(labelText: 'Prénom'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  readOnly: true,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _roleSelection,
                  items: ['Utilisateur', 'Coach', 'Nutritionniste', 'Autre']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _roleSelection = v);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Type de compte',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildAvatar(),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.photo),
                          label: const Text('Choisir une photo'),
                        ),
                        const SizedBox(height: 6),
                        ElevatedButton.icon(
                          onPressed: _showAvatarPicker,
                          icon: const Icon(Icons.grid_view),
                          label: const Text('Choisir parmi avatars'),
                        ),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: _deleteAvatar,
                          child: const Text(
                            'Supprimer avatar',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Enregistrer'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _changePassword,
                    child: const Text('Changer le mot de passe'),
                  ),
                ),
                const SizedBox(height: 24),
                Divider(),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _isLoading ? null : _deleteAccount,
                    child: const Text(
                      'Supprimer mon compte',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
