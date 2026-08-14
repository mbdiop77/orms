class Reservation {
  final String id;
  final String salleId;
  final String titre;
  final String statut; // 'libre' | 'occupée'
  final DateTime heureDebut;
  final DateTime heureFin;

  Reservation({
    required this.id,
    required this.salleId,
    required this.titre,
    required this.statut,
    required this.heureDebut,
    required this.heureFin,
  });

  factory Reservation.fromMap(Map<String, dynamic> map) {
    return Reservation(
      id: map['id'] as String,
      salleId: map['salle_id'] as String,
      titre: map['titre'] as String,
      statut: map['statut'] as String,
      heureDebut: DateTime.parse(map['heure_debut'] as String),
      heureFin: DateTime.parse(map['heure_fin'] as String),
    );
  }
}