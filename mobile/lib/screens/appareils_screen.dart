import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/session.dart';
import '../services/onele_api.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Les sessions ouvertes sur le compte. Un appareil perdu se ferme d'ici,
/// sans changer de mot de passe.
class AppareilsScreen extends StatefulWidget {
  const AppareilsScreen({super.key});

  @override
  State<AppareilsScreen> createState() => _AppareilsScreenState();
}

class _AppareilsScreenState extends State<AppareilsScreen> {
  final _api = OneleApi();
  List<SessionOuverte>? _sessions;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final liste = await _api.sessions();
      if (mounted) {
        setState(() {
          _sessions = liste;
          _erreur = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _erreur = e.toString());
    }
  }

  Future<void> _fermer(SessionOuverte session) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Fermer cette session ?'),
        content: Text(
          '${session.libelle} devra se reconnecter pour accéder au compte.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
    if (confirme != true) return;

    try {
      await _api.revoquerSession(session.id);
      await _charger();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final marge = margeLaterale(context, minimum: 20);
    final sessions = _sessions;

    return Scaffold(
      appBar: AppBar(title: const Text('Appareils connectés')),
      body: RefreshIndicator(
        onRefresh: _charger,
        color: AppColors.brand,
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
                  Text(
                    'Chaque connexion — mobile ou web — ouvre une session. '
                    'Fermez celles que vous ne reconnaissez pas.',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (sessions == null)
                    Column(
                      children: const [
                        SqueletteCarte(),
                        SizedBox(height: 10),
                        SqueletteCarte(),
                      ],
                    )
                  else
                    for (final (i, session) in sessions.indexed) ...[
                      if (i > 0) const SizedBox(height: 10),
                      EntreeAnimee(
                        rang: i,
                        child: _CarteSession(
                          session: session,
                          onFermer: session.actuelle
                              ? null
                              : () => _fermer(session),
                        ),
                      ),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarteSession extends StatelessWidget {
  final SessionOuverte session;
  final VoidCallback? onFermer;

  const _CarteSession({required this.session, required this.onFermer});

  @override
  Widget build(BuildContext context) {
    final actuelle = session.actuelle;
    final teinte = actuelle ? AppColors.ok : AppColors.inkMuted;

    return CarteBlanche(
      padding: const EdgeInsets.fromLTRB(14, 13, 8, 13),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: teinte.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              session.libelle.contains('web')
                  ? Icons.language
                  : Icons.smartphone_outlined,
              size: 20,
              color: teinte,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        session.libelle,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (actuelle) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.okSoft,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: AppColors.okLine),
                        ),
                        child: const Text(
                          'Cet appareil',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ok,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _quand(session),
                  style: const TextStyle(fontSize: 12.5, color: AppColors.faint),
                ),
              ],
            ),
          ),
          if (onFermer != null)
            IconButton(
              onPressed: onFermer,
              tooltip: 'Fermer la session',
              icon: const Icon(
                Icons.logout,
                size: 19,
                color: AppColors.danger,
              ),
            )
          else
            const SizedBox(width: 8),
        ],
      ),
    );
  }

  static String _quand(SessionOuverte session) {
    final date = session.derniereUtilisation ?? session.creeeLe;
    if (date == null) return 'Jamais utilisée';

    final ecart = DateTime.now().difference(date);
    if (ecart.inMinutes < 2) return 'Active à l’instant';
    if (ecart.inHours < 1) return 'Active il y a ${ecart.inMinutes} min';
    if (ecart.inHours < 24) return 'Active il y a ${ecart.inHours} h';
    if (ecart.inDays < 7) return 'Active il y a ${ecart.inDays} j';
    return 'Active le ${DateFormat('dd/MM/yyyy').format(date)}';
  }
}
