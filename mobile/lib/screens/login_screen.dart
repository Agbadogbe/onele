import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;
  bool _masque = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_email.text.trim(), _password.text);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      if (!ok) _error = auth.lastError ?? 'Connexion impossible.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: barreEtatClaire,
      child: Scaffold(
        backgroundColor: AppColors.rail,
        body: Column(
          children: [
            // Bandeau de marque sur fond « aurore »
            AuroraPanel(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    margeLaterale(context, minimum: 28),
                    ecranBas(context) ? 14 : 26,
                    margeLaterale(context, minimum: 28),
                    ecranBas(context) ? 16 : 30,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const BrandStamp(taille: 40, surFondSombre: true),
                          const SizedBox(width: 12),
                          const Wordmark(taille: 21, couleur: AppColors.railInk),
                        ],
                      ),
                      if (!ecranBas(context)) ...[
                        const SizedBox(height: 22),
                        Text(
                          'Vos congés,\nsans la paperasse.',
                          style: titreDisplay(
                            taille: 31,
                            couleur: AppColors.railInk,
                            graisse: FontWeight.w700,
                            hauteur: 1.18,
                            espacement: -0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Déposez vos demandes et suivez leur validation.',
                          style: TextStyle(
                            color: AppColors.railMuted,
                            fontSize: 14.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Feuille de formulaire
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    margeLaterale(context, minimum: 24),
                    ecranBas(context) ? 20 : 30,
                    margeLaterale(context, minimum: 24),
                    32,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Connexion', style: titreDisplay(taille: 23)),
                        const SizedBox(height: 4),
                        const Text(
                          'Utilisez le compte fourni par votre service RH.',
                          style: TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (_error != null) ...[
                          ErrorBanner(message: _error!),
                          const SizedBox(height: 18),
                        ],

                        TextFormField(
                          controller: _email,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.mail_outline, size: 20),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          validator: (v) => (v == null || !v.contains('@'))
                              ? 'Email invalide'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _masque
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                                color: AppColors.inkMuted,
                              ),
                              onPressed: () =>
                                  setState(() => _masque = !_masque),
                              tooltip: _masque ? 'Afficher' : 'Masquer',
                            ),
                          ),
                          obscureText: _masque,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) =>
                              _submitting ? null : _submit(),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Mot de passe requis'
                              : null,
                        ),
                        const SizedBox(height: 24),

                        PrimaryButton(
                          libelle: 'Se connecter',
                          onPressed: _submitting ? null : _submit,
                          chargement: _submitting,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _submitting
                              ? null
                              : () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                ),
                          child: const Text('Créer un compte'),
                        ),
                      ],
                    ),
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
