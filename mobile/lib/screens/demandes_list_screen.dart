import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/activite.dart';
import '../models/demande.dart';
import '../services/auth_provider.dart';
import '../services/onele_api.dart';
import '../services/realtime_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/carte_activite.dart';
import '../widgets/common.dart';
import '../widgets/status_badge.dart';
import 'demande_detail_screen.dart';
import 'home_shell.dart';
import 'new_demande_screen.dart';

class DemandesListScreen extends StatefulWidget {
  const DemandesListScreen({super.key});

  @override
  State<DemandesListScreen> createState() => _DemandesListScreenState();
}

class _DemandesListScreenState extends State<DemandesListScreen> {
  final _api = OneleApi();
  List<Demande> _demandes = [];
  MonActivite? _activite;
  bool _loading = true;
  String _filtre = 'toutes';

  StreamSubscription<Demande>? _ecoute;
  final _recentes = <int>{};
  final _minuteries = <Timer>[];

  @override
  void initState() {
    super.initState();
    _load();

    // Verdict rendu depuis l'espace web : la carte bascule sur place, sans
    // rechargement ni geste de l'utilisateur.
    _ecoute = context.read<RealtimeProvider>().demandesTraitees.listen(
      _appliquerVerdict,
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

  void _appliquerVerdict(Demande demande) {
    if (!mounted) return;

    setState(() {
      final position = _demandes.indexWhere((d) => d.id == demande.id);
      if (position == -1) {
        _demandes = [demande, ..._demandes];
      } else {
        _demandes = [..._demandes]..[position] = demande;
      }
      _recentes.add(demande.id);
    });

    // Le solde et le rythme bougent aussi : on les redemande discrètement.
    unawaited(
      _api.monActivite().then((a) {
        if (mounted) setState(() => _activite = a);
      }, onError: (_) {}),
    );

    // La mise en évidence s'efface d'elle-même après quelques secondes.
    _minuteries.add(
      Timer(const Duration(milliseconds: 2600), () {
        if (!mounted) return;
        setState(() => _recentes.remove(demande.id));
      }),
    );
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Les deux appels partent ensemble : l'accueil n'attend pas deux allers-retours.
      final (toutes, activite) = await (
        _api.mesDemandes(),
        _api.monActivite(),
      ).wait;
      if (!mounted) return;
      setState(() {
        _demandes = toutes;
        _activite = activite;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  List<Demande> get _filtrees {
    switch (_filtre) {
      case 'en_attente':
        return _demandes.where((d) => d.statut == 'en_attente').toList();
      case 'traitees':
        return _demandes.where((d) => d.statut != 'en_attente').toList();
      default:
        return _demandes;
    }
  }

  int _compte(String statut) =>
      _demandes.where((d) => d.statut == statut).length;

  Future<void> _ouvrir(Demande demande) async {
    final change = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DemandeDetailScreen(demandeId: demande.id),
      ),
    );
    if (change == true) _load();
  }

  Future<void> _creer() async {
    final cree = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const NewDemandeScreen()));
    if (cree == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final liste = _filtrees;
    final marge = margeLaterale(context);

    return Scaffold(
      body: Column(
        children: [
          DarkHeader(
            sousTitre: 'MES DEMANDES',
            titre: 'Bonjour, ${user?.prenom ?? ''}',
            action: GestureDetector(
              onTap: () => Onglets.of(context)?.allerA(3),
              child: Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.railAccent.withValues(alpha: 0.4),
                    width: 1.4,
                  ),
                ),
                child: Avatar(
                  prenom: user?.prenom ?? '',
                  nom: user?.nom ?? '',
                  taille: 40,
                  surFondSombre: true,
                ),
              ),
            ),
            // Sur un écran bas de plafond, les compteurs cèdent la place à la liste.
            bas: ecranBas(context)
                ? null
                : Row(
                    children: [
                      _Compteur(
                        valeur: _compte('en_attente'),
                        libelle: 'En attente',
                        couleur: AppColors.warnLine,
                      ),
                      _Compteur(
                        valeur: _compte('validee'),
                        libelle: 'Validées',
                        couleur: AppColors.okLine,
                      ),
                      _Compteur(
                        valeur: _compte('refusee'),
                        libelle: 'Refusées',
                        couleur: AppColors.dangerLine,
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
                      padding: EdgeInsets.fromLTRB(marge, 16, marge, 24),
                      children: const [
                        SqueletteCarte(),
                        SizedBox(height: 10),
                        SqueletteCarte(),
                        SizedBox(height: 10),
                        SqueletteCarte(),
                        SizedBox(height: 10),
                        SqueletteCarte(),
                      ],
                    )
                  : liste.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 40),
                        EmptyState(
                          icone: Icons.inbox_outlined,
                          titre: _filtre == 'toutes'
                              ? 'Aucune demande'
                              : 'Rien dans ce filtre',
                          texte: _filtre == 'toutes'
                              ? 'Déposez votre première demande de congé, de permission ou de matériel.'
                              : 'Changez de filtre pour voir vos autres demandes.',
                          action: _filtre == 'toutes'
                              ? FilledButton.icon(
                                  onPressed: _creer,
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Nouvelle demande'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.brand,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 13,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ],
                    )
                  // Le résumé et les filtres défilent avec la liste : ils
                  // rendent la hauteur au contenu dès qu'on descend.
                  : CustomScrollView(
                      slivers: [
                        if (_activite != null)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(marge, 14, marge, 4),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: const Duration(milliseconds: 420),
                                curve: Curves.easeOutCubic,
                                builder: (_, v, enfant) => Opacity(
                                  opacity: v,
                                  child: Transform.translate(
                                    offset: Offset(0, 10 * (1 - v)),
                                    child: enfant,
                                  ),
                                ),
                                child: CarteActivite(activite: _activite!),
                              ),
                            ),
                          ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(marge, 14, marge, 6),
                            child: Row(
                              children: [
                                _puce('toutes', 'Toutes'),
                                const SizedBox(width: 8),
                                _puce('en_attente', 'En attente'),
                                const SizedBox(width: 8),
                                _puce('traitees', 'Traitées'),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(marge, 4, marge, 96),
                          sliver: SliverList.separated(
                            itemCount: liste.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) => EntreeAnimee(
                              rang: i,
                              child: _CarteDemande(
                                demande: liste[i],
                                surbrillance: _recentes.contains(liste[i].id),
                                onTap: () => _ouvrir(liste[i]),
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
      // L'écran vide porte déjà son propre bouton : pas de doublon avec le FAB.
      floatingActionButton: (!_loading && liste.isEmpty && _filtre == 'toutes')
          ? null
          : FloatingActionButton.extended(
              onPressed: _creer,
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle demande'),
            ),
    );
  }

  Widget _puce(String cle, String libelle) {
    final actif = _filtre == cle;

    return GestureDetector(
      onTap: () => setState(() => _filtre = cle),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: actif ? AppColors.brandSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: actif ? AppColors.brandLine : AppColors.line,
          ),
        ),
        child: Text(
          libelle,
          style: TextStyle(
            fontSize: 13,
            fontWeight: actif ? FontWeight.w600 : FontWeight.w400,
            color: actif ? AppColors.brand : AppColors.inkMuted,
          ),
        ),
      ),
    );
  }
}

/// Compteur affiché dans l'en-tête sombre.
class _Compteur extends StatelessWidget {
  final int valeur;
  final String libelle;
  final Color couleur;

  const _Compteur({
    required this.valeur,
    required this.libelle,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: couleur,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              CompteurAnime(
                valeur: valeur,
                style: titreDisplay(
                  taille: 23,
                  couleur: AppColors.railInk,
                  graisse: FontWeight.w700,
                  hauteur: 1,
                  espacement: -0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            libelle,
            style: const TextStyle(color: AppColors.railMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _CarteDemande extends StatelessWidget {
  final Demande demande;
  final bool surbrillance;
  final VoidCallback onTap;

  const _CarteDemande({
    required this.demande,
    required this.onTap,
    this.surbrillance = false,
  });

  /// Deux encodages qui ne se marchent pas dessus : la tuile porte le type,
  /// le liseré porte le statut. Chacun répond à une question différente.
  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM', 'fr_FR');
    final memeJour = demande.dateDebut == demande.dateFin;
    final periode = memeJour
        ? df.format(demande.dateDebut)
        : '${df.format(demande.dateDebut)} au ${df.format(demande.dateFin)}';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: surbrillance
            ? AppShadows.teinte(AppColors.brandHi)
            : AppShadows.carte,
      ),
      child: Material(
        color: surbrillance ? AppColors.brandSoft : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Le liseré de statut court sur toute la hauteur : il se lit
                // du coin de l'œil, avant même le libellé de la pastille.
                Container(width: 4, color: statutColor(demande.statut)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(13, 13, 12, 13),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TypeTile(type: demande.type),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      typeLabel(demande.type),
                                      style: titreDisplay(
                                        taille: 17,
                                        graisse: FontWeight.w600,
                                        espacement: -0.2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  StatusBadge(
                                    statut: demande.statut,
                                    compact: true,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                demande.resumeDetail,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.ink2,
                                  fontSize: 13.5,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 9),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 13,
                                    color: AppColors.faint,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      periode,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.faint,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 3,
                                    height: 3,
                                    decoration: const BoxDecoration(
                                      color: AppColors.line2,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _depuis(demande.createdAt),
                                    style: const TextStyle(
                                      color: AppColors.faint,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 4, top: 13),
                          child: Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: AppColors.faint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Un dépôt daté « il y a 3 j » se situe sans calcul mental ; la date
  /// exacte, elle, vit sur la fiche.
  static String _depuis(DateTime date) {
    final ecart = DateTime.now().difference(date);
    if (ecart.inMinutes < 60) return 'à l’instant';
    if (ecart.inHours < 24) return 'il y a ${ecart.inHours} h';
    if (ecart.inDays < 31) return 'il y a ${ecart.inDays} j';
    return 'il y a ${(ecart.inDays / 30).round()} mois';
  }
}
