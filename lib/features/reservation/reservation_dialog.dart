import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/salle_temps_reel.dart';
import '../../models/motif.dart';
import '../../providers/motifs_provider.dart';
import '../../providers/reservation_controller.dart';

const _kIndigo = Color(0xFF4F46E5);
const _kIndigoClaire = Color(0xFF6366F1);
const _kIndigoClair = Color(0xFFA5B4FC);
const _kFondDebut = Color(0xFF0F172A);
const _kFondFin = Color(0xFF1E293B);
const _kTexteClair = Color(0xFFF1F5F9);

Future<void> showReservationDialog(BuildContext context, SalleTempsReel salle) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Réservation',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, _, _) => const SizedBox.shrink(),
    transitionBuilder: (context, animation, _, _) {
      final courbe = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return Transform.scale(
        scale: 0.92 + (0.08 * courbe.value),
        child: Opacity(
          opacity: courbe.value,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: _ReservationDialogContent(salle: salle),
            ),
          ),
        ),
      );
    },
  );
}

class _ReservationDialogContent extends ConsumerStatefulWidget {
  final SalleTempsReel salle;

  const _ReservationDialogContent({required this.salle});

  @override
  ConsumerState<_ReservationDialogContent> createState() => _ReservationDialogContentState();
}

class _ReservationDialogContentState extends ConsumerState<_ReservationDialogContent> {
  final _formKey = GlobalKey<FormState>();
  final _titreCtrl = TextEditingController();

  Motif? _motifSelectionne;
  DateTime? _dateDebut;
  DateTime? _dateFin;
  TimeOfDay? _heureDebut;
  TimeOfDay? _heureFin;

  @override
  void dispose() {
    _titreCtrl.dispose();
    super.dispose();
  }

