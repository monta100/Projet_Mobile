import 'package:flutter/material.dart';
import '../Services/user_service.dart';
import '../Theme/app_colors.dart';
import '../l10n/app_localizations.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPwController = TextEditingController();
  final _confirmPwController = TextEditingController();
  final UserService _userService = UserService();

  bool _isLoading = false;
  bool _stepCode =
      false; // false: demander email, true: saisir code + nouveau mdp
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPwController.dispose();
    _confirmPwController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.enterEmail ??
                'Veuillez saisir votre email',
          ),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final ok = await _userService.requestPasswordReset(
        _emailController.text.trim(),
      );
      if (!mounted) return;
      if (ok) {
        setState(() => _stepCode = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.codeSentCheckEmail ??
                  'Code envoyé. Vérifiez votre email (ou la console en dev).',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.noAccountForEmail ??
                  "Aucun compte n'est associé à cet email.",
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)?.errorGeneric ?? 'Erreur'}: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final ok = await _userService.resetPassword(
        _emailController.text.trim(),
        _codeController.text.trim(),
        _newPwController.text,
      );
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.passwordResetSuccess ??
                  'Mot de passe réinitialisé. Vous pouvez vous connecter.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // revenir à la connexion
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.invalidOrExpiredCode ??
                  'Code invalide ou expiré.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)?.errorGeneric ?? 'Erreur'}: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.forgotPasswordTitle ??
              'Mot de passe oublié',
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  _stepCode
                      ? (AppLocalizations.of(context)?.forgotIntroCode ??
                            'Entrez le code reçu et votre nouveau mot de passe')
                      : (AppLocalizations.of(context)?.forgotIntroEmail ??
                            'Entrez votre email pour recevoir un code de réinitialisation'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),

                // Email (toujours visible)
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)?.email ?? 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (!_stepCode)
                      return null; // step email only, no strict validation here
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)?.enterEmail ??
                          'Veuillez saisir votre email';
                    }
                    if (!UserService().validerEmail(value)) {
                      return AppLocalizations.of(context)?.invalidEmail ??
                          'Format d\'email invalide';
                    }
                    return null;
                  },
                ),

                if (!_stepCode) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColors.primaryColor
                            : Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              AppLocalizations.of(context)?.sendCode ??
                                  'Envoyer le code',
                            ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText:
                          AppLocalizations.of(context)?.resetCodeLabel ??
                          'Code de réinitialisation',
                      prefixIcon: const Icon(Icons.verified_user),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)?.enterCodePrompt ??
                            'Veuillez saisir le code';
                      }
                      if (value.length < 4)
                        return AppLocalizations.of(context)?.invalidCode ??
                            'Code invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _newPwController,
                    obscureText: _obscureNew,
                    decoration: InputDecoration(
                      labelText:
                          AppLocalizations.of(context)?.newPasswordLabel ??
                          'Nouveau mot de passe',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNew ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () =>
                            setState(() => _obscureNew = !_obscureNew),
                      ),
                      border: const OutlineInputBorder(),
                      helperText:
                          AppLocalizations.of(context)?.passwordRules ??
                          'Au moins 8 caractères, une majuscule, une minuscule et un chiffre',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)?.enterPassword ??
                            'Veuillez saisir un mot de passe';
                      }
                      if (!UserService().validerMotDePasse(value)) {
                        return AppLocalizations.of(context)?.weakPassword ??
                            'Mot de passe trop faible';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPwController,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText:
                          AppLocalizations.of(context)?.confirmPasswordLabel ??
                          'Confirmer le mot de passe',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(
                              context,
                            )?.pleaseConfirmPassword ??
                            'Veuillez confirmer votre mot de passe';
                      }
                      if (value != _newPwController.text) {
                        return AppLocalizations.of(
                              context,
                            )?.passwordsDontMatch ??
                            'Les mots de passe ne correspondent pas';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColors.primaryColor
                            : Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              AppLocalizations.of(
                                    context,
                                  )?.resetPasswordButton ??
                                  'Réinitialiser le mot de passe',
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
