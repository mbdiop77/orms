class Compartiment {
  final String id;
  final String etageId;
  final String nom;
  final String? code;

  Compartiment({required this.id, required this.etageId, required this.nom, this.code});

  factory Compartiment.fromMap(Map<String, dynamic> map) {
    return Compartiment(
      id: map['id'] as String,
      etageId: map['etage_id'] as String,
      nom: map['nom'] as String,
      code: map['code'] as String?,
    );
  }
}