  Future<void> _choisirDate({required bool debut}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: debut ? now : (_dateDebut ?? now),
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: _kIndigoClaire, surface: _kFondFin),
        ),
        child: child!,
      ),
    );
    if (date == null) return;
    setState(() {
      if (debut) {
        _dateDebut = date;
        _dateFin ??= date;
      } else {
        _dateFin = date;
      }
    });
  }

  Future<void> _choisirHeure({required bool debut}) async {
    final heure = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: _kIndigoClaire, surface: _kFondFin),
        ),
        child: child!,
      ),
    );
    if (heure == null) return;
    setState(() {
      if (debut) {
        _heureDebut = heure;
      } else {
        _heureFin = heure;
      }
    });
  }

  DateTime? get _dateHeureDebut {
    if (_dateDebut == null || _heureDebut == null) return null;
    return DateTime(_dateDebut!.year, _dateDebut!.month, _dateDebut!.day,
        _heureDebut!.hour, _heureDebut!.minute);
  }

  DateTime? get _dateHeureFin {
    if (_dateFin == null || _heureFin == null) return null;
    return DateTime(_dateFin!.year, _dateFin!.month, _dateFin!.day,
        _heureFin!.hour, _heureFin!.minute);
  }

  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate()) return;

    if (_motifSelectionne == null) return _erreur('Choisis un motif');
    if (_dateDebut == null || _dateFin == null) {
      return _erreur('Choisis la période (date début et date fin)');
    }
    if (_heureDebut == null || _heureFin == null) {
      return _erreur('Choisis le créneau (heure début et heure fin)');
    }

    final debut = _dateHeureDebut!;
    final fin = _dateHeureFin!;

    if (!fin.isAfter(debut)) {
      return _erreur('La date/heure de fin doit être après le début');
    }

    final succes = await ref.read(reservationControllerProvider.notifier).creerReservation(
          salleId: widget.salle.id,
          motifId: _motifSelectionne!.id,
          titre: _titreCtrl.text.trim().isEmpty ? null : _titreCtrl.text.trim(),
          dateDebut: debut,
          dateFin: fin,
        );

    if (succes && mounted) Navigator.of(context).pop();
  }

  void _erreur(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final motifsAsync = ref.watch(motifsProvider);
    final reservationState = ref.watch(reservationControllerProvider);
    final dateFmt = DateFormat('EEE d MMM', 'fr_FR');

    ref.listen(reservationControllerProvider, (previous, next) {
      next.whenOrNull(error: (err, st) => _erreur(err.toString()));
    });

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_kFondDebut, _kFondFin],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(22, 22, 16, 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kIndigo, _kIndigoClaire],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.meeting_room_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nouvelle réservation',
                            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.salle.nom,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _Section(titre: 'Motif', icone: Icons.label_outline),
                        const SizedBox(height: 10),
                        motifsAsync.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator(color: _kIndigoClair)),
                          ),
                          error: (err, st) => Text('Erreur motifs : $err', style: const TextStyle(color: _kTexteClair)),
                          data: (motifs) {
                            final motifsTries = [...motifs]
                              ..sort((a, b) {
                                if (a.libelle == 'Other') return 1;
                                if (b.libelle == 'Other') return -1;
                                return 0;
                              });

                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: motifsTries.map((m) {
                                final selectionne = _motifSelectionne?.id == m.id;
                                return GestureDetector(
                                  onTap: () => setState(() => _motifSelectionne = m),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 02),
                                    decoration: BoxDecoration(
                                      color: selectionne ? _kIndigo : Colors.white.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: selectionne ? _kIndigo : Colors.white.withValues(alpha: 0.14),
                                      ),
                                    ),
                                    child: Text(
                                      m.libelle,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: selectionne ? Colors.white : Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          alignment: Alignment.topCenter,
                          child: (_motifSelectionne?.libelle == 'Other')
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 14),
                                  child: TextFormField(
                                    controller: _titreCtrl,
                                    style: const TextStyle(color: _kTexteClair),
                                    decoration: InputDecoration(
                                      labelText: 'Précisez le motif',
                                      labelStyle: TextStyle(color: Colors.grey.shade400),
                                      hintText: 'Ex : Onboarding équipe design',
                                      hintStyle: TextStyle(color: Colors.grey.shade600),
                                      filled: true,
                                      fillColor: Colors.white.withValues(alpha: 0.04),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: _kIndigoClair, width: 1.4),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (_motifSelectionne?.libelle == 'Other' &&
                                          (v == null || v.trim().isEmpty)) {
                                        return 'Précision requise pour ce motif';
                                      }
                                      return null;
                                    },
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 22),
                        const _Section(titre: 'Période', icone: Icons.date_range_rounded),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _ChampSelection(
                                label: 'Date début',
                                valeur: _dateDebut != null ? dateFmt.format(_dateDebut!) : null,
                                icone: Icons.calendar_today_rounded,
                                onTap: () => _choisirDate(debut: true),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ChampSelection(
                                label: 'Date fin',
                                valeur: _dateFin != null ? dateFmt.format(_dateFin!) : null,
                                icone: Icons.calendar_today_rounded,
                                onTap: () => _choisirDate(debut: false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        const _Section(titre: 'Créneau horaire', icone: Icons.schedule_rounded),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _ChampSelection(
                                label: 'Heure début',
                                valeur: _heureDebut?.format(context),
                                icone: Icons.access_time_rounded,
                                onTap: () => _choisirHeure(debut: true),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ChampSelection(
                                label: 'Heure fin',
                                valeur: _heureFin?.format(context),
                                icone: Icons.access_time_rounded,
                                onTap: () => _choisirHeure(debut: false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 26),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: reservationState.isLoading
                                  ? null
                                  : const LinearGradient(colors: [_kIndigo, _kIndigoClaire]),
                              color: reservationState.isLoading ? Colors.white.withValues(alpha: 0.08) : null,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: reservationState.isLoading ? null : _soumettre,
                                child: Center(
                                  child: reservationState.isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2.4, color: _kIndigoClair),
                                        )
                                      : const Text(
                                          'Confirmer la réservation',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String titre;
  final IconData icone;

  const _Section({required this.titre, required this.icone});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 15, color: _kIndigoClair),
        const SizedBox(width: 6),
        Text(
          titre,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFCBD5E1)),
        ),
      ],
    );
  }
}

class _ChampSelection extends StatelessWidget {
  final String label;
  final String? valeur;
  final IconData icone;
  final VoidCallback onTap;

  const _ChampSelection({
    required this.label,
    required this.valeur,
    required this.icone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rempli = valeur != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: rempli ? _kIndigoClair.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: rempli ? _kIndigoClair.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone, size: 13, color: rempli ? _kIndigoClair : Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              valeur ?? '',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: rempli ? _kTexteClair : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}