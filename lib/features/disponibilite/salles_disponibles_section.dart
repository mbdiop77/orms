import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/salle_temps_reel.dart';
import '../../providers/salles_temps_reel_provider.dart';
import '../../providers/current_profile_provider.dart';
import '../reservation/reservation_dialog.dart';

const _kIndigo = Color(0xFF4F46E5);
const _kIndigoClair = Color(0xFFA5B4FC);
const _kVert = Color(0xFF4ADE80);
const _kOrange = Color(0xFFFBBF24);
const _kTexteClair = Color(0xFFF1F5F9);

class SallesDisponiblesSection extends ConsumerStatefulWidget {
  const SallesDisponiblesSection({super.key});

  @override
  ConsumerState<SallesDisponiblesSection> createState() => _SallesDisponiblesSectionState();
}

enum _ModeRecherche { disponibleMaintenant, bientotLibre }

class _SallesDisponiblesSectionState extends ConsumerState<SallesDisponiblesSection> {
  bool _ouvert = false;
  String? _departementSelectionne;
  _ModeRecherche _mode = _ModeRecherche.disponibleMaintenant;

  Duration? _dureeSelectionnee;
  bool _journeeSelectionnee = false;
  DateTime? _rechercheDebut;
  DateTime? _rechercheFin;

  int? _minutesSelectionnees;

  static const _dureesPreset = [
    ('30 min', Duration(minutes: 30)),
    ('1h30', Duration(hours: 1, minutes: 30)),
    ('2h', Duration(hours: 2)),
    ('3h', Duration(hours: 3)),
  ];

  static const _minutesPreset = [5, 10, 15, 20, 30, 45, 60];

  static const int _heureOuverture = 8;
  static const int _heureFermeture = 22;

  bool _salleDisponiblePeriode(SalleTempsReel s, DateTime debut, DateTime fin) {
    if (s.debutOccupation != null && s.finOccupation != null) {
      if (debut.isBefore(s.finOccupation!) && fin.isAfter(s.debutOccupation!)) return false;
    }
    for (final r in s.reservationsAttente) {
      if (debut.isBefore(r.fin) && fin.isAfter(r.debut)) return false;
    }
    return true;
  }

  void _selectionnerJournee() {
    setState(() {
      _journeeSelectionnee = true;
      _dureeSelectionnee = null;
      _rechercheDebut = null;
      _rechercheFin = null;
    });
  }

  (DateTime, DateTime) _plageJournee() {
    final now = DateTime.now();
    final ouverture = DateTime(now.year, now.month, now.day, _heureOuverture);
    final fermeture = DateTime(now.year, now.month, now.day, _heureFermeture);
    return (ouverture, fermeture);
  }

  Future<void> _ouvrirRechercheManuelle() async {
    DateTime? debut = _rechercheDebut ?? DateTime.now();
    DateTime? fin = _rechercheFin;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final dateFmt = DateFormat('EEE d MMM à HH:mm', 'fr_FR');

          Future<void> choisir({required bool estDebut}) async {
            final base = estDebut ? (debut ?? DateTime.now()) : (fin ?? debut ?? DateTime.now());
            final date = await showDatePicker(
              context: context,
              initialDate: base,
              firstDate: DateTime.now().subtract(const Duration(days: 1)),
              lastDate: DateTime.now().add(const Duration(days: 90)),
              builder: (context, child) => Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(primary: _kIndigoClair, surface: Color(0xFF1E293B)),
                ),
                child: child!,
              ),
            );
            if (date == null || !context.mounted) return;

