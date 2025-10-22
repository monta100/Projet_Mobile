import 'package:flutter/material.dart';
import '../Services/user_service.dart';

class VerificationScreen extends StatefulWidget {
  final String email;
  final UserService userService;

  const VerificationScreen({
    Key? key,
    required this.email,
    required this.userService,
  }) : super(key: key);

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() => _isLoading = true);
    final code = _codeController.text.trim();
    final success = await widget.userService.verifierCode(widget.email, code);
    setState(() => _isLoading = false);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compte vérifié.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code invalide ou expiré.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vérification')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              'Un code de vérification a été envoyé à ${widget.email}. Saisissez-le ci-dessous.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verify,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Vérifier'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  final code = await widget.userService.resendCode(
                    widget.email,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          code == null
                              ? 'Utilisateur introuvable'
                              : 'Code renvoyé (vérifier la console ou votre mail)',
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Renvoyer le code'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
