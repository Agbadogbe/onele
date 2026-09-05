import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Icônes de la barre d'état en clair — à appliquer sous tout bandeau sombre.
const barreEtatClaire = SystemUiOverlayStyle(
  statusBarBrightness: Brightness.dark,
  statusBarIconBrightness: Brightness.light,
  statusBarColor: Colors.transparent,
);

/// Largeur de lecture confortable. Au-delà — tablette, téléphone en paysage —
/// le contenu est centré plutôt qu'étiré : une ligne de 900 px ne se lit pas.
const double largeurLecture = 560;

/// Marge latérale qui recentre le contenu dès que l'écran dépasse cette
/// largeur. Elle se pose sur le `padding` d'une liste : la zone de défilement
/// garde toute la largeur — donc le geste aussi — et seul le contenu est centré.
double margeLaterale(BuildContext context, {double minimum = 16}) {
  final reste = (MediaQuery.sizeOf(context).width - largeurLecture) / 2;
  return reste > minimum ? reste : minimum;
}

/// Vrai sur un écran bas de plafond (téléphone en paysage), où un en-tête
/// complet mangerait le tiers de la hauteur utile.
bool ecranBas(BuildContext context) => MediaQuery.sizeOf(context).height < 520;

/// Centre un contenu non défilant dans la largeur de lecture.
///
/// `heightFactor: 1` est indispensable : sans lui le widget s'étirerait aussi
/// en hauteur, et une barre de navigation — qui se dimensionne sur son enfant —
/// occuperait tout l'écran.
class ZoneLecture extends StatelessWidget {
  final Widget child;

  const ZoneLecture({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: largeurLecture),
        child: child,
      ),
    );
  }
}

/// Pastille d'initiales — la teinte est dérivée du nom, comme sur le web.
class Avatar extends StatelessWidget {
  final String prenom;
  final String nom;
  final double taille;
  final bool surFondSombre;

  const Avatar({
    super.key,
    required this.prenom,
    required this.nom,
    this.taille = 40,
    this.surFondSombre = false,
  });

  static const _teintes = [
    [Color(0xFFDCE9EF), Color(0xFF1B566F)],
    [Color(0xFFE4E5F3), Color(0xFF4A4A87)],
    [Color(0xFFE0EEE5), Color(0xFF2A6B48)],
    [Color(0xFFF2E7DA), Color(0xFF8A5B24)],
    [Color(0xFFEFE0E5), Color(0xFF87405A)],
    [Color(0xFFDEEBEB), Color(0xFF26666A)],
  ];