            final heure = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(base),
              builder: (context, child) => Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(primary: _kIndigoClair, surface: Color(0xFF1E293B)),
                ),
                child: child!,
              ),
            );
            if (heure == null || !context.mounted) return;

            final resultat = DateTime(date.year, date.month, date.day, heure.hour, heure.minute);
            setStateDialog(() {
              if (estDebut) {
                debut = resultat;
              } else {
                fin = resultat;
              }
            });
          }

          return Dialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Recherche manuelle',
                        style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: _kTexteClair)),
                    const SizedBox(height: 16),
                    _ChampMiniDate(
                      label: 'Début',
                      valeur: debut != null ? dateFmt.format(debut!) : null,
                      onTap: () => choisir(estDebut: true),
                    ),
                    const SizedBox(height: 10),
                    _ChampMiniDate(
                      label: 'Fin',
                      valeur: fin != null ? dateFmt.format(fin!) : null,
                      onTap: () => choisir(estDebut: false),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Annuler', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: _kIndigo,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: (debut != null && fin != null && fin!.isAfter(debut!))
                                ? () {
                                    setState(() {
                                      _rechercheDebut = debut;
                                      _rechercheFin = fin;
                                      _dureeSelectionnee = null;
                                      _journeeSelectionnee = false;
                                    });
                                    Navigator.pop(dialogContext);
                                  }
                                : null,
                            child: const Text('Rechercher', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profilAsync = ref.watch(currentProfileProvider);
    final peutReserver = profilAsync.maybeWhen(
      data: (p) => p['role'] != 'visiteur',
      orElse: () => false,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.055),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() => _ouvert = !_ouvert),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _kIndigoClair.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.search_rounded, size: 18, color: _kIndigoClair),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text('Salles disponibles',
                              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: _kTexteClair)),
                        ),
                        AnimatedRotation(
                          turns: _ouvert ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  child: _ouvert
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                          child: _corpsSection(peutReserver),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _corpsSection(bool peutReserver) {
    final sallesAsync = ref.watch(sallesTempsReelProvider);

    return sallesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(color: _kIndigoClair)),
      ),
      error: (err, st) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text('Erreur : $err', style: const TextStyle(color: _kTexteClair)),
      ),
      data: (salles) {
        final departements = salles.map((s) => s.departementLabel).toSet().toList()
          ..sort((a, b) {
            if (a.toUpperCase() == 'SUPPORT') return -1;
            if (b.toUpperCase() == 'SUPPORT') return 1;
            return a.compareTo(b);
          });
        _departementSelectionne ??= departements.firstWhere(
          (d) => d.toUpperCase() == 'SUPPORT',
          orElse: () => departements.isNotEmpty ? departements.first : '',
        );
        if (_departementSelectionne!.isEmpty) _departementSelectionne = null;

        final sallesDept = salles.where((s) => s.departementLabel == _departementSelectionne).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           // Text('Siège', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade400)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: departements.map((d) {
                return _ChipSelectionnable(
                  label: d,
                  selectionne: _departementSelectionne == d,
                  couleur: _kIndigoClair,
                  onTap: () => setState(() => _departementSelectionne = d),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ChipSelectionnable(
                  label: 'Disponibles pendant...',
                  icone: Icons.event_available_rounded,
                  selectionne: _mode == _ModeRecherche.disponibleMaintenant,
                  couleur: _kVert,
                  onTap: () => setState(() => _mode = _ModeRecherche.disponibleMaintenant),
                ),
                _ChipSelectionnable(
                  label: "Libres d'ici ...",
                  icone: Icons.hourglass_bottom_rounded,
                  selectionne: _mode == _ModeRecherche.bientotLibre,
                  couleur: _kOrange,
                  onTap: () => setState(() => _mode = _ModeRecherche.bientotLibre),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_mode == _ModeRecherche.disponibleMaintenant) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._dureesPreset.map((preset) {
                    final selectionne = _dureeSelectionnee == preset.$2 && _rechercheDebut == null && !_journeeSelectionnee;
                    return _ChipSelectionnable(
                      label: preset.$1,
                      selectionne: selectionne,
                      couleur: _kVert,
                      onTap: () => setState(() {
                        _dureeSelectionnee = preset.$2;
                        _journeeSelectionnee = false;
                        _rechercheDebut = null;
                        _rechercheFin = null;
                      }),
                    );
                  }),
                  _ChipSelectionnable(
                    label: 'Toute la journée',
                    selectionne: _journeeSelectionnee,
                    couleur: _kVert,
                    onTap: _selectionnerJournee,
                  ),
                  _ChipSelectionnable(
                    label: _rechercheDebut != null ? 'Plage personnalisée ✓' : 'Personnalisé…',
                    icone: Icons.tune_rounded,
                    selectionne: _rechercheDebut != null,
                    couleur: _kVert,
                    onTap: _ouvrirRechercheManuelle,
                  ),
                ],
              ),
            ] else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _minutesPreset.map((m) {
                  return _ChipSelectionnable(
                    label: '$m min',
                    selectionne: _minutesSelectionnees == m,
                    couleur: _kOrange,
                    onTap: () => setState(() => _minutesSelectionnees = m),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            _resultats(sallesDept, peutReserver),
          ],
        );
      },
    );
  }

  Widget _resultats(List<SalleTempsReel> sallesDept, bool peutReserver) {
    List<SalleTempsReel> resultats;
    String? sousTitreRecherche;

    if (_mode == _ModeRecherche.disponibleMaintenant) {
      DateTime? debut;
      DateTime? fin;

      if (_rechercheDebut != null && _rechercheFin != null) {
        debut = _rechercheDebut;
        fin = _rechercheFin;
        sousTitreRecherche =
            '${DateFormat('d MMM HH:mm', 'fr_FR').format(debut!)} → ${DateFormat('d MMM HH:mm', 'fr_FR').format(fin!)}';
      } else if (_journeeSelectionnee) {
        final plage = _plageJournee();
        debut = plage.$1;
        fin = plage.$2;
        sousTitreRecherche = 'toute la journée ($_heureOuverture h - $_heureFermeture h)';
      } else if (_dureeSelectionnee != null) {
        debut = DateTime.now();
        fin = debut.add(_dureeSelectionnee!);
      }

      if (debut == null || fin == null) {
        return Text('Choisis une durée pour lancer la recherche.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5));
      }

      resultats = sallesDept.where((s) => _salleDisponiblePeriode(s, debut!, fin!)).toList();
    } else {
      if (_minutesSelectionnees == null) {
        return Text('Choisis un délai pour lancer la recherche.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5));
      }
      resultats = sallesDept
    .where((s) =>
        s.statutActuel == 'occupee' &&
        s.minutesAvantLiberation != null &&
        s.minutesAvantLiberation! <= _minutesSelectionnees! &&
        s.reservationsAttente.isEmpty)
    .toList()
  ..sort((a, b) => (a.minutesAvantLiberation ?? 0).compareTo(b.minutesAvantLiberation ?? 0));
    }

    if (resultats.isEmpty) {
      return Text('Aucune salle trouvée pour ce critère.',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${resultats.length} salle${resultats.length > 1 ? 's' : ''} trouvée${resultats.length > 1 ? 's' : ''}'
          '${sousTitreRecherche != null ? ' libre $sousTitreRecherche' : ''}',
          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 8),
        ...resultats.map((s) => _ResultatSalle(
              salle: s,
              mode: _mode,
              onReserver: () => showReservationDialog(context, s),
              peutReserver: peutReserver,
            )),
      ],
    );
  }
}

