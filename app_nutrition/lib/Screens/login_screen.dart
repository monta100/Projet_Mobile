import 'package:flutter/material.dart';
import 'package:sign_in_button/sign_in_button.dart';
import '../Services/user_service.dart';
import '../Theme/app_colors.dart';
import '../Services/social_auth_service.dart';
import 'verification_screen.dart';
import '../Routs/app_routes.dart';
import '../Services/session_service.dart';
import '../l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final UserService _userService = UserService();
  final SocialAuthService _socialAuth = SocialAuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final utilisateur = await _userService.authentifier(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (utilisateur != null) {
          if (!utilisateur.isVerified) {
            // User exists and password is correct but not verified
            if (mounted) {
              showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(
                    AppLocalizations.of(context)?.notVerifiedTitle ??
                        'Compte non vérifié',
                  ),
                  content: Text(
                    AppLocalizations.of(context)?.notVerifiedBody ??
                        'Votre compte n\'est pas encore vérifié. Voulez-vous renvoyer le code de vérification ou saisir un code existant ?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        final code = await _userService.resendCode(
                          utilisateur.email,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                code == null
                                    ? (AppLocalizations.of(
                                            context,
                                          )?.userNotFound ??
                                          'Utilisateur introuvable')
                                    : (AppLocalizations.of(
                                            context,
                                          )?.codeResent ??
                                          'Code renvoyé (vérifier la console ou votre mail)'),
                              ),
                            ),
                          );
                        }
                      },
                      child: Text(
                        AppLocalizations.of(context)?.resendCode ??
                            'Renvoyer le code',
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VerificationScreen(
                              email: utilisateur.email,
                              userService: _userService,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        AppLocalizations.of(context)?.enterCode ??
                            'Saisir le code',
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(
                        AppLocalizations.of(context)?.cancel ?? 'Annuler',
                      ),
                    ),
                  ],
                ),
              );
            }
          } else {
            if (mounted) {
              // Persist session then navigate
              await SessionService().persistUser(utilisateur);
              // Navigation vers l'écran principal
              Navigator.pushReplacementNamed(
                context,
                '/home',
                arguments: utilisateur,
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)?.badCredentials ??
                      'Email ou mot de passe incorrect',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppLocalizations.of(context)?.appBarLogin ?? 'Connexion'}: $e',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final res = await _socialAuth.signInWithGoogle();
    setState(() => _isLoading = false);
    if (res == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.googleCancelledOrFailed ??
                  'Connexion Google annulée ou échouée',
            ),
          ),
        );
      }
      return;
    }
    // Mapper l'utilisateur Google vers notre modèle et naviguer
    final email = res['email'] as String?;
    // final name = res['name'] as String?; // Not used in sign-in only flow
    if (email == null || email.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.googleEmailMissing ??
                  "Impossible de récupérer l'email Google.",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Ne pas créer de compte ici: seulement connecter si l'utilisateur existe déjà
      final utilisateur = await _userService.obtenirUtilisateurParEmail(email);
      if (!mounted) return;
      if (utilisateur == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.noLocalAccountForGoogle ??
                  "Aucun compte local lié à cet email Google. Veuillez vous inscrire.",
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      if (!utilisateur.isVerified) {
        // Proposer la vérification comme dans le flux email/mot de passe
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              AppLocalizations.of(context)?.notVerifiedTitle ??
                  'Compte non vérifié',
            ),
            content: Text(
              AppLocalizations.of(context)?.notVerifiedBody ??
                  'Votre compte existe mais n\'est pas vérifié. Renvoyer le code ou saisir un code existant ?',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  final code = await _userService.resendCode(utilisateur.email);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          code == null
                              ? (AppLocalizations.of(context)?.userNotFound ??
                                    'Utilisateur introuvable')
                              : (AppLocalizations.of(context)?.codeResent ??
                                    'Code renvoyé (vérifier la console ou votre mail)'),
                        ),
                      ),
                    );
                  }
                },
                child: Text(
                  AppLocalizations.of(context)?.resendCode ??
                      'Renvoyer le code',
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VerificationScreen(
                        email: utilisateur.email,
                        userService: _userService,
                      ),
                    ),
                  );
                },
                child: Text(
                  AppLocalizations.of(context)?.enterCode ?? 'Saisir le code',
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(AppLocalizations.of(context)?.cancel ?? 'Annuler'),
              ),
            ],
          ),
        );
        return;
      }
      // Aller vers l'accueil
      await SessionService().persistUser(utilisateur);
      Navigator.pushReplacementNamed(context, '/home', arguments: utilisateur);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la connexion Google: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.appBarLogin ?? 'Connexion'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo ou titre de l'app
                Icon(
                  Icons.restaurant_menu,
                  size: 80,
                  color: isDark
                      ? AppColors.primaryColor
                      : Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 32),

                Text(
                  AppLocalizations.of(context)?.appTitle ?? 'App Nutrition',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 48),

                // Champ Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)?.email ?? 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)?.enterEmail ??
                          'Veuillez saisir votre email';
                    }
                    if (!_userService.validerEmail(value)) {
                      return AppLocalizations.of(context)?.invalidEmail ??
                          'Format d\'email invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Champ Mot de passe
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText:
                        AppLocalizations.of(context)?.password ??
                        'Mot de passe',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)?.enterPassword ??
                          'Veuillez saisir votre mot de passe';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Lien Mot de passe oublié
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.forgotPassword);
                    },
                    child: Text(
                      AppLocalizations.of(context)?.forgotPassword ??
                          'Mot de passe oublié ?',
                    ),
                  ),
                ),

                // Bouton de connexion
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.primaryColor
                          : Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            AppLocalizations.of(context)?.loginButton ??
                                'Se connecter',
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Boutons de connexion sociale
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: SignInButton(
                    Buttons.google,
                    text:
                        AppLocalizations.of(context)?.loginWithGoogle ??
                        'Se connecter avec Google',
                    onPressed: () {
                      if (_isLoading) return;
                      _handleGoogleSignIn();
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Lien vers l'inscription
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: Text(
                    AppLocalizations.of(context)?.noAccountRegister ??
                        'Pas encore de compte ? S\'inscrire',
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
