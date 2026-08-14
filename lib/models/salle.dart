class Salle {
  final String id;
  final String nom;
  final int etage;

  Salle({required this.id, required this.nom, required this.etage});

  factory Salle.fromMap(Map<String, dynamic> map) {
    return Salle(
      id: map['id'] as String,
      nom: map['nom'] as String,
      etage: map['etage'] as int,
    );
  }
}