class _ResultatSalle extends StatelessWidget {
  final SalleTempsReel salle;
  final _ModeRecherche mode;
  final VoidCallback onReserver;
  final bool peutReserver;

  const _ResultatSalle({
    required this.salle,
    required this.mode,
    required this.onReserver,
    required this.peutReserver,
  });

  @override
  Widget build(BuildContext context) {
    final couleur = mode == _ModeRecherche.bientotLibre ? _kOrange : _kVert;

    return LayoutBuilder(
  builder: (context, constraints) {
    final etroit = constraints.maxWidth <= 250;

    final blocNom = Tooltip(
    waitDuration: const Duration(milliseconds: 240),
    padding: EdgeInsets.zero,
    margin: EdgeInsets.zero,
    decoration: const BoxDecoration(color: Colors.transparent),
    richMessage: WidgetSpan(child: _InfoBulleSalle(salle: salle)),
    child: Row(
      children: [
        Flexible(
          child: Text(
            salle.nom,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFF1F5F9)),
          ),
        ),
        const SizedBox(width: 3),
        Icon(Icons.info_outline_rounded, size: 13, color: Colors.grey.shade500),
      ],
    ),
  );

    final badgeStatut = (mode == _ModeRecherche.bientotLibre && salle.minutesAvantLiberation != null)
    ? Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: couleur.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: couleur.withValues(alpha: 0.4)),
        ),
        child: Text(
          'Libre dans ${salle.minutesAvantLiberation} mn',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: couleur),
        ),
      )
   : Container(
       // padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
       // decoration: BoxDecoration(
       //   color: couleur.withValues(alpha: 0.16),
        //  borderRadius: BorderRadius.circular(20),
        //  border: Border.all(color: couleur.withValues(alpha: 0.4)),
       // ),
       // child: Text('Libre', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: couleur)),
      );


