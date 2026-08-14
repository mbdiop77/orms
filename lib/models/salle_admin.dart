class SalleAdmin {
  final String id;
  final String nom;
  final String? code;
  final String compartimentId;
  final String? departementId;
  final int capacite;
  final String statut;
  final bool actif;

  SalleAdmin({
    required this.id,
    required this.nom,
    this.code,
    required this.compartimentId,
    this.departementId,
    required this.capacite,
    required this.statut,
    required this.actif,
  });

  factory SalleAdmin.fromMap(Map<String, dynamic> map) {
    return SalleAdmin(
      id: map['id'] as String,
      nom: map['nom'] as String,
      code: map['code'] as String?,
      compartimentId: map['compartiment_id'] as String,
      departementId: map['departement_id'] as String?,
      capacite: (map['capacite'] as int?) ?? 0,
      statut: map['statut'] as String,
      actif: (map['actif'] as bool?) ?? true,
    );
  }
}