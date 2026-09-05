import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/activite.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Compteur qui défile de zéro jusqu'à sa valeur — le chiffre prend vie
/// au lieu d'apparaître d'un bloc.
class CompteurAnime extends StatelessWidget {
  final int valeur;
  final TextStyle? style;
  final Duration duree;

  const CompteurAnime({
    super.key,
    required this.valeur,
    this.style,
    this.duree = const Duration(milliseconds: 900),
  });

  @override
  Widget build(BuildContext context) {
    // Respecte le réglage système « animations réduites ».
    if (MediaQuery.disableAnimationsOf(context)) {
      return Text('$valeur', style: style);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: valeur.toDouble()),
      duration: duree,
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => Text('${v.round()}', style: style),
    );
  }
}

/// Rythme des six derniers mois — série unique, donc pas de légende : le
/// titre de la carte dit déjà ce qui est mesuré.
class _MiniBarres extends StatelessWidget {
  final List<PointMensuel> points;

  const _MiniBarres({required this.points});

  @override
  Widget build(BuildContext context) {
    final maxi = points.fold<int>(1, (m, p) => p.total > m ? p.total : m);
    final initiales = DateFormat('MMM', 'fr_FR');
    // Le mois le plus chargé porte sa valeur : la teinte seule passe sous le
    // rapport de contraste de 3:1, une étiquette directe prend le relais.
    final sommet = points.indexWhere((p) => p.total == maxi);

    return SizedBox(
      height: 75,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (i, p) in points.indexed) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 13,
                    child: i == sommet && p.total > 0
                        ? FittedBox(
                            child: Text(
                              '${p.total}',
                              style: const TextStyle(
                                fontSize: 11,
                                height: 1,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink2,
                              ),
                            ),
                          )
                        : null,
                  ),
                  // La barre pousse depuis la ligne de base, décalée dans le temps.
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: p.total / maxi),
                    duration: Duration(milliseconds: 520 + i * 70),
                    curve: Curves.easeOutBack,
                    builder: (_, v, _) => Container(
                      height: (40 * v).clamp(p.total > 0 ? 3.0 : 0.0, 40.0),
                      decoration: BoxDecoration(
                        // Une seule série, donc une seule teinte : varier
                        // l'opacité selon la valeur ré-encoderait en couleur ce
                        // que la hauteur dit déjà.
                        color: p.total == 0 ? AppColors.line : AppColors.tConge,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    initiales.format(p.mois).substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.faint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Carte de synthèse en tête d'accueil : solde de congés, rythme des derniers
/// mois, délai de réponse habituel et prochaine échéance.
class CarteActivite extends StatelessWidget {
  final MonActivite activite;

  const CarteActivite({super.key, required this.activite});

  @override
  Widget build(BuildContext context) {
    final prochaine = activite.prochaineDemande;
    final delai = activite.delaiReponseMoyenHeures;

    return CarteBlanche(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      ombre: AppShadows.flottant,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('CETTE ANNÉE', style: eyebrowStyle),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.tConge.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '${DateTime.now().year}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.tConge,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        CompteurAnime(
                          valeur: activite.joursCongesPris,
                          style: titreDisplay(
                            taille: 42,
                            graisse: FontWeight.w700,
                            hauteur: 1,
                            espacement: -1.4,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'jours',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.inkMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'de congés pris',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              if (activite.activiteMensuelle.isNotEmpty)
                Expanded(
                  child: _MiniBarres(points: activite.activiteMensuelle),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.line),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Repere(
                  icone: Icons.timer_outlined,
                  libelle: 'Réponse en',
                  valeur: formaterDelai(delai),
                ),
              ),
              Container(width: 1, height: 26, color: AppColors.line),
              Expanded(
                child: _Repere(
                  icone: Icons.event_available_outlined,
                  libelle: prochaine == null ? 'À venir' : 'Prochaine',
                  valeur: prochaine == null
                      ? 'Rien de prévu'
                      : _dansCombien(prochaine.dateDebut),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _dansCombien(DateTime date) {
    final jours = DateUtils.dateOnly(date)
        .difference(DateUtils.dateOnly(DateTime.now()))
        .inDays;
    if (jours <= 0) return "aujourd'hui";
    if (jours == 1) return 'demain';
    return 'dans $jours j';
  }
}

class _Repere extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final String valeur;

  const _Repere({
    required this.icone,
    required this.libelle,
    required this.valeur,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 17, color: AppColors.faint),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                libelle,
                style: const TextStyle(fontSize: 11.5, color: AppColors.faint),
              ),
              const SizedBox(height: 1),
              Text(
                valeur,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
