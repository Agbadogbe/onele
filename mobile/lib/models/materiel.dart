class Materiel {
  final int id;
  final String nom;
  final String? categorie;
  final String? description;
  final int quantiteDisponible;

  Materiel({
    required this.id,
    required this.nom,
    required this.categorie,
    required this.description,
    required this.quantiteDisponible,
  });

  factory Materiel.fromJson(Map<String, dynamic> json) {
    return Materiel(
      id: json['id'] as int,
      nom: json['nom'] as String,
      categorie: json['categorie'] as String?,
      description: json['description'] as String?,
      quantiteDisponible: json['quantite_disponible'] as int,
    );
  }
}
