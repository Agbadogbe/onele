import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_provider.dart';
import '../services/onele_api.dart';
import '../widgets/common.dart';

/// Modification de sa propre fiche. Le rôle n'y figure pas : il relève de
/// l'administration, et un champ grisé ne ferait qu'inviter à le demander.
class ModifierProfilScreen extends StatefulWidget {
  const ModifierProfilScreen({super.key});

  @override
  State<ModifierProfilScreen> createState() => _ModifierProfilScreenState();
}

class _ModifierProfilScreenState extends State<ModifierProfilScreen> {
  final _api = OneleApi();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nom;
  late final TextEditingController _prenom;
  late final TextEditingController _email;
  late final TextEditingController _telephone;

  bool _envoi = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nom = TextEditingController(text: user?.nom ?? '');
    _prenom = TextEditingController(text: user?.prenom ?? '');
    _email = TextEditingController(text: user?.email ?? '');
    _telephone = TextEditingController(text: user?.telephone ?? '');
  }

  @override
  void dispose() {
    _nom.dispose();
    _prenom.dispose();
    _email.dispose();
    _telephone.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _envoi = true;
      _erreur = null;
    });

    try {
      final maj = await _api.modifierProfil(
        nom: _nom.text.trim(),
        prenom: _prenom.text.trim(),
        email: _email.text.trim(),
        telephone: _telephone.text.trim().isEmpty
            ? null
            : _telephone.text.trim(),
      );
      if (!mounted) return;
      context.read<AuthProvider>().remplacerUtilisateur(maj);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fiche mise à jour.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _envoi = false;
        _erreur = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final marge = margeLaterale(context, minimum: 20);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes informations')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(marge, 8, marge, 34),
          children: [
            ZoneLecture(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_erreur != null) ...[
                    ErrorBanner(message: _erreur!),
                    const SizedBox(height: 18),
                  ],
                  const TitreSection(libelle: 'IDENTITÉ'),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _prenom,
                          decoration: const InputDecoration(
                            labelText: 'Prénom',
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: _requis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _nom,
                          decoration: const InputDecoration(labelText: 'Nom'),
                          textCapitalization: TextCapitalization.words,
                          validator: _requis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  const TitreSection(libelle: 'CONTACT'),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline, size: 20),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Email invalide'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _telephone,
                    decoration: const InputDecoration(
                      labelText: 'Téléphone',
                      helperText: 'Facultatif',
                      prefixIcon: Icon(Icons.phone_outlined, size: 20),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 30),
                  PrimaryButton(
                    libelle: 'Enregistrer',
                    icone: Icons.check_rounded,
                    chargement: _envoi,
                    onPressed: _envoi ? null : _enregistrer,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String? _requis(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Champ requis' : null;
}
