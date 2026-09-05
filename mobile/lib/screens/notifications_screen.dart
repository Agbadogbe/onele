import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/app_notification.dart';
import '../services/onele_api.dart';
import '../services/realtime_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'demande_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _api = OneleApi();
  List<AppNotification> _notifications = [];
  bool _loading = true;

  StreamSubscription<AppNotification>? _ecoute;
  final _recentes = <int>{};
  final _minuteries = <Timer>[];

  @override
  void initState() {
    super.initState();
    _load();

    // Poussée par le serveur : la notification se pose en tête de liste.
    _ecoute = context.read<RealtimeProvider>().notificationsRecues.listen(
      _inserer,
    );
  }

  @override
  void dispose() {
    _ecoute?.cancel();
    for (final minuterie in _minuteries) {
      minuterie.cancel();
    }
    super.dispose();
  }

  void _inserer(AppNotification notification) {
    if (!mounted) return;

    setState(() {
      if (_notifications.any((n) => n.id == notification.id)) return;
      _notifications = [notification, ..._notifications];
      _recentes.add(notification.id);
    });

    _minuteries.add(
      Timer(const Duration(milliseconds: 2600), () {
        if (!mounted) return;
        setState(() => _recentes.remove(notification.id));
      }),
    );
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final n = await _api.notifications();
      if (!mounted) return;
      setState(() {
        _notifications = n;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _toutMarquerLu() async {
    // La liste bascule tout de suite ; si le serveur refuse, le rechargement
    // qui suit remet les pastilles là où elles doivent être.
    setState(() {
      _notifications = [
        for (final n in _notifications)
          AppNotification(
            id: n.id,
            demandeId: n.demandeId,
            message: n.message,
            lue: true,
            createdAt: n.createdAt,
          ),
      ];
    });
    context.read<RealtimeProvider>().viderCompteur();

    try {
      await _api.marquerToutesLues();
    } catch (_) {
      await _load();
      if (mounted) await context.read<RealtimeProvider>().rafraichirNonLues();
    }
  }

  Future<void> _ouvrir(AppNotification n) async {
    if (!n.lue) {
      await _api.marquerNotificationLue(n.id);
      if (!mounted) return;
      context.read<RealtimeProvider>().marquerUneLue();
      _load();
    }
    if (n.demandeId != null && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DemandeDetailScreen(demandeId: n.demandeId!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nonLues = _notifications.where((n) => !n.lue).length;
    final enDirect = context.watch<RealtimeProvider>().connecte;
    final marge = margeLaterale(context);

    return Scaffold(
      body: Column(
        children: [
          DarkHeader(
            sousTitre: 'SUIVI',
            titre: 'Alertes',
            // Une seule pastille à la fois : tant qu'il reste des non-lues,
            // c'est l'action qui a la place ; le témoin de liaison prend le
            // relais une fois la pile soldée.
            action: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (enDirect && nonLues == 0) const _TemoinDirect(),
                if (nonLues > 0)
                  // Le compteur est aussi l'action : là où l'œil compte les
                  // non-lues est aussi là où la main veut les solder.
                  Material(
                    color: AppColors.railAccent,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: InkWell(
                      onTap: _toutMarquerLu,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 7, 11, 7),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$nonLues non lue${nonLues > 1 ? 's' : ''}',
                              style: const TextStyle(
                                color: AppColors.rail,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.done_all,
                              size: 15,
                              color: AppColors.rail,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              color: AppColors.brand,
              child: _loading
                  ? ListView(
                      padding: EdgeInsets.fromLTRB(marge, 14, marge, 24),
                      children: const [
                        SqueletteCarte(),
                        SizedBox(height: 9),
                        SqueletteCarte(),
                        SizedBox(height: 9),
                        SqueletteCarte(),
                      ],
                    )
                  : _notifications.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 40),
                        EmptyState(
                          icone: Icons.notifications_none,
                          titre: 'Aucune notification',
                          texte: 'Vous serez prévenu ici dès qu’une de vos demandes sera traitée.',
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(marge, 14, marge, 24),
                      itemCount: _notifications.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 9),
                      itemBuilder: (context, i) => EntreeAnimee(
                        rang: i,
                        child: _CarteNotification(
                          notification: _notifications[i],
                          surbrillance: _recentes.contains(
                            _notifications[i].id,
                          ),
                          onTap: () => _ouvrir(_notifications[i]),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Témoin de liaison temps réel, affiché tant que le socket est ouvert.
class _TemoinDirect extends StatelessWidget {
  const _TemoinDirect();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.railAccent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.railAccent.withValues(alpha: 0.30)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 6,
            height: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.railAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SizedBox(width: 7),
          Text(
            'En direct',
            style: TextStyle(
              color: AppColors.railAccent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CarteNotification extends StatelessWidget {
  final AppNotification notification;
  final bool surbrillance;
  final VoidCallback onTap;

  const _CarteNotification({
    required this.notification,
    required this.onTap,
    this.surbrillance = false,
  });

  @override
  Widget build(BuildContext context) {
    final lue = notification.lue;
    // Le message porte le verdict : on colore l'icône en conséquence.
    final refusee = notification.message.toLowerCase().contains('refus');
    final couleur = lue
        ? AppColors.inkMuted
        : refusee
        ? AppColors.danger
        : AppColors.ok;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: surbrillance
            ? AppShadows.teinte(AppColors.brandHi)
            : AppShadows.carte,
      ),
      child: Material(
        color: lue ? AppColors.surface : AppColors.brandSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: surbrillance
                    ? AppColors.brandHi
                    : lue
                    ? AppColors.line
                    : AppColors.brandLine,
                width: surbrillance ? 1.5 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: couleur.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    refusee ? Icons.close_rounded : Icons.check_rounded,
                    size: 19,
                    color: couleur,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.35,
                          fontWeight: lue ? FontWeight.w400 : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _quand(notification.createdAt),
                        style: const TextStyle(
                          color: AppColors.faint,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!lue)
                  Container(
                    margin: const EdgeInsets.only(left: 8, top: 6),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.brand,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Une heure relative se situe sans lire une date ; au-delà d'une semaine,
  /// la date exacte redevient l'information utile.
  static String _quand(DateTime date) {
    final ecart = DateTime.now().difference(date);
    if (ecart.inMinutes < 2) return 'à l’instant';
    if (ecart.inMinutes < 60) return 'il y a ${ecart.inMinutes} min';
    if (ecart.inHours < 24) return 'il y a ${ecart.inHours} h';
    if (ecart.inDays < 7) return 'il y a ${ecart.inDays} j';
    return DateFormat("d MMM 'à' HH:mm", 'fr_FR').format(date);
  }
}
