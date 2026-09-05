import 'package:flutter/material.dart';

import '../models/materiel.dart';
import '../services/onele_api.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'new_demande_screen.dart';

/// L'inventaire, côté employé : ce qu'on peut demander, et ce qu'il en reste.
/// Sans cet écran, il fallait ouvrir le formulaire pour découvrir le stock.
class CatalogueScreen extends StatefulWidget {
  const CatalogueScreen({super.key});

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  final _api = OneleApi();
  final _recherche = TextEditingController();

  List<Materiel>? _materiels;
  String? _erreur;
  String _categorie = 'Tout';

  @override
  void initState() {
    super.initState();
    _charger();
    _recherche.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    try {
      final liste = await _api.materiels();
      if (!mounted) return;
      setState(() {
        _materiels = liste;
        _erreur = null;
      });
    } catch (e) {
      if (mounted) setState(() => _erreur = e.toString());
    }
  }

  List<String> get _categories {
    final vues = <String>{};
    for (final m in _materiels ?? <Materiel>[]) {
      final c = m.categorie;
      if (c != null && c.isNotEmpty) vues.add(c);
    }
    return ['Tout', ...vues.toList()..sort()];
  }

  List<Materiel> get _filtres {
    final terme = _recherche.text.trim().toLowerCase();

    return (_materiels ?? <Materiel>[]).where((m) {
      if (_categorie != 'Tout' && m.categorie != _categorie) return false;
      if (terme.isEmpty) return true;
      return m.nom.toLowerCase().contains(terme) ||
          (m.description ?? '').toLowerCase().contains(terme) ||
          (m.categorie ?? '').toLowerCase().contains(terme);
    }).toList();
  }

