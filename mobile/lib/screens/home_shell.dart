import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_notification.dart';
import '../services/realtime_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'catalogue_screen.dart';
import 'demandes_list_screen.dart';
import 'notifications_screen.dart';
import 'profil_screen.dart';

/// Donne à n'importe quel écran de l'application le moyen de changer d'onglet
/// — l'avatar de l'accueil ouvre ainsi le profil sans empiler de page.
class Onglets extends InheritedWidget {
  final int actif;
  final ValueChanged<int> allerA;

  const Onglets({
    super.key,
    required this.actif,
    required this.allerA,
    required super.child,
  });

  static Onglets? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Onglets>();

  @override
  bool updateShouldNotify(Onglets ancien) => ancien.actif != actif;
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  StreamSubscription<AppNotification>? _ecoute;

  static const _screens = [
    DemandesListScreen(),
    CatalogueScreen(),
    NotificationsScreen(),
    ProfilScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Une notification poussée par le serveur s'annonce où que l'on soit
    // dans l'application, pas seulement sur l'onglet Notifications.
    _ecoute = context.read<RealtimeProvider>().notificationsRecues.listen(
      _annoncer,
    );
  }

  @override
  void dispose() {
    _ecoute?.cancel();
    super.dispose();
  }

  void _annoncer(AppNotification notification) {
    if (!mounted) return;

    final refusee = notification.message.toLowerCase().contains('refus');
    final couleur = refusee ? AppColors.dangerLine : AppColors.okLine;
    // `width` et `margin` s'excluent : sur écran large on fixe la largeur,
    // sinon on garde la marge qui colle la bannière aux bords.
    final large = MediaQuery.sizeOf(context).width > largeurLecture + 40;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.rail,
          elevation: 12,
          duration: const Duration(seconds: 5),
          width: large ? largeurLecture : null,
          margin: large ? null : const EdgeInsets.fromLTRB(14, 0, 14, 14),
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          content: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  refusee ? Icons.close_rounded : Icons.check_rounded,
                  size: 19,
                  color: couleur,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'À L’INSTANT',
                      style: TextStyle(
                        color: AppColors.railMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.12 * 10.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.railInk,
                        fontSize: 14,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'Voir',
            textColor: AppColors.railAccent,
            onPressed: () => setState(() => _index = 2),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final nonLues = context.watch<RealtimeProvider>().nonLues;

    return Onglets(
      actif: _index,
      allerA: (i) => setState(() => _index = i),
      child: Scaffold(
        body: IndexedStack(index: _index, children: _screens),
        bottomNavigationBar: _BarreOnglets(
          index: _index,
          nonLues: nonLues,
          onChange: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}

/// Barre d'onglets maison : l'onglet actif porte la tuile de marque, les
/// autres restent en encre sourde. Le compteur ne vit que sur les alertes.
class _BarreOnglets extends StatelessWidget {
  final int index;
  final int nonLues;
  final ValueChanged<int> onChange;

  const _BarreOnglets({
    required this.index,
    required this.nonLues,
    required this.onChange,
  });

  static const _onglets = [
    (Icons.inbox_outlined, Icons.inbox_rounded, 'Demandes'),
    (Icons.inventory_2_outlined, Icons.inventory_2, 'Matériel'),
    (Icons.notifications_outlined, Icons.notifications_rounded, 'Alertes'),
    (Icons.person_outline, Icons.person_rounded, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F0E1C18),
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          child: ZoneLecture(
            child: Row(
              children: List.generate(_onglets.length, (i) {
                final actif = i == index;
                final (icone, iconeActive, libelle) = _onglets[i];

                return Expanded(
                  child: InkWell(
                    onTap: () => onChange(i),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            width: 46,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: actif ? AppColors.gradBrand : null,
                              borderRadius: BorderRadius.circular(11),
                              boxShadow: actif
                                  ? AppShadows.teinte(AppColors.brand)
                                  : null,
                            ),
                            child: _IconeOnglet(
                              icone: actif ? iconeActive : icone,
                              couleur: actif
                                  ? Colors.white
                                  : AppColors.inkMuted,
                              // Seul l'onglet Alertes porte un compteur.
                              compteur: i == 2 ? nonLues : 0,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            libelle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: actif
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: actif
                                  ? AppColors.brand
                                  : AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

/// Icône d'onglet, éventuellement surmontée du nombre de notifications non lues.
class _IconeOnglet extends StatelessWidget {
  final IconData icone;
  final Color couleur;
  final int compteur;

  const _IconeOnglet({
    required this.icone,
    required this.couleur,
    required this.compteur,
  });

  @override
  Widget build(BuildContext context) {
    final icone = Icon(this.icone, size: 21, color: couleur);
    if (compteur <= 0) return icone;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        icone,
        Positioned(
          top: -5,
          right: -9,
          child: Container(
            constraints: const BoxConstraints(minWidth: 17),
            height: 17,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.surface, width: 1.6),
            ),
            child: Text(
              compteur > 99 ? '99+' : '$compteur',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                height: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
