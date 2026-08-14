import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/supabase_client.dart';
import '../../models/app_notification.dart';
import '../../providers/historique_reservations_provider.dart';
import '../../providers/notifications_controller.dart';
import '../../services/beep_service.dart';

class _EtatConnu {
  final String statut;
  final int minutesDecalage;
  final DateTime dateDebut;

  _EtatConnu({required this.statut, required this.minutesDecalage, required this.dateDebut});
}

/// Widget invisible : surveille les changements sur les réservations de
/// l'utilisateur connecté et déclenche bip + notification in-app pour :
/// - un créneau qui démarre dans moins de 5 minutes
/// - une réservation décalée par une prolongation
/// - une réservation annulée
class NotificationsWatcher extends ConsumerStatefulWidget {
  final Widget child;

  const NotificationsWatcher({super.key, required this.child});

  @override
  ConsumerState<NotificationsWatcher> createState() => _NotificationsWatcherState();
}

class _NotificationsWatcherState extends ConsumerState<NotificationsWatcher> {
  final Map<String, _EtatConnu> _etatsConnus = {};
  final Set<String> _dejaAlerteBientot = {};
  Timer? _minuteur;

  @override
  void initState() {
    super.initState();
    _minuteur = Timer.periodic(const Duration(seconds: 30), (_) => _verifierDemarragesImminents());
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    super.dispose();
  }

  String? get _userId => supabase.auth.currentUser?.id;

  void _verifierDemarragesImminents() {
    final maintenant = DateTime.now();
    for (final etat in _etatsConnus.entries) {
      if (etat.value.statut != 'confirmee') continue;
      final diff = etat.value.dateDebut.difference(maintenant);
      if (diff.inSeconds > 0 && diff.inMinutes < 5 && !_dejaAlerteBientot.contains(etat.key)) {
        _dejaAlerteBientot.add(etat.key);
        _notifier(
          type: TypeNotification.bientot,
          message: 'Ton créneau démarre dans moins de 5 minutes '
              '(${DateFormat.Hm('fr_FR').format(etat.value.dateDebut)}).',
        );
      }
    }
  }

  void _notifier({required TypeNotification type, required String message}) {
    if (!mounted) return;
    ref.read(notificationsControllerProvider.notifier).ajouter(
          AppNotification(
            id: '${DateTime.now().microsecondsSinceEpoch}',
            type: type,
            message: message,
            horodatage: DateTime.now(),
          ),
        );
    if (type == TypeNotification.annulation) {
      BeepService.jouerQuadruple();
    } else {
      BeepService.jouer();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(historiqueReservationsProvider, (previous, next) {
      next.whenData((liste) {
        final userId = _userId;
        if (userId == null) return;

        for (final r in liste) {
          if (r.formateurId != userId) continue;

          final precedent = _etatsConnus[r.id];

         if (precedent != null) {
            // Décalage détecté (à venir OU déjà en cours)
            if (r.minutesDecalage > precedent.minutesDecalage &&
                (r.statutAffichage == 'a_venir' || r.statutAffichage == 'en_cours')) {
              final minutesAjoutees = r.minutesDecalage - precedent.minutesDecalage;
              final nomOccupant = r.decaleParNom ?? 'Inconnu';

              _notifier(
                type: TypeNotification.decalage,
                message: "L'occupant actuel, $nomOccupant, a demandé "
                    "$minutesAjoutees minute${minutesAjoutees > 1 ? 's' : ''} de plus. "
                    "Votre créneau dans la salle ${r.salleNom} démarre à "
                    "${DateFormat.Hm('fr_FR').format(r.dateDebut)}.",
              );
            }
            // Annulation détectée
            if (precedent.statut == 'confirmee' && r.statut == 'annulee') {
              _notifier(
                type: TypeNotification.annulation,
                message: 'Ta réservation "${r.salleNom}" du '
                    '${DateFormat('d MMM à HH:mm', 'fr_FR').format(r.dateDebut)} a été annulée.',
              );
            }
          }

          _etatsConnus[r.id] = _EtatConnu(
            statut: r.statut,
            minutesDecalage: r.minutesDecalage,
            dateDebut: r.dateDebut,
          );
        }

        _verifierDemarragesImminents();
      });
    });

    return widget.child;
  }
}