  Future<void> _demander(Materiel materiel) async {
    final cree = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NewDemandeScreen(
          typeInitial: 'materiel',
          materielInitialId: materiel.id,
        ),
      ),
    );
    if (cree == true) await _charger();
  }

  @override
  Widget build(BuildContext context) {
    final marge = margeLaterale(context);
    final liste = _filtres;
    final disponibles = (_materiels ?? [])
        .where((m) => m.quantiteDisponible > 0)
        .length;

    return Scaffold(
      body: Column(
        children: [
          DarkHeader(
            sousTitre: 'CATALOGUE',
            titre: 'Le matériel',
            action: const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.railAccent,
              size: 26,
            ),
            bas: ecranBas(context)
                ? null
                : _BarreRecherche(
                    controleur: _recherche,
                    resume: _materiels == null
                        ? 'Chargement de l’inventaire…'
                        : '$disponibles référence${disponibles > 1 ? 's' : ''} '
                              'disponible${disponibles > 1 ? 's' : ''} '
                              'sur ${_materiels!.length}',
                  ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _charger,
              color: AppColors.brand,
              child: CustomScrollView(
                slivers: [
                  if (_erreur != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(marge, 16, marge, 0),
                        child: ErrorBanner(message: _erreur!),
                      ),
                    ),

                  if (_materiels != null && _categories.length > 2)
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 54,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.fromLTRB(marge, 14, marge, 6),
                          children: [
                            for (final c in _categories) ...[
                              _Puce(
                                libelle: c,
                                actif: c == _categorie,
                                onTap: () => setState(() => _categorie = c),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),
                    ),

                  if (_materiels == null)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(marge, 16, marge, 24),
                      sliver: SliverList.separated(
                        itemCount: 4,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, _) => const SqueletteCarte(),
                      ),
                    )
                  else if (liste.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: EmptyState(
                          icone: Icons.search_off,
                          titre: 'Rien ne correspond',
                          texte: _recherche.text.isEmpty
                              ? 'Aucun matériel dans cette catégorie.'
                              : 'Essayez un autre mot, ou changez de catégorie.',
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(marge, 10, marge, 30),
                      sliver: SliverList.separated(
                        itemCount: liste.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => EntreeAnimee(
                          rang: i,
                          child: _CarteMateriel(
                            materiel: liste[i],
                            onDemander: () => _demander(liste[i]),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Recherche posée dans le bandeau sombre : le champ y est clair sur fond
/// foncé, ce qui le désigne comme l'action principale de l'écran.
class _BarreRecherche extends StatelessWidget {
  final TextEditingController controleur;
  final String resume;

  const _BarreRecherche({required this.controleur, required this.resume});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: TextField(
            controller: controleur,
            style: const TextStyle(color: AppColors.railInk, fontSize: 15),
            cursorColor: AppColors.railAccent,
            decoration: InputDecoration(
              hintText: 'Rechercher un équipement',
              hintStyle: const TextStyle(
                color: AppColors.railMuted,
                fontSize: 15,
              ),
              prefixIcon: const Icon(
                Icons.search,
                size: 20,
                color: AppColors.railMuted,
              ),
              suffixIcon: controleur.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: controleur.clear,
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.railMuted,
                      ),
                    ),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          resume,
          style: const TextStyle(color: AppColors.railMuted, fontSize: 12.5),
        ),
      ],
    );
  }
}

class _Puce extends StatelessWidget {
  final String libelle;
  final bool actif;
  final VoidCallback onTap;

  const _Puce({
    required this.libelle,
    required this.actif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          color: actif ? AppColors.brand : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: actif ? AppColors.brand : AppColors.line,
          ),
          boxShadow: actif ? AppShadows.teinte(AppColors.brand) : null,
        ),
        child: Text(
          libelle,
          style: TextStyle(
            fontSize: 13,
            fontWeight: actif ? FontWeight.w600 : FontWeight.w400,
            color: actif ? Colors.white : AppColors.inkMuted,
          ),
        ),
      ),
    );
  }
}

class _CarteMateriel extends StatelessWidget {
  final Materiel materiel;
  final VoidCallback onDemander;

  const _CarteMateriel({required this.materiel, required this.onDemander});

  /// Trois paliers, parce que « 2 restants » n'appelle pas la même décision
  /// que « 18 disponibles ».
  static (String, Color, Color, Color) _stock(int quantite) {
    if (quantite == 0) {
      return ('Épuisé', AppColors.danger, AppColors.dangerSoft, AppColors.dangerLine);
    }
    if (quantite <= 3) {
      return ('$quantite restant${quantite > 1 ? 's' : ''}', AppColors.warn,
          AppColors.warnSoft, AppColors.warnLine);
    }
    return ('$quantite disponibles', AppColors.ok, AppColors.okSoft, AppColors.okLine);
  }

  /// Le nom est plus précis que la catégorie : « Casque audio » et
  /// « Ordinateur portable » partagent la catégorie Informatique mais pas
  /// grand-chose d'autre. La catégorie ne sert que de filet.
  static IconData _icone(String nom, String? categorie) {
    const parNom = {
      'casque': Icons.headset_outlined,
      'écran': Icons.desktop_windows_outlined,
      'ordinateur': Icons.laptop_mac,
      'station': Icons.usb,
      'projecteur': Icons.videocam_outlined,
      'micro': Icons.mic_none_outlined,
      'chaise': Icons.chair_outlined,
      'bureau': Icons.table_restaurant_outlined,
      'imprimante': Icons.print_outlined,
      'destructeur': Icons.delete_sweep_outlined,
    };
    final minuscule = nom.toLowerCase();
    for (final entree in parNom.entries) {
      if (minuscule.contains(entree.key)) return entree.value;
    }

    switch (categorie) {
      case 'Informatique':
        return Icons.laptop_mac;
      case 'Audiovisuel':
        return Icons.videocam_outlined;
      case 'Mobilier':
        return Icons.chair_outlined;
      case 'Bureautique':
        return Icons.print_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final (libelle, encre, fond, filet) = _stock(materiel.quantiteDisponible);
    final epuise = materiel.quantiteDisponible == 0;

    return CarteBlanche(
      padding: const EdgeInsets.all(14),
      onTap: epuise ? null : onDemander,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: epuise ? null : typeGradient('materiel'),
                  color: epuise ? AppColors.surfaceSunk : null,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: epuise
                      ? null
                      : AppShadows.teinte(AppColors.tMateriel),
                ),
                child: Icon(
                  _icone(materiel.nom, materiel.categorie),
                  size: 21,
                  color: epuise ? AppColors.faint : Colors.white,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      materiel.nom,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    if (materiel.categorie != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        materiel.categorie!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.faint,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: fond,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: filet),
                ),
                child: Text(
                  libelle,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: encre,
                  ),
                ),
              ),
            ],
          ),
          if (materiel.description != null) ...[
            const SizedBox(height: 11),
            Text(
              materiel.description!,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: AppColors.ink2,
              ),
            ),
          ],
          if (!epuise) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Spacer(),
                TextButton.icon(
                  onPressed: onDemander,
                  icon: const Icon(Icons.add, size: 17),
                  label: const Text('Demander'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.brand,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