final boutonReserver = peutReserver
    ? TextButton(
        onPressed: onReserver,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: _kIndigoClair.withValues(alpha: 0.14),
          foregroundColor: _kIndigoClair,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        child: const Text('Réserver', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      )
    : null;
    // Écran etroit

    if (etroit) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      blocNom,
      const SizedBox(height: 8),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          badgeStatut,
          if (boutonReserver != null) ...[
            const SizedBox(width: 04),
            boutonReserver,
          ],
        ],
      ),
    ],
  );
}

    // Écran normal : tout sur une seule ligne
   return Row(
  children: [
    Expanded(child: blocNom),
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        badgeStatut,
        if (boutonReserver != null) ...[
          const SizedBox(width: 12),
          boutonReserver,
        ],
      ],
    ),
  ],
);
   },
  );
 }
}

class _InfoBulleSalle extends StatelessWidget {
  final SalleTempsReel salle;

  const _InfoBulleSalle({required this.salle});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 240),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.place_rounded, size: 13, color: _kIndigoClair),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Localisation exacte de la salle',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                const Icon(Icons.layers_rounded, size: 13, color: _kIndigoClair),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${salle.etageLabel} (${salle.compartimentLabel})',
                    style: const TextStyle(color: _kTexteClair, fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.apartment_rounded, size: 13, color: _kIndigoClair),
                const SizedBox(width: 6),
                Text(salle.departementLabel, style: TextStyle(color: Colors.grey.shade300, fontSize: 12)),
              ],
            ),
            if (salle.capacite > 0) ...[
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(Icons.people_outline_rounded, size: 13, color: _kIndigoClair),
                  const SizedBox(width: 6),
                  Text('${salle.capacite} places', style: TextStyle(color: Colors.grey.shade300, fontSize: 12)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChipSelectionnable extends StatelessWidget {
  final String label;
  final IconData? icone;
  final bool selectionne;
  final Color couleur;
  final VoidCallback onTap;

  const _ChipSelectionnable({
    required this.label,
    this.icone,
    required this.selectionne,
    required this.couleur,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selectionne ? couleur.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: selectionne ? couleur : Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icone != null) ...[
              Icon(icone, size: 13, color: selectionne ? const Color(0xFF0F172A) : Colors.grey.shade400),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selectionne ? const Color(0xFF0F172A) : Colors.grey.shade300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChampMiniDate extends StatelessWidget {
  final String label;
  final String? valeur;
  final VoidCallback onTap;

  const _ChampMiniDate({required this.label, required this.valeur, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade400)),
            const SizedBox(height: 3),
            Text(
              valeur ?? 'Choisir',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: valeur != null ? _kTexteClair : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}