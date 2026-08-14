import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';import '../core/supabase_client.dart';

class ReservationController extends StateNotifier<AsyncValue<void>> {
  ReservationController() : super(const AsyncValue.data(null));

  Future<bool> creerReservation({
    required String salleId,
    required String motifId,
    String? titre,
    required DateTime dateDebut,
    required DateTime dateFin,
  }) async {
    state = const AsyncValue.loading();
    try {
      final userId = supabase.auth.currentUser!.id;

      await supabase.from('reservations').insert({
        'salle_id': salleId,
        'formateur_id': userId,
        'motif_id': motifId,
        'titre': titre,
        'date_debut': dateDebut.toIso8601String(),
        'date_fin': dateFin.toIso8601String(),
        'statut': 'confirmee',
      });

      state = const AsyncValue.data(null);
      return true;
    } on PostgrestException catch (e, st) {
      // Code de la contrainte exclude (chevauchement) : 23P01
      if (e.code == '23P01') {
        state = AsyncValue.error(
          'Ce créneau chevauche une réservation existante pour cette salle.',
          st,
        );
      } else {
        state = AsyncValue.error(e.message, st);
      }
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final reservationControllerProvider =
    StateNotifierProvider<ReservationController, AsyncValue<void>>((ref) {
  return ReservationController();
});