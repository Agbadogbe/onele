import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/demande.dart';
import '../services/onele_api.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/status_badge.dart';

class DemandeDetailScreen extends StatefulWidget {
  final int demandeId;

  const DemandeDetailScreen({super.key, required this.demandeId});

  @override
  State<DemandeDetailScreen> createState() => _DemandeDetailScreenState();
}

class _DemandeDetailScreenState extends State<DemandeDetailScreen> {
  final _api = OneleApi();
  Demande? _demande;
  bool _loading = true;
  bool _annulation = false;
  String? _error;

  static const _actionLabels = {
    'creation': 'Demande déposée',
    'validee': 'Demande validée',
    'refusee': 'Demande refusée',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final d = await _api.demande(widget.demandeId);
      if (!mounted) return;
      setState(() {
        _demande = d;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _annuler() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler la demande ?'),
        content: const Text(
          'Cette action est irréversible : la demande sera retirée du suivi RH.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Retour'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Annuler la demande'),
          ),
        ],
      ),
    );
    if (confirme != true) return;

    setState(() => _annulation = true);
    try {
      await _api.annulerDemande(widget.demandeId);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _annulation = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détail de la demande')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brand),
            )
          : _error != null
          ? EmptyState(
              icone: Icons.error_outline,
              titre: 'Chargement impossible',
              texte: _error!,
              action: OutlinedButton(
                onPressed: _load,
                child: const Text('Réessayer'),
              ),
            )
          : _corps(),
    );
  }

  Widget _corps() {
    final d = _demande!;
    final df = DateFormat('dd/MM/yyyy');
    final memeJour = d.dateDebut == d.dateFin;

    final marge = margeLaterale(context, minimum: 20);

    return ListView(
      padding: EdgeInsets.fromLTRB(marge, 8, marge, 32),
      children: [
        // Carte d'en-tête
        CarteBlanche(
          padding: const EdgeInsets.all(18),
          ombre: AppShadows.flottant,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TypeTile(type: d.type, taille: 46),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          typeLabel(d.type),
                          style: titreDisplay(taille: 21, hauteur: 1.1),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Demande n° ${d.id}',
                          style: const TextStyle(
                            color: AppColors.faint,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(statut: d.statut),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 16),
              _ligne(
                Icons.calendar_today_outlined,
                memeJour ? 'Date' : 'Période',
                memeJour
                    ? df.format(d.dateDebut)
                    : '${df.format(d.dateDebut)} → ${df.format(d.dateFin)}',
              ),
              const SizedBox(height: 13),
              _ligne(Icons.notes_outlined, 'Détail', d.resumeDetail),
              if (d.commentaire != null && d.commentaire!.isNotEmpty) ...[
                const SizedBox(height: 13),
                _ligne(
                  Icons.chat_bubble_outline,
                  'Commentaire RH',
                  d.commentaire!,
                ),
              ],
              if (d.validateur != null) ...[
                const SizedBox(height: 13),
                _ligne(
                  Icons.person_outline,
                  'Traitée par',
                  d.validateur!.nomComplet,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 26),
        Text('SUIVI', style: eyebrowStyle),
        const SizedBox(height: 12),

        if (d.historiques.isEmpty)
          const Text(
            'Aucun évènement enregistré.',
            style: TextStyle(color: AppColors.inkMuted, fontSize: 14),
          )
        else
          ...List.generate(d.historiques.length, (i) {
            final h = d.historiques[i];
            final dernier = i == d.historiques.length - 1;
            final couleur = h.action == 'validee'
                ? AppColors.ok
                : h.action == 'refusee'
                ? AppColors.danger
                : AppColors.brand;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Jalon + filet de liaison
                  Column(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: couleur.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          h.action == 'validee'
                              ? Icons.check
                              : h.action == 'refusee'
                              ? Icons.close
                              : Icons.edit_outlined,
                          size: 13,
                          color: couleur,
                        ),
                      ),
                      if (!dernier)
                        Expanded(
                          child: Container(width: 1.5, color: AppColors.line),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: dernier ? 0 : 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _actionLabels[h.action] ?? h.action,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "${DateFormat("dd/MM/yyyy 'à' HH:mm").format(h.dateAction)}"
                            "${h.acteur != null ? ' · ${h.acteur!.nomComplet}' : ''}",
                            style: const TextStyle(
                              color: AppColors.faint,
                              fontSize: 12.5,
                            ),
                          ),
                          if (h.commentaire != null &&
                              h.commentaire!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: const BoxDecoration(
                                color: AppColors.surfaceAlt,
                                border: Border(
                                  left: BorderSide(
                                    color: AppColors.line2,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                '« ${h.commentaire} »',
                                style: const TextStyle(
                                  color: AppColors.inkMuted,
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

        if (d.statut == 'en_attente') ...[
          const SizedBox(height: 30),
          OutlinedButton.icon(
            onPressed: _annulation ? null : _annuler,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: Text(_annulation ? 'Annulation…' : 'Annuler la demande'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.dangerLine),
            ),
          ),
        ],
      ],
    );
  }

  Widget _ligne(IconData icone, String label, String valeur) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, size: 17, color: AppColors.faint),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.faint, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(valeur, style: const TextStyle(fontSize: 14.5, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}
