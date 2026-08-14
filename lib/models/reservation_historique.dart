class ReservationHistorique {
  final String id;
  final String salleId;
  final String salleNom;
  final String? salleCode;
  final int salleCapacite;
  final int salleEtageNumero;
  final String? salleEtageNom;
  final String? salleDepartementNom;
  final String? salleCompartimentNom;
  final String formateurId;
  final String? formateurNom;
  final String? motifLibelle;
  final String? titre;
  final DateTime dateDebut;
  final DateTime dateFin;
  final String statut;
  final int prolongationMinutes;
  final String? decaleParReservationId;
  final int minutesDecalage;
  final String? decaleParNom;
  final DateTime createdAt;
  final String statutAffichage;

  ReservationHistorique({
    required this.id,
    required this.salleId,
    required this.salleNom,
    this.salleCode,
    required this.salleCapacite,
    required this.salleEtageNumero,
    this.salleEtageNom,
    this.salleDepartementNom,
    this.salleCompartimentNom,
    required this.formateurId,
    this.formateurNom,
    this.motifLibelle,
    this.titre,
    required this.dateDebut,
    required this.dateFin,
    required this.statut,
    required this.prolongationMinutes,
    this.decaleParReservationId,
    required this.minutesDecalage,
    this.decaleParNom,
    required this.createdAt,
    required this.statutAffichage,
  });

  String get salleEtageLabel =>
      (salleEtageNom != null && salleEtageNom!.isNotEmpty) ? salleEtageNom! : 'Niveau $salleEtageNumero';

  String get salleDepartementLabel => salleDepartementNom ?? 'Sans département';

  factory ReservationHistorique.fromMap(Map<String, dynamic> map) {
    return ReservationHistorique(
      id: map['id'] as String,
      salleId: map['salle_id'] as String,
      salleNom: map['salle_nom'] as String,
      salleCode: map['salle_code'] as String?,
      salleCapacite: (map['salle_capacite'] as int?) ?? 0,
      salleEtageNumero: (map['salle_etage_numero'] as int?) ?? 0,
      salleEtageNom: map['salle_etage_nom'] as String?,
      salleDepartementNom: map['salle_departement_nom'] as String?,
      salleCompartimentNom: map['salle_compartiment_nom'] as String?,
      formateurId: map['formateur_id'] as String,
      formateurNom: map['formateur_nom'] as String?,
      motifLibelle: map['motif_libelle'] as String?,
      titre: map['titre'] as String?,
      dateDebut: DateTime.parse(map['date_debut'] as String),
      dateFin: DateTime.parse(map['date_fin'] as String),
      statut: map['statut'] as String,
      prolongationMinutes: (map['prolongation_minutes'] as int?) ?? 0,
      decaleParReservationId: map['decale_par_reservation_id'] as String?,
      minutesDecalage: (map['minutes_decalage'] as int?) ?? 0,
      decaleParNom: map['decale_par_nom'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      statutAffichage: map['statut_affichage'] as String,
    );
  }
}