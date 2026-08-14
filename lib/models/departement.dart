class Departement {
  final String id;
  final String nom;

  Departement({required this.id, required this.nom});

  factory Departement.fromMap(Map<String, dynamic> map) {
    return Departement(
      id: map['id'] as String,
      nom: map['nom'] as String,
    );
  }
}