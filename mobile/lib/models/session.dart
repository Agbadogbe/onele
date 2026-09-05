/// Un appareil connecté au compte — un jeton d'accès, vu de l'utilisateur.
class SessionOuverte {
  final int id;
  final String nom;
  final DateTime? derniereUtilisation;
  final DateTime? creeeLe;
  final bool actuelle;

  SessionOuverte({
    required this.id,
    required this.nom,
    required this.derniereUtilisation,
    required this.creeeLe,
    required this.actuelle,
  });

  factory SessionOuverte.fromJson(Map<String, dynamic> json) {
    DateTime? date(String cle) {
      final brut = json[cle];
      return brut is String ? DateTime.parse(brut).toLocal() : null;
    }

    return SessionOuverte(
      id: json['id'] as int,
      nom: json['nom'] as String? ?? 'Appareil',
      derniereUtilisation: date('derniere_utilisation'),
      creeeLe: date('creee_le'),
      actuelle: json['actuelle'] as bool? ?? false,
    );
  }

  /// Le nom du jeton dit d'où vient la session : on le rend lisible.
  String get libelle => switch (nom) {
    'mobile' => 'Application mobile',
    'api' => 'Espace web',
    'web' => 'Espace web',
    _ => nom,
  };
}
