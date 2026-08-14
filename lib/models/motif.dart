class Motif {
  final String id;
  final String libelle;
  final bool necessitePrecision;

  Motif({required this.id, required this.libelle, required this.necessitePrecision});

  factory Motif.fromMap(Map<String, dynamic> map) {
    return Motif(
      id: map['id'] as String,
      libelle: map['libelle'] as String,
      necessitePrecision: (map['necessite_precision'] as bool?) ?? false,
    );
  }
}