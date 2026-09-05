import 'package:flutter/material.dart';

import '../services/onele_api.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Changement de mot de passe. L'ancien est exigé : un téléphone laissé
/// déverrouillé ne doit pas suffire à prendre le compte.
class MotDePasseScreen extends StatefulWidget {
  const MotDePasseScreen({super.key});

  @override
  State<MotDePasseScreen> createState() => _MotDePasseScreenState();
}

class _MotDePasseScreenState extends State<MotDePasseScreen> {
  final _api = OneleApi();
  final _formKey = GlobalKey<FormState>();
  final _actuel = TextEditingController();
  final _nouveau = TextEditingController();
  final _confirmation = TextEditingController();

  bool _masqueActuel = true;
  bool _masqueNouveau = true;
  bool _envoi = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    // La jauge suit la frappe : la force se voit pendant qu'on tape,
    // pas au moment où le serveur refuse.
    _nouveau.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _actuel.dispose();
    _nouveau.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  /// Force estimée sur quatre crans : longueur d'abord, variété ensuite.
  /// Le serveur, lui, n'exige que huit caractères — la jauge conseille.
  int get _force {
    final mdp = _nouveau.text;
    if (mdp.isEmpty) return 0;
    // Dès la première frappe la jauge bouge : muette, elle passerait pour
    // cassée alors qu'elle dit seulement « pas encore assez ».
    var score = 1;
    if (mdp.length >= 8) score++;
    if (mdp.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(mdp) && RegExp(r'[a-z]').hasMatch(mdp)) {
      score++;
    }
    if (RegExp(r'[0-9]').hasMatch(mdp) || RegExp(r'[^A-Za-z0-9]').hasMatch(mdp)) {
      score++;
    }
    // Sous huit caractères le serveur refusera : la jauge ne promet jamais
    // mieux que « faible », quelle que soit la variété des caractères.
    if (mdp.length < 8) return 1;
    return score.clamp(1, 4);
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _envoi = true;
      _erreur = null;
    });

    try {
      await _api.changerMotDePasse(
        actuel: _actuel.text,
        nouveau: _nouveau.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mot de passe modifié. Les autres appareils sont déconnectés.'),
        ),
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
      appBar: AppBar(title: const Text('Mot de passe')),
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
                  TextFormField(
                    controller: _actuel,
                    obscureText: _masqueActuel,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe actuel',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: _OeilBouton(
                        masque: _masqueActuel,
                        onTap: () =>
                            setState(() => _masqueActuel = !_masqueActuel),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 26),
                  const TitreSection(libelle: 'NOUVEAU'),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _nouveau,
                    obscureText: _masqueNouveau,
                    decoration: InputDecoration(
                      labelText: 'Nouveau mot de passe',
                      prefixIcon: const Icon(Icons.lock_reset, size: 20),
                      suffixIcon: _OeilBouton(
                        masque: _masqueNouveau,
                        onTap: () =>
                            setState(() => _masqueNouveau = !_masqueNouveau),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 8)
                        ? 'Au moins 8 caractères'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _Jauge(force: _force),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _confirmation,
                    obscureText: _masqueNouveau,
                    decoration: const InputDecoration(
                      labelText: 'Confirmer le nouveau mot de passe',
                      prefixIcon: Icon(Icons.check_circle_outline, size: 20),
                    ),
                    validator: (v) =>
                        v != _nouveau.text ? 'La confirmation ne correspond pas' : null,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.brandLine),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          size: 18,
                          color: AppColors.brand,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Vos autres appareils seront déconnectés. '
                            'Celui-ci reste ouvert.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: AppColors.brand,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  PrimaryButton(
                    libelle: 'Changer le mot de passe',
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
}

class _OeilBouton extends StatelessWidget {
  final bool masque;
  final VoidCallback onTap;

  const _OeilBouton({required this.masque, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: masque ? 'Afficher' : 'Masquer',
      icon: Icon(
        masque ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 20,
        color: AppColors.inkMuted,
      ),
    );
  }
}

/// Quatre segments qui se remplissent — la longueur de la barre dit la force,
/// la couleur ne fait que la doubler, et le libellé la nomme.
class _Jauge extends StatelessWidget {
  final int force;

  const _Jauge({required this.force});

  static const _libelles = ['', 'Trop court', 'Correct', 'Bon', 'Solide'];
  static const _teintes = [
    AppColors.line2,
    AppColors.danger,
    AppColors.warn,
    AppColors.brand,
    AppColors.ok,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 1; i <= 4; i++) ...[
          if (i > 1) const SizedBox(width: 5),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              height: 4,
              decoration: BoxDecoration(
                color: i <= force ? _teintes[force] : AppColors.line,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
        const SizedBox(width: 11),
        SizedBox(
          width: 54,
          child: Text(
            _libelles[force],
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _teintes[force],
            ),
          ),
        ),
      ],
    );
  }
}
