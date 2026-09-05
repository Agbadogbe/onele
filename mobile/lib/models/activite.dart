import 'demande.dart';

/// Un point du rythme mensuel : « 2026-08 » et le nombre de demandes déposées.
class PointMensuel {
  final DateTime mois;
  final int total;

  PointMensuel({required this.mois, required this.total});

  factory PointMensuel.fromJson(Map<String, dynamic> json) {
    final parties = (json['mois'] as String).split('-');
    return PointMensuel(
      mois: DateTime(int.parse(parties[0]), int.parse(parties[1])),
      total: json['total'] as int,
    );
  }
}

/// Le pendant employé du tableau de bord : ce que l'accueil résume en tête.
class MonActivite {
  final int joursCongesPris;
  final Map<String, int> parStatut;
  final Map<String, int> parType;
  final double? delaiReponseMoyenHeures;
  final List<PointMensuel> activiteMensuelle;
  final Demande? prochaineDemande;

  MonActivite({
    required this.joursCongesPris,
    required this.parStatut,
    required this.parType,
    required this.delaiReponseMoyenHeures,
    required this.activiteMensuelle,
    required this.prochaineDemande,
  });

  int statut(String cle) => parStatut[cle] ?? 0;

  int get total => parStatut.values.fold(0, (a, b) => a + b);

  factory MonActivite.fromJson(Map<String, dynamic> json) {
    final prochaine = json['prochaine_demande'];

    return MonActivite(
      joursCongesPris: json['jours_conges_pris'] as int? ?? 0,
      parStatut: _entiers(json['par_statut']),
      parType: _entiers(json['par_type']),
      delaiReponseMoyenHeures: (json['delai_reponse_moyen_heures'] as num?)
          ?.toDouble(),
      activiteMensuelle: (json['activite_mensuelle'] as List? ?? [])
          .map((e) => PointMensuel.fromJson(e as Map<String, dynamic>))
          .toList(),
      prochaineDemande: prochaine is Map<String, dynamic>
          ? Demande.fromJson(prochaine)
          : null,
    );
  }

  static Map<String, int> _entiers(Object? source) {
    if (source is! Map) return {};
    return source.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
  }
}