  @override
  Widget build(BuildContext context) {
    final initiales =
        '${prenom.isNotEmpty ? prenom[0] : ''}'
                '${nom.isNotEmpty ? nom[0] : ''}'
            .toUpperCase();
    final graine = '$prenom$nom'.codeUnits.fold<int>(0, (a, b) => a + b);
    final teinte = _teintes[graine % _teintes.length];

    return Container(
      width: taille,
      height: taille,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: surFondSombre ? AppColors.rail3 : teinte[0],
        shape: BoxShape.circle,
      ),
      child: Text(
        initiales.isEmpty ? '?' : initiales,
        style: TextStyle(
          color: surFondSombre ? AppColors.railAccent : teinte[1],
          fontSize: taille * 0.36,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Tuile portant l'icône du type de demande. La teinte du type y est pleine
/// et non lavée : c'est elle qui donne son rythme coloré à la liste.
class TypeTile extends StatelessWidget {
  final String type;
  final double taille;

  const TypeTile({super.key, required this.type, this.taille = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: taille,
      height: taille,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: typeGradient(type),
        borderRadius: BorderRadius.circular(taille * 0.30),
        boxShadow: AppShadows.teinte(typeColor(type)),
      ),
      child: Icon(typeIcon(type), size: taille * 0.46, color: Colors.white),
    );
  }
}

/// Écran vide : icône, titre, explication et action facultative.
class EmptyState extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String texte;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icone,
    required this.titre,
    required this.texte,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: const BoxDecoration(
                color: AppColors.surfaceSunk,
                shape: BoxShape.circle,
              ),
              child: Icon(icone, size: 27, color: AppColors.faint),
            ),
            const SizedBox(height: 16),
            Text(
              titre,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              texte,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.inkMuted,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

/// Bandeau d'erreur de formulaire.
class ErrorBanner extends StatelessWidget {
  final String message;

  const ErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.dangerLine),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.danger),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Logotype : un anneau surmonté de son accent — le « Ó » d'Onélé, réduit à
/// deux formes. Dessiné plutôt qu'écrit, il reste net à toutes les tailles et
/// ne dépend d'aucune fonte.
class BrandStamp extends StatelessWidget {
  final double taille;
  final bool surFondSombre;

  const BrandStamp({super.key, this.taille = 40, this.surFondSombre = false});

  @override
  Widget build(BuildContext context) {
    final encre = surFondSombre ? AppColors.rail : Colors.white;
    final anneau = taille * 0.42;
    final trait = taille * 0.095;

    return Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        gradient: surFondSombre ? null : AppColors.gradBrand,
        color: surFondSombre ? AppColors.railAccent : null,
        borderRadius: BorderRadius.circular(taille * 0.30),
        boxShadow: surFondSombre ? null : AppShadows.teinte(AppColors.brand),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // L'anneau, légèrement décentré vers le bas : l'accent occupe le
          // reste de la hauteur sans que la marque paraisse tomber.
          Padding(
            padding: EdgeInsets.only(top: taille * 0.10),
            child: Container(
              width: anneau,
              height: anneau,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: encre, width: trait),
              ),
            ),
          ),
          Positioned(
            top: taille * 0.10,
            left: taille * 0.52,
            child: Transform.rotate(
              angle: 0.62,
              child: Container(
                width: taille * 0.22,
                height: trait,
                decoration: BoxDecoration(
                  color: encre,
                  borderRadius: BorderRadius.circular(trait),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Le nom, dans la fonte de la marque.
class Wordmark extends StatelessWidget {
  final double taille;
  final Color couleur;

  const Wordmark({super.key, this.taille = 18, this.couleur = AppColors.ink});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Onélé',
      style: titreDisplay(
        taille: taille,
        couleur: couleur,
        graisse: FontWeight.w700,
        espacement: -0.2,
      ),
    );
  }
}

/// En-tête sombre reprenant le rail de l'espace web.
class DarkHeader extends StatelessWidget {
  final String titre;
  final String? sousTitre;
  final Widget? action;
  final Widget? bas;

  const DarkHeader({
    super.key,
    required this.titre,
    this.sousTitre,
    this.action,
    this.bas,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: barreEtatClaire,
      child: ClipRRect(
        // Le bandeau se referme en arrondi : il se lit comme un objet posé sur
        // le papier, pas comme une bande qui court d'un bord à l'autre.
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xl),
        ),
        child: AuroraPanel(
          child: SizedBox(
          width: double.infinity,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                margeLaterale(context, minimum: 20),
                ecranBas(context) ? 8 : 14,
                margeLaterale(context, minimum: 20),
                ecranBas(context) ? 12 : 18,
              ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (sousTitre != null) ...[
                                Text(
                                  sousTitre!,
                                  style: eyebrowStyle.copyWith(
                                    color: AppColors.railMuted,
                                  ),
                                ),
                                const SizedBox(height: 5),
                              ],
                              Text(
                                titre,
                                style: titreDisplay(
                                  taille: 27,
                                  couleur: AppColors.railInk,
                                  graisse: FontWeight.w700,
                                  hauteur: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ?action,
                      ],
                    ),
                    if (bas != null) ...[const SizedBox(height: 20), bas!],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bouton principal en dégradé — le pendant mobile du `.btn` du web.
/// `ElevatedButton` ne prend pas de dégradé : on peint l'`Ink` nous-mêmes.
class PrimaryButton extends StatelessWidget {
  final String libelle;
  final VoidCallback? onPressed;
  final bool chargement;
  final IconData? icone;

  const PrimaryButton({
    super.key,
    required this.libelle,
    required this.onPressed,
    this.chargement = false,
    this.icone,
  });

  @override
  Widget build(BuildContext context) {
    final actif = onPressed != null && !chargement;

    return Opacity(
      opacity: actif ? 1 : 0.55,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          boxShadow: actif
              ? [
                  const BoxShadow(
                    color: Color(0x3D17506E),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              gradient: AppColors.gradBrand,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: InkWell(
              onTap: actif ? onPressed : null,
              child: Container(
                height: 52,
                alignment: Alignment.center,
                child: chargement
                    ? const SizedBox(
                        height: 19,
                        width: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icone != null) ...[
                            Icon(icone, size: 19, color: Colors.white),
                            const SizedBox(width: 9),
                          ],
                          Text(
                            libelle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fond « aurore » : nappe sombre + halo cyan peint *à l'intérieur* du cadre.
/// (Une `boxShadow` se dessinerait hors du cadre et resterait invisible.)
class AuroraPanel extends StatelessWidget {
  final Widget child;

  const AuroraPanel({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(gradient: AppColors.gradRail),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.85, -1.1),
                radius: 1.15,
                colors: [Color(0x662AA8C4), Color(0x00000000)],
                stops: [0.0, 1.0],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.9, 0.9),
                radius: 1.0,
                colors: [Color(0x3317506E), Color(0x00000000)],
                stops: [0.0, 1.0],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Surface de contenu : ombre douce plutôt que filet. Le filet reste pour les
/// surfaces secondaires, qui ne doivent pas sembler flotter.
class CarteBlanche extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color couleur;
  final VoidCallback? onTap;
  final BorderRadius? rayon;
  final Border? bordure;
  final List<BoxShadow>? ombre;

  const CarteBlanche({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.couleur = AppColors.surface,
    this.onTap,
    this.rayon,
    this.bordure,
    this.ombre,
  });

  @override
  Widget build(BuildContext context) {
    final r = rayon ?? BorderRadius.circular(AppRadius.md);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: ombre ?? AppShadows.carte,
      ),
      child: Material(
        color: couleur,
        borderRadius: r,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(borderRadius: r, border: bordure),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Intertitre de section : l'étiquette majuscule, prolongée d'un filet qui
/// occupe la largeur restante. Le filet dit « ce qui suit forme un groupe ».
class TitreSection extends StatelessWidget {
  final String libelle;
  final Widget? action;

  const TitreSection({super.key, required this.libelle, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(libelle, style: eyebrowStyle),
        const SizedBox(width: 12),
        const Expanded(child: Divider(height: 1, color: AppColors.line)),
        if (action != null) ...[const SizedBox(width: 12), action!],
      ],
    );
  }
}

/// Rangée de réglage : icône, libellé, valeur, et ce qu'on peut en faire.
class LigneReglage extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final String? valeur;
  final Widget? fin;
  final VoidCallback? onTap;
  final Color? teinte;
  final bool premiere;

  const LigneReglage({
    super.key,
    required this.icone,
    required this.libelle,
    this.valeur,
    this.fin,
    this.onTap,
    this.teinte,
    this.premiere = false,
  });

  @override
  Widget build(BuildContext context) {
    final couleur = teinte ?? AppColors.brand;

    return Column(
      children: [
        // Le filet sépare les rangées entre elles sans encadrer le groupe,
        // et s'arrête à la hauteur du texte plutôt qu'à celle de l'icône.
        if (!premiere)
          const Padding(
            padding: EdgeInsets.only(left: 56),
            child: Divider(height: 1, color: AppColors.line),
          ),
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: couleur.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icone, size: 17, color: couleur),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        libelle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.ink,
                        ),
                      ),
                      if (valeur != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          valeur!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                fin ??
                    (onTap == null
                        ? const SizedBox.shrink()
                        : const Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: AppColors.faint,
                          )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Entrée en fondu-montée, décalée selon le rang : la liste se pose au lieu
/// d'apparaître d'un bloc. Au-delà du douzième élément le décalage est plafonné
/// — personne n'attend une seconde et demie pour voir le bas d'une liste.
class EntreeAnimee extends StatelessWidget {
  final int rang;
  final Widget child;

  const EntreeAnimee({super.key, required this.rang, required this.child});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    return TweenAnimationBuilder<double>(
      key: ValueKey(rang),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 340 + (rang.clamp(0, 12)) * 45),
      curve: Curves.easeOutCubic,
      builder: (_, v, enfant) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 14 * (1 - v)), child: enfant),
      ),
      child: child,
    );
  }
}

/// Ossature de chargement : un bloc gris qui respire. Elle occupe la place
/// exacte du contenu attendu, ce qu'un tourniquet centré ne fait pas.
class Squelette extends StatefulWidget {
  final double hauteur;
  final double? largeur;
  final double rayon;

  const Squelette({
    super.key,
    this.hauteur = 14,
    this.largeur,
    this.rayon = 7,
  });

  @override
  State<Squelette> createState() => _SqueletteState();
}

class _SqueletteState extends State<Squelette>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        height: widget.hauteur,
        width: widget.largeur,
        decoration: BoxDecoration(
          color: Color.lerp(
            AppColors.surfaceSunk,
            AppColors.line2,
            _c.value * 0.7,
          ),
          borderRadius: BorderRadius.circular(widget.rayon),
        ),
      ),
    );
  }
}

/// Ossature d'une carte de demande — même gabarit que la carte réelle.
class SqueletteCarte extends StatelessWidget {
  const SqueletteCarte({super.key});

  @override
  Widget build(BuildContext context) {
    return CarteBlanche(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Squelette(hauteur: 44, largeur: 44, rayon: 13),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Squelette(hauteur: 15, largeur: 120),
                SizedBox(height: 9),
                Squelette(hauteur: 12),
                SizedBox(height: 7),
                Squelette(hauteur: 12, largeur: 90),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
