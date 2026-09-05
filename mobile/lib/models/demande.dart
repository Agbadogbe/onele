import 'user.dart';

class HistoriqueEntry {
  final String action;
  final String? commentaire;
  final DateTime dateAction;
  final AppUser? acteur;

  HistoriqueEntry({
    required this.action,
    required this.commentaire,
    required this.dateAction,
    required this.acteur,
  });

  factory HistoriqueEntry.fromJson(Map<String, dynamic> json) {
    return HistoriqueEntry(
      action: json['action'] as String,
      commentaire: json['commentaire'] as String?,
      dateAction: DateTime.parse(json['date_action'] as String),
      acteur:
          json['acteur'] is Map<String, dynamic> &&
              (json['acteur'] as Map).isNotEmpty
          ? AppUser.fromJson(json['acteur'] as Map<String, dynamic>)
          : null,
    );
  }
}

class Demande {
  final int id;
  final String type;
  final DateTime dateDebut;
  final DateTime dateFin;
  final String statut;
  final String? commentaire;
  final AppUser? utilisateur;
  final AppUser? validateur;
  final Map<String, dynamic>? detail;
  final DateTime createdAt;
  final List<HistoriqueEntry> historiques;

  Demande({
    required this.id,
    required this.type,
    required this.dateDebut,
    required this.dateFin,
    required this.statut,
    required this.commentaire,
    required this.utilisateur,
    required this.validateur,
    required this.detail,
    required this.createdAt,
    this.historiques = const [],
  });

  /// L'API renvoie « 14:00:00 » : on n'affiche que les heures et minutes.
  static String _heure(Object? valeur) {
    final texte = valeur?.toString() ?? '';
    return texte.length >= 5 ? texte.substring(0, 5) : texte;
  }

  static String _capitaliser(Object? valeur) {
    final texte = valeur?.toString() ?? '';
    return texte.isEmpty ? texte : texte[0].toUpperCase() + texte.substring(1);
  }

  String get resumeDetail {
    if (detail == null) return '—';
    switch (type) {
      case 'conge':
        return '${_capitaliser(detail!['type_conge'])} · ${detail!['nombre_jours']} j';
      case 'permission':
        final motif = detail!['motif']?.toString() ?? '';
        final heures =
            '${_heure(detail!['heure_debut'])} – ${_heure(detail!['heure_fin'])}';
        return motif.isEmpty ? heures : '$heures · $motif';
      case 'materiel':
        final materiel = detail!['materiel'] as Map<String, dynamic>?;
        return '${materiel?['nom'] ?? ''} ×${detail!['quantite']}';
      default:
        return '—';
    }
  }

  factory Demande.fromJson(Map<String, dynamic> json) {
    return Demande(
      id: json['id'] as int,
      type: json['type'] as String,
      dateDebut: DateTime.parse(json['date_debut'] as String),
      dateFin: DateTime.parse(json['date_fin'] as String),
      statut: json['statut'] as String,
      commentaire: json['commentaire'] as String?,
      utilisateur:
          json['utilisateur'] is Map<String, dynamic> &&
              (json['utilisateur'] as Map).isNotEmpty
          ? AppUser.fromJson(json['utilisateur'] as Map<String, dynamic>)
          : null,
      validateur:
          json['validateur'] is Map<String, dynamic> &&
              (json['validateur'] as Map).isNotEmpty
          ? AppUser.fromJson(json['validateur'] as Map<String, dynamic>)
          : null,
      detail: json['detail'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      historiques: (json['historiques'] as List<dynamic>? ?? [])
          .map((e) => HistoriqueEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
