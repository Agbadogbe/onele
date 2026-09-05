import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/materiel.dart';
import '../services/onele_api.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class NewDemandeScreen extends StatefulWidget {
  /// Type présélectionné, et matériel déjà choisi le cas échéant : le
  /// catalogue amène ici avec la ligne déjà remplie.
  final String typeInitial;
  final int? materielInitialId;

  const NewDemandeScreen({
    super.key,
    this.typeInitial = 'conge',
    this.materielInitialId,
  });

  @override
  State<NewDemandeScreen> createState() => _NewDemandeScreenState();
}

class _NewDemandeScreenState extends State<NewDemandeScreen> {
  final _api = OneleApi();

  late String _type = widget.typeInitial;
  bool _submitting = false;
  String? _error;

  // Congé
  DateTime? _debut;
  DateTime? _fin;
  String _typeConge = 'annuel';
  final _nombreJours = TextEditingController();

  // Permission
  DateTime? _datePermission;
  TimeOfDay? _heureDebut;
  TimeOfDay? _heureFin;
  final _motifPermission = TextEditingController();

  // Matériel
  DateTime? _dateMateriel;
  List<Materiel> _materiels = [];
  Materiel? _materielChoisi;
  final _quantite = TextEditingController(text: '1');
  final _motifMateriel = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chargerMateriels();
  }

  Future<void> _chargerMateriels() async {
    try {
      final m = await _api.materiels();
      if (!mounted) return;
      setState(() {
        _materiels = m;
        // La ligne choisie au catalogue n'est retrouvable qu'une fois
        // l'inventaire arrivé : la sélection se pose ici, pas à l'init.
        final vise = widget.materielInitialId;
        if (vise != null) {
          for (final materiel in m) {
            if (materiel.id == vise) _materielChoisi = materiel;
          }
        }
      });
    } catch (_) {
      // L'inventaire reste vide : le formulaire matériel affichera une liste sans option.
    }
  }

  @override
  void dispose() {
    _nombreJours.dispose();
    _motifPermission.dispose();
    _quantite.dispose();
    _motifMateriel.dispose();
    super.dispose();
  }

  Future<DateTime?> _choisirDate(DateTime? initiale) {
    final maintenant = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initiale ?? maintenant,
      firstDate: maintenant.subtract(const Duration(days: 30)),
      lastDate: maintenant.add(const Duration(days: 365)),
      locale: const Locale('fr', 'FR'),
    );
  }

  Future<TimeOfDay?> _choisirHeure(TimeOfDay? initiale) {
    return showTimePicker(
      context: context,
      initialTime: initiale ?? TimeOfDay.now(),
    );
  }

  String _fmtDate(DateTime? d) =>
      d == null ? 'Choisir une date' : DateFormat('dd/MM/yyyy').format(d);
  String _fmtHeure(TimeOfDay? t) => t == null ? 'Choisir' : t.format(context);
  String _versApi(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    setState(() => _error = null);

    try {
      switch (_type) {
        case 'conge':
          if (_debut == null || _fin == null || _nombreJours.text.isEmpty) {
            throw 'Merci de renseigner les dates et le nombre de jours.';
          }
          setState(() => _submitting = true);
          await _api.creerDemandeConge(
            debut: _debut!,
            fin: _fin!,
            typeConge: _typeConge,
            nombreJours: int.parse(_nombreJours.text),
          );
        case 'permission':
          if (_datePermission == null ||
              _heureDebut == null ||
              _heureFin == null ||
              _motifPermission.text.isEmpty) {
            throw 'Merci de compléter tous les champs.';
          }
          setState(() => _submitting = true);
          await _api.creerDemandePermission(
            date: _datePermission!,
            heureDebut: _versApi(_heureDebut!),
            heureFin: _versApi(_heureFin!),
            motif: _motifPermission.text,
          );
        case 'materiel':
          if (_dateMateriel == null ||
              _materielChoisi == null ||
              _quantite.text.isEmpty) {
            throw 'Merci de compléter tous les champs.';
          }
          setState(() => _submitting = true);
          await _api.creerDemandeMateriel(
            date: _dateMateriel!,
            materielId: _materielChoisi!.id,
            quantite: int.parse(_quantite.text),
            motif: _motifMateriel.text,
          );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle demande')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            margeLaterale(context, minimum: 20),
            6,
            margeLaterale(context, minimum: 20),
            28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('TYPE DE DEMANDE', style: eyebrowStyle),
              const SizedBox(height: 10),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _carteType('conge'),
                    const SizedBox(width: 10),
                    _carteType('permission'),
                    const SizedBox(width: 10),
                    _carteType('materiel'),
                  ],
                ),
              ),
              const SizedBox(height: 26),

              if (_error != null) ...[
                ErrorBanner(message: _error!),
                const SizedBox(height: 18),
              ],

              if (_type == 'conge') _formulaireConge(),
              if (_type == 'permission') _formulairePermission(),
              if (_type == 'materiel') _formulaireMateriel(),

              const SizedBox(height: 28),
              PrimaryButton(
                libelle: 'Soumettre la demande',
                onPressed: _submitting ? null : _submit,
                chargement: _submitting,
                icone: Icons.send_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Sélecteur de type : trois cartes tactiles plutôt qu'un segment étroit.
  Widget _carteType(String type) {
    final actif = _type == type;
    final couleur = typeColor(type);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _type = type;
          _error = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: actif ? couleur : AppColors.line,
              width: actif ? 1.6 : 1,
            ),
            boxShadow: actif ? AppShadows.teinte(couleur) : AppShadows.carte,
          ),
          child: Column(
            children: [
              // La tuile prend la couleur pleine une fois choisie : le choix
              // se voit d'un coup d'œil, même en périphérie du regard.
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: actif ? typeGradient(type) : null,
                  color: actif ? null : couleur.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  typeIcon(type),
                  size: 19,
                  color: actif ? Colors.white : couleur,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                typeLabel(type),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: actif ? FontWeight.w600 : FontWeight.w400,
                  color: actif ? AppColors.ink : AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formulaireConge() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _typeConge,
          decoration: const InputDecoration(labelText: 'Type de congé'),
          items: const [
            DropdownMenuItem(value: 'annuel', child: Text('Annuel')),
            DropdownMenuItem(value: 'maladie', child: Text('Maladie')),
            DropdownMenuItem(
              value: 'exceptionnel',
              child: Text('Exceptionnel'),
            ),
          ],
          onChanged: (v) => setState(() => _typeConge = v!),
        ),
        const SizedBox(height: 14),
        _champDate('Date de début', _fmtDate(_debut), _debut != null, () async {
          final d = await _choisirDate(_debut);
          if (d != null) setState(() => _debut = d);
        }),
        const SizedBox(height: 14),
        _champDate('Date de fin', _fmtDate(_fin), _fin != null, () async {
          final d = await _choisirDate(_fin);
          if (d != null) setState(() => _fin = d);
        }),
        const SizedBox(height: 14),
        TextField(
          controller: _nombreJours,
          decoration: const InputDecoration(
            labelText: 'Nombre de jours',
            helperText: 'Jours ouvrés décomptés de votre solde',
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _formulairePermission() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _champDate(
          'Date',
          _fmtDate(_datePermission),
          _datePermission != null,
          () async {
            final d = await _choisirDate(_datePermission);
            if (d != null) setState(() => _datePermission = d);
          },
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _champDate(
                'Heure de début',
                _fmtHeure(_heureDebut),
                _heureDebut != null,
                () async {
                  final t = await _choisirHeure(_heureDebut);
                  if (t != null) setState(() => _heureDebut = t);
                },
                icone: Icons.schedule_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _champDate(
                'Heure de fin',
                _fmtHeure(_heureFin),
                _heureFin != null,
                () async {
                  final t = await _choisirHeure(_heureFin);
                  if (t != null) setState(() => _heureFin = t);
                },
                icone: Icons.schedule_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _motifPermission,
          decoration: const InputDecoration(
            labelText: 'Motif',
            hintText: 'Rendez-vous médical, démarche administrative…',
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _formulaireMateriel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _champDate(
          'Date souhaitée',
          _fmtDate(_dateMateriel),
          _dateMateriel != null,
          () async {
            final d = await _choisirDate(_dateMateriel);
            if (d != null) setState(() => _dateMateriel = d);
          },
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<Materiel>(
          initialValue: _materielChoisi,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Matériel'),
          hint: const Text('Choisir dans l’inventaire'),
          items: _materiels
              .map(
                (m) => DropdownMenuItem(
                  value: m,
                  child: Text(
                    '${m.nom}  ·  ${m.quantiteDisponible} dispo.',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _materielChoisi = v),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _quantite,
          decoration: const InputDecoration(labelText: 'Quantité'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _motifMateriel,
          decoration: const InputDecoration(
            labelText: 'Motif',
            hintText: 'Équipement du poste, présentation client…',
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  /// Champ tactile ouvrant un sélecteur : rendu identique aux autres champs.
  Widget _champDate(
    String label,
    String valeur,
    bool rempli,
    VoidCallback onTap, {
    IconData icone = Icons.calendar_today_outlined,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: Icon(icone, size: 19, color: AppColors.inkMuted),
        ),
        child: Text(
          valeur,
          style: TextStyle(
            fontSize: 15,
            color: rempli ? AppColors.ink : AppColors.faint,
          ),
        ),
      ),
    );
  }
}
