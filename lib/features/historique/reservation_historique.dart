import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/reservation_historique.dart';
import '../../providers/historique_reservations_provider.dart';
import '../../providers/current_profile_provider.dart';
import '../../providers/reservation_actions_controller.dart';

//const _kIndigo = Color(0xFF4F46E5);
const _kIndigoClair = Color(0xFFA5B4FC);
const _kTexteClair = Color(0xFFF1F5F9);

class ReservationHistoriqueSection extends ConsumerWidget {
  const ReservationHistoriqueSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historiqueAsync = ref.watch(historiqueReservationsProvider);
    final profilAsync = ref.watch(currentProfileProvider);

    final estAdmin = profilAsync.maybeWhen(
      data: (p) => p['role'] == 'admin',
      orElse: () => false,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 24, 12, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kIndigoClair.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.history_rounded, size: 18, color: _kIndigoClair),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                  estAdmin ? 'Toutes les réservations' : 'Mes réservations',
                  style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: _kTexteClair),
                ),)
              ],
            ),
          ),
          const SizedBox(height: 12),
          historiqueAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(color: _kIndigoClair)),
            ),
            error: (err, st) => Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Erreur : $err', style: const TextStyle(color: _kTexteClair)),
            ),
            data: (liste) {
              if (liste.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
                  child: Text(
                    'Aucune réservation pour le moment.',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                );
              }
              return Column(
                children: liste.map((r) => _ReservationCard(reservation: r, estAdmin: estAdmin)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReservationCard extends ConsumerWidget {
  final ReservationHistorique reservation;
  final bool estAdmin;

  const _ReservationCard({required this.reservation, required this.estAdmin});

  _StatutStyle get _style {
    switch (reservation.statutAffichage) {
      case 'en_cours':
        return _StatutStyle('En cours', const Color(0xFF4ADE80));
      case 'a_venir':
        return _StatutStyle('A venir', const Color(0xFF60A5FA));
      case 'annulee':
        return _StatutStyle('Annulée', const Color(0xFF94A3B8));
      case 'terminee':
      default:
        return _StatutStyle('Terminée', const Color(0xFF94A3B8));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = _style;
    final dateFmt = DateFormat('EEE d MMM', 'fr_FR');
    final heureFmt = DateFormat.Hm('fr_FR');
    final actionState = ref.watch(reservationActionsControllerProvider);

    ref.listen(reservationActionsControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (err, st) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err.toString()),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        ),
      );
    });

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: style.couleur, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Tooltip(
                    waitDuration: const Duration(milliseconds: 250),
                    padding: EdgeInsets.zero,
                    margin: EdgeInsets.zero,
                    decoration: const BoxDecoration(color: Colors.transparent),
                    richMessage: WidgetSpan(
                      child: _SalleInfoBulle(reservation: reservation),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            reservation.salleNom,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: _kTexteClair,
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.info_outline_rounded,
                          size: 13,
                          color: Colors.grey.shade500,
                        ),
                      ],
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: style.couleur.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: style.couleur.withValues(alpha: 0.4)),
                ),
                child: Text(
                  style.libelle,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: style.couleur),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${dateFmt.format(reservation.dateDebut)}  •  '
            '${heureFmt.format(reservation.dateDebut)} – ${heureFmt.format(reservation.dateFin)}',
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade300),
          ),
          if (reservation.motifLibelle != null || reservation.titre != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                [reservation.motifLibelle, reservation.titre].where((e) => e != null && e.isNotEmpty).join(' — '),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ),
          if (estAdmin && reservation.formateurNom != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Par ${reservation.formateurNom}',
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
              ),
            ),
          if ((reservation.statutAffichage == 'a_venir' || reservation.statutAffichage == 'en_cours') &&
            reservation.minutesDecalage > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFFFBBF24)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFFFDE68A), height: 1.4),
                      children: [
                        const TextSpan(
                          text: "L'occupant actuel, ",
                       //   style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text: reservation.decaleParNom ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text: ', a demandé ${reservation.minutesDecalage} min de plus. '
                              'Ton créneau démarre maintenant à ${heureFmt.format(reservation.dateDebut)}.',
                        ),
                      ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (reservation.statutAffichage == 'a_venir' || reservation.statutAffichage == 'en_cours') ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (reservation.statutAffichage == 'a_venir') ...[
                  _ActionChip(
                    label: 'Modifier',
                    icone: Icons.edit_calendar_rounded,
                    couleur: _kIndigoClair,
                    occupe: actionState.isLoading,
                    onTap: () => _ouvrirModification(context, ref),
                  ),
                  _ActionChip(
                    label: 'Annuler',
                    icone: Icons.close_rounded,
                    couleur: const Color(0xFFF87171),
                    occupe: actionState.isLoading,
                    onTap: () => _confirmerAnnulation(context, ref),
                  ),
                ],
                if (reservation.statutAffichage == 'en_cours') ...[
                  _ActionChip(
                    label: 'Libérer la salle',
                    icone: Icons.logout_rounded,
                    couleur: const Color(0xFFF87171),
                    occupe: actionState.isLoading,
                    onTap: () => _confirmerLiberation(context, ref),
                  ),
                  if (reservation.prolongationMinutes < 10) ...[
                    _ActionChip(
                      label: '+5 min',
                      icone: Icons.add_circle_outline_rounded,
                      couleur: const Color(0xFFFBBF24),
                      occupe: actionState.isLoading,
                      onTap: () => ref.read(reservationActionsControllerProvider.notifier).prolonger(
                            reservationId: reservation.id,
                            salleId: reservation.salleId,
                            finActuelle: reservation.dateFin,
                            minutesDejaProlongees: reservation.prolongationMinutes,
                            minutesAjoutees: 5,
                          ),
                    ),
                    if (reservation.prolongationMinutes <= 0)
                      _ActionChip(
                        label: '+10 min',
                        icone: Icons.add_circle_outline_rounded,
                        couleur: const Color(0xFFFBBF24),
                        occupe: actionState.isLoading,
                        onTap: () => ref.read(reservationActionsControllerProvider.notifier).prolonger(
                              reservationId: reservation.id,
                              salleId: reservation.salleId,
                              finActuelle: reservation.dateFin,
                              minutesDejaProlongees: reservation.prolongationMinutes,
                              minutesAjoutees: 10,
                            ),
                      ),
                  ],
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _confirmerAnnulation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Annuler la réservation ?', style: TextStyle(color: _kTexteClair)),
        content: Text(
          '${reservation.salleNom} — ${DateFormat.Hm('fr_FR').format(reservation.dateDebut)}',
          style: TextStyle(color: Colors.grey.shade300),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Retour')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () {
              Navigator.pop(context);
              ref.read(reservationActionsControllerProvider.notifier).annuler(reservation.id);
            },
            child: const Text('Annuler la réservation'),
          ),
        ],
      ),
    );
  }

  void _confirmerLiberation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Libérer la salle ?', style: TextStyle(color: _kTexteClair)),
        content: Text(
          '${reservation.salleNom} sera immédiatement marquée comme libre.',
          style: TextStyle(color: Colors.grey.shade300),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Retour')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(reservationActionsControllerProvider.notifier).libererMaintenant(reservation.id);
            },
            child: const Text('Libérer'),
          ),
        ],
      ),
    );
  }

  void _ouvrirModification(BuildContext context, WidgetRef ref) {
    DateTime dateDebut = reservation.dateDebut;
    DateTime dateFin = reservation.dateFin;
    TimeOfDay heureDebut = TimeOfDay.fromDateTime(reservation.dateDebut);
    TimeOfDay heureFin = TimeOfDay.fromDateTime(reservation.dateFin);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          final dateFmt = DateFormat('EEE d MMM', 'fr_FR');
          return Dialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modifier le créneau — ${reservation.salleNom}',
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: _kTexteClair),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ChampMini(
                          label: 'Date début',
                          valeur: dateFmt.format(dateDebut),
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: dateDebut,
                              firstDate: DateTime.now().subtract(const Duration(days: 1)),
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                            );
                            if (d != null) setState(() => dateDebut = d);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ChampMini(
                          label: 'Heure',
                          valeur: heureDebut.format(context),
                          onTap: () async {
                            final h = await showTimePicker(context: context, initialTime: heureDebut);
                            if (h != null) setState(() => heureDebut = h);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _ChampMini(
                          label: 'Date fin',
                          valeur: dateFmt.format(dateFin),
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: dateFin,
                              firstDate: DateTime.now().subtract(const Duration(days: 1)),
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                            );
                            if (d != null) setState(() => dateFin = d);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ChampMini(
                          label: 'Heure',
                          valeur: heureFin.format(context),
                          onTap: () async {
                            final h = await showTimePicker(context: context, initialTime: heureFin);
                            if (h != null) setState(() => heureFin = h);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            final nouveauDebut = DateTime(dateDebut.year, dateDebut.month, dateDebut.day,
                                heureDebut.hour, heureDebut.minute);
                            final nouveauFin = DateTime(
                                dateFin.year, dateFin.month, dateFin.day, heureFin.hour, heureFin.minute);

                            if (!nouveauFin.isAfter(nouveauDebut)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('La fin doit être après le début')),
                              );
                              return;
                            }

                            Navigator.pop(dialogContext);
                            ref.read(reservationActionsControllerProvider.notifier).modifierCreneau(
                                  reservationId: reservation.id,
                                  nouveauDebut: nouveauDebut,
                                  nouveauFin: nouveauFin,
                                );
                          },
                          child: const Text('Enregistrer'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatutStyle {
  final String libelle;
  final Color couleur;
  _StatutStyle(this.libelle, this.couleur);
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icone;
  final Color couleur;
  final bool occupe;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.icone,
    required this.couleur,
    required this.occupe,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: occupe ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: couleur.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: couleur.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 13, color: couleur),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: couleur)),
          ],
        ),
      ),
    );
  }
}

