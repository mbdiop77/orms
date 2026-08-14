import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/salle_temps_reel.dart';

class SalleCard extends StatefulWidget {
  final SalleTempsReel salle;
  final VoidCallback onReserver;
  final bool peutReserver;

  const SalleCard({
    super.key,
    required this.salle,
    required this.onReserver,
    this.peutReserver = true,
  });

  @override
  State<SalleCard> createState() => _SalleCardState();
}

class _SalleCardState extends State<SalleCard> {
  bool _voirToutesAttentes = false;

  Color get _couleur {
    switch (widget.salle.statutActuel) {
      case 'occupee':
        return widget.salle.seraBientotDisponible ? const Color(0xFFFBBF24) : const Color(0xFFF87171);
      case 'maintenance':
        return const Color(0xFF94A3B8);
      default:
        return const Color(0xFF4ADE80);
    }
  }

  String get _libelleStatut {
    final salle = widget.salle;
    switch (salle.statutActuel) {
      case 'occupee':
        if (salle.seraBientotDisponible && salle.liberationImminente != null) {
          return 'Libre dans ${salle.liberationImminente}';
        }
        return 'Occupée';
      case 'maintenance':
        return 'Maintenance';
      default:
        return 'Libre';
    }
  }

  @override
  Widget build(BuildContext context) {
    final salle = widget.salle;
    final heureFmt = DateFormat.Hm('fr_FR');
    final dateFmt = DateFormat('d MMM', 'fr_FR');
    final couleur = _couleur;
    final attentes = salle.reservationsAttente;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: couleur.withValues(alpha: 0.15), blurRadius: 20, spreadRadius: -4, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0F172A).withValues(alpha: 0.82),
                  const Color(0xFF1E293B).withValues(alpha: 0.72),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: couleur.withValues(alpha: 0.35), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              LayoutBuilder(
      builder: (context, constraints) {
      final etroit = constraints.maxWidth <= 260;

      final blocNom = Row(
        children: [
          Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: couleur,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: couleur.withValues(alpha: 0.7), blurRadius: 8, spreadRadius: 1)],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
               Text(
                  salle.nom,
                overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFF1F5F9)),
                ),
                if (salle.capacite > 0) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.people_outline_rounded, size: 12, color: Colors.grey.shade400),
                  //    const SizedBox(width: 1),
                      
                      Expanded(
      child: Text(
        '${salle.capacite} place${salle.capacite > 1 ? 's' : ''}',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade400),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      );
final badgeStatut = Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
  decoration: BoxDecoration(
    color: couleur.withValues(alpha: 0.16),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: couleur.withValues(alpha: 0.4)),
  ),
  child: Text(
    _libelleStatut,
    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: couleur),
  ),
);

final boutonReserver = widget.peutReserver
    ? Material(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: widget.onReserver,
          borderRadius: BorderRadius.circular(20),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            child: Text(
              'Réserver',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFA5B4FC)),
            ),
          ),
        ),
      )
    : null;

    if (etroit) {
  // Écran étroit : nom en haut, badge + bouton alignés horizontalement en dessous
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          blocNom,
          const SizedBox(height: 8),
          Row(
            children: [
              badgeStatut,
              if (boutonReserver != null) ...[
                const SizedBox(width: 8),
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
        badgeStatut,
        if (boutonReserver != null) ...[
          const SizedBox(width: 8),
          boutonReserver,
        ],
      ],
    );
  },
),
                if (salle.statutActuel == 'occupee') ...[
                  const SizedBox(height: 10),
                  Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
                  const SizedBox(height: 10),
                  Text(
                    'Réservation en cours ${heureFmt.format(salle.debutOccupation ?? DateTime.now())} à '
                    '${heureFmt.format(salle.finOccupation ?? DateTime.now())}'
                    '  •  ${salle.occupeeParNom ?? ''}',
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFFCBD5E1)),
                  ),
                  if (salle.titreOccupation != null || salle.motifOccupation != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text( 
                        salle.titreOccupation ?? salle.motifOccupation!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ),
                ],
                if (attentes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: attentes.length > 1
                        ? () => setState(() => _voirToutesAttentes = !_voirToutesAttentes)
                        : null,
                    child: Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: attentes.length > 1
                              ? AnimatedRotation(
                                  turns: _voirToutesAttentes ? 0.125 : 0,
                                  duration: const Duration(milliseconds: 180),
                                  child: const Icon(Icons.add, size: 13, color: Color(0xFFA5B4FC)),
                                )
                              : const Icon(Icons.schedule, size: 12, color: Color(0xFFA5B4FC)),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _texteAttente(attentes.first, heureFmt, dateFmt),
                            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade400),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (attentes.length > 1)
                          Text(
                            '+${attentes.length - 1}',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                          ),
                      ],
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: (_voirToutesAttentes && attentes.length > 1)
                        ? Padding(
                            padding: const EdgeInsets.only(top: 6, left: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: attentes
                                  .skip(1)
                                  .map((r) => Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          _texteAttente(r, heureFmt, dateFmt),
                                          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade400),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _texteAttente(ReservationAttente r, DateFormat heureFmt, DateFormat dateFmt) {
    final aujourdHui = DateTime.now();
    final memeJour = r.debut.year == aujourdHui.year &&
        r.debut.month == aujourdHui.month &&
        r.debut.day == aujourdHui.day;
    final prefixeDate = memeJour ? '' : '${dateFmt.format(r.debut)} • ';

    return 'En attente : $prefixeDate${heureFmt.format(r.debut)} à ${heureFmt.format(r.fin)}'
        '${r.occupant != null ? ' — ${r.occupant}' : ''}';
  }
}