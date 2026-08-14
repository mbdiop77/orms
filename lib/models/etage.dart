class Etage {
  final String id;
  final int numero;
  final String? nom;

  Etage({required this.id, required this.numero, this.nom});

  factory Etage.fromMap(Map<String, dynamic> map) {
    return Etage(
      id: map['id'] as String,
      numero: (map['numero'] as int?) ?? 0,
      nom: map['nom'] as String?,
    );
  }
}