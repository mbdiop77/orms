class ReservationAttente {
  final DateTime debut;
  final DateTime fin;
  final String? titre;
  final String? occupant;
  final String? motif;

  ReservationAttente({
    required this.debut,
    required this.fin,
    this.titre,
    this.occupant,
    this.motif,
  });

  factory ReservationAttente.fromMap(Map<String, dynamic> map) {
    return ReservationAttente(
      debut: DateTime.parse(map['debut'] as String),
      fin: DateTime.parse(map['fin'] as String),
      titre: map['titre'] as String?,
      occupant: map['occupant'] as String?,
      motif: map['motif'] as String?,
    );
  }
}

class SalleTempsReel {
  final String id;
  final String nom;
  final String? code;
  final String compartimentId;
  final String? compartimentNom;
  final int etageNumero;
  final String? etageNom;
  final String? departementId;
  final String? departementNom;
  final int capacite;
  final String statut;
  final bool actif;

  final String statutActuel; // 'occupee' | 'maintenance' | 'libre'
  final String? occupeePar;
  final String? occupeeParNom;
  final DateTime? debutOccupation;
  final DateTime? finOccupation;
  final String? titreOccupation;
  final String? motifOccupation;
  final int? minutesAvantLiberation;
  final bool seraBientotDisponible;
  final String? liberationImminente;

  final List<ReservationAttente> reservationsAttente;

  SalleTempsReel({
    required this.id,
    required this.nom,
    this.code,
    required this.compartimentId,
    this.compartimentNom,
    required this.etageNumero,
    this.etageNom,
    this.departementId,
    this.departementNom,
    required this.capacite,
    required this.statut,
    required this.actif,
    required this.statutActuel,
    this.occupeePar,
    this.occupeeParNom,
    this.debutOccupation,
    this.finOccupation,
    this.titreOccupation,
    this.motifOccupation,
    this.minutesAvantLiberation,
    required this.seraBientotDisponible,
    this.liberationImminente,
    this.reservationsAttente = const [],
  });

  String get etageLabel =>
      (etageNom != null && etageNom!.isNotEmpty) ? etageNom! : 'Niveau $etageNumero';

  String get departementLabel =>
      (departementNom != null && departementNom!.isNotEmpty) ? departementNom! : 'Sans département';

  String get compartimentLabel =>
      (compartimentNom != null && compartimentNom!.isNotEmpty) ? compartimentNom! : 'Compartiment';

  factory SalleTempsReel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(String? key) =>
        map[key] != null ? DateTime.parse(map[key] as String) : null;

    final rawListe = map['reservations_attente'];
    final liste = <ReservationAttente>[];
    if (rawListe is List) {
      for (final e in rawListe) {
        liste.add(ReservationAttente.fromMap(e as Map<String, dynamic>));
      }
    }

    return SalleTempsReel(
      id: map['id'] as String,
      nom: map['nom'] as String,
      code: map['code'] as String?,
      compartimentId: map['compartiment_id'] as String,
      compartimentNom: map['compartiment_nom'] as String?,
      etageNumero: (map['etage_numero'] as int?) ?? 0,
      etageNom: map['etage_nom'] as String?,
      departementId: map['departement_id'] as String?,
      departementNom: map['departement_nom'] as String?,
      capacite: (map['capacite'] as int?) ?? 0,
      statut: map['statut'] as String,
      actif: (map['actif'] as bool?) ?? true,
      statutActuel: map['statut_actuel'] as String,
      occupeePar: map['occupee_par'] as String?,
      occupeeParNom: map['occupee_par_nom'] as String?,
      debutOccupation: parseDate('debut_occupation'),
      finOccupation: parseDate('fin_occupation'),
      titreOccupation: map['titre_occupation'] as String?,
      motifOccupation: map['motif_occupation'] as String?,
      minutesAvantLiberation: map['minutes_avant_liberation'] != null
          ? (map['minutes_avant_liberation'] as num).toInt()
          : null,
      seraBientotDisponible: (map['sera_bientot_disponible'] as bool?) ?? false,
      liberationImminente: map['liberation_imminente'] as String?,
      reservationsAttente: liste,
    );
  }
}