class _ChampMini extends StatelessWidget {
  final String label;
  final String valeur;
  final VoidCallback onTap;

  const _ChampMini({required this.label, required this.valeur, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade400)),
            const SizedBox(height: 3),
            Text(valeur, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _kTexteClair)),
          ],
        ),
      ),
    );
  }
}

class _SalleInfoBulle extends StatelessWidget {
  final ReservationHistorique reservation;

  const _SalleInfoBulle({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final compartiment = (reservation.salleCompartimentNom != null &&
            reservation.salleCompartimentNom!.isNotEmpty)
        ? reservation.salleCompartimentNom!
        : null;

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.place_rounded, size: 14, color: _kIndigoClair),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Localisation exacte de la salle',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.meeting_room_rounded, size: 15, color: _kIndigoClair),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    reservation.salleNom,
                    style: const TextStyle(color: _kTexteClair, fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (reservation.salleCode != null && reservation.salleCode!.isNotEmpty) ...[
              const SizedBox(height: 6),
              _LigneInfo(icone: Icons.qr_code_2_rounded, texte: 'Code : ${reservation.salleCode}'),
            ],
            const SizedBox(height: 6),
            _LigneInfo(
              icone: Icons.layers_rounded,
              texte: compartiment != null
                  ? '${reservation.salleEtageLabel} ($compartiment)'
                  : reservation.salleEtageLabel,
            ),
            const SizedBox(height: 6),
            _LigneInfo(
              icone: Icons.apartment_rounded,
              texte: reservation.salleDepartementLabel,
            ),
            if (reservation.salleCapacite > 0) ...[
              const SizedBox(height: 6),
              _LigneInfo(
                icone: Icons.people_outline_rounded,
                texte: '${reservation.salleCapacite} place${reservation.salleCapacite > 1 ? 's' : ''}',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LigneInfo extends StatelessWidget {
  final IconData icone;
  final String texte;

  const _LigneInfo({required this.icone, required this.texte});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, size: 13, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texte,
            style: TextStyle(color: Colors.grey.shade300, fontSize: 12),
          ),
        ),
      ],
    );
  }
}