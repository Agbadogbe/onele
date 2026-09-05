import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/activite.dart';
import '../services/api_client.dart';
import '../services/auth_provider.dart';
import '../services/onele_api.dart';
import '../services/realtime_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/carte_activite.dart';
import '../widgets/common.dart';
import 'appareils_screen.dart';
import 'modifier_profil_screen.dart';
import 'mot_de_passe_screen.dart';

/// Le compte, vu par son titulaire : qui je suis, ce que j'ai déposé,
/// ce que je peux régler.
class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final _api = OneleApi();
  MonActivite? _activite;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final activite = await _api.monActivite();
      if (mounted) setState(() => _activite = activite);
    } catch (_) {
      // Le bandeau de chiffres se tait : le reste de l'écran reste utilisable.
    }
  }

  Future<void> _deconnecter() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text(
          'Vos demandes restent enregistrées. Il faudra vous reconnecter '
          'pour les consulter depuis cet appareil.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirme == true && mounted) {
      await context.read<AuthProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tempsReel = context.watch<RealtimeProvider>();
    final user = auth.user;
    final marge = margeLaterale(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _charger,
        color: AppColors.brand,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _Entete(
              prenom: user?.prenom ?? '',
              nom: user?.nom ?? '',
              email: user?.email ?? '',
              role: user?.role ?? 'employe',
            ),

            // Le bandeau de chiffres chevauche l'en-tête : il appartient aux
            // deux plans, ce qui fait tenir la page en un seul bloc.
            Transform.translate(
              offset: const Offset(0, -30),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: marge),
                child: _BandeauChiffres(activite: _activite),
              ),
            ),

            Transform.translate(
              offset: const Offset(0, -14),
              child: Padding(
                padding: EdgeInsets.fromLTRB(marge, 0, marge, 34),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const TitreSection(libelle: 'MON COMPTE'),
                    const SizedBox(height: 10),
                    CarteBlanche(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          LigneReglage(
                            premiere: true,
                            icone: Icons.badge_outlined,
                            libelle: 'Mes informations',
                            valeur: user?.email,
                            onTap: () => _ouvrir(const ModifierProfilScreen()),
                          ),
                          LigneReglage(
                            icone: Icons.lock_outline,
                            libelle: 'Mot de passe',
                            valeur: 'Changer le mot de passe du compte',
                            onTap: () => _ouvrir(const MotDePasseScreen()),
                          ),
                          LigneReglage(
                            icone: Icons.devices_outlined,
                            libelle: 'Appareils connectés',
                            valeur: 'Voir et fermer les sessions ouvertes',
                            onTap: () => _ouvrir(const AppareilsScreen()),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),
                    const TitreSection(libelle: 'PRÉFÉRENCES'),
                    const SizedBox(height: 10),
                    CarteBlanche(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          LigneReglage(
                            premiere: true,
                            icone: Icons.bolt_outlined,
                            libelle: 'Alertes en direct',
                            valeur: tempsReel.alertesActives
                                ? (tempsReel.connecte
                                      ? 'Liaison ouverte'
                                      : 'Reconnexion en cours…')
                                : 'Coupées — rien ne s’affiche en cours de route',
                            teinte: AppColors.brandHi,
                            fin: Switch.adaptive(
                              value: tempsReel.alertesActives,
                              activeThumbColor: Colors.white,
                              activeTrackColor: AppColors.brand,
                              onChanged: tempsReel.definirAlertes,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),
                    const TitreSection(libelle: 'APPLICATION'),
                    const SizedBox(height: 10),
                    CarteBlanche(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          LigneReglage(
                            premiere: true,
                            icone: Icons.info_outline,
                            libelle: 'Version',
                            teinte: AppColors.inkMuted,
                            fin: const Text(
                              '1.0.0',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.inkMuted,
                              ),
                            ),
                          ),
                          LigneReglage(
                            icone: Icons.dns_outlined,
                            libelle: 'Serveur',
                            teinte: AppColors.inkMuted,
                            fin: Text(
                              hoteServeur,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.inkMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),
                    OutlinedButton.icon(
                      onPressed: _deconnecter,
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Se déconnecter'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.dangerLine),
                        backgroundColor: AppColors.surface,
                      ),
                    ),

                    const SizedBox(height: 26),
                    Center(
                      child: Opacity(
                        opacity: 0.5,
                        child: Column(
                          children: [
                            const BrandStamp(taille: 30),
                            const SizedBox(height: 8),
                            Text(
                              'Onélé — vos démarches RH',
                              style: TextStyle(
                                fontSize: 12,
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
          ],
        ),
      ),
    );
  }

  Future<void> _ouvrir(Widget ecran) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ecran));
    if (mounted) await _charger();
  }
}

/// Bandeau sombre du profil : l'avatar y est posé en grand, cerné d'un halo.
class _Entete extends StatelessWidget {
  final String prenom;
  final String nom;
  final String email;
  final String role;

  const _Entete({
    required this.prenom,
    required this.nom,
    required this.email,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final marge = margeLaterale(context, minimum: 20);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppRadius.xl),
      ),
      child: AuroraPanel(
        child: SizedBox(
          width: double.infinity,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(marge, 16, marge, 52),
              child: ZoneLecture(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROFIL',
                      style: eyebrowStyle.copyWith(color: AppColors.railMuted),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.railAccent.withValues(
                                alpha: 0.45,
                              ),
                              width: 1.5,
                            ),
                          ),
                          child: Avatar(
                            prenom: prenom,
                            nom: nom,
                            taille: 58,
                            surFondSombre: true,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$prenom $nom'.trim(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: titreDisplay(
                                  taille: 25,
                                  couleur: AppColors.railInk,
                                  graisse: FontWeight.w700,
                                  hauteur: 1.15,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.railAccent.withValues(
                                        alpha: 0.16,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.pill,
                                      ),
                                    ),
                                    child: Text(
                                      roleLabel(role),
                                      style: const TextStyle(
                                        color: AppColors.railAccent,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(
                          Icons.mail_outline,
                          size: 15,
                          color: AppColors.railMuted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.railMuted,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ],
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

/// Trois chiffres qui résument le compte, sur une carte détachée.
class _BandeauChiffres extends StatelessWidget {
  final MonActivite? activite;

  const _BandeauChiffres({required this.activite});

  @override
  Widget build(BuildContext context) {
    return ZoneLecture(
      child: CarteBlanche(
        padding: const EdgeInsets.symmetric(vertical: 15),
        ombre: AppShadows.flottant,
        child: Row(
          children: [
            _Chiffre(
              valeur: activite?.total,
              libelle: 'Demandes',
              teinte: AppColors.brand,
            ),
            const _Filet(),
            _Chiffre(
              valeur: activite?.statut('en_attente'),
              libelle: 'En attente',
              teinte: AppColors.warn,
            ),
            const _Filet(),
            _Chiffre(
              valeur: activite?.joursCongesPris,
              libelle: 'Jours pris',
              teinte: AppColors.tConge,
            ),
          ],
        ),
      ),
    );
  }
}

class _Filet extends StatelessWidget {
  const _Filet();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 30, color: AppColors.line);
}

class _Chiffre extends StatelessWidget {
  final int? valeur;
  final String libelle;
  final Color teinte;

  const _Chiffre({
    required this.valeur,
    required this.libelle,
    required this.teinte,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (valeur == null)
            const Squelette(hauteur: 27, largeur: 34)
          else
            CompteurAnime(
              valeur: valeur!,
              style: titreDisplay(
                taille: 27,
                couleur: teinte,
                graisse: FontWeight.w700,
                hauteur: 1,
              ),
            ),
          const SizedBox(height: 5),
          Text(
            libelle,
            style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}
