import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';

class ReservationActionsController extends StateNotifier<AsyncValue<void>> {
  ReservationActionsController() : super(const AsyncValue.data(null));

  Future<bool> annuler(String reservationId) async {
    state = const AsyncValue.loading();
    try {
      await supabase.from('reservations').update({'statut': 'annulee'}).eq('id', reservationId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> libererMaintenant(String reservationId) async {
    state = const AsyncValue.loading();
    try {
      await supabase.from('reservations').update({'statut': 'terminee'}).eq('id', reservationId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

    Future<bool> prolonger({
    required String reservationId,
    required String salleId,
    required DateTime finActuelle,
    required int minutesDejaProlongees,
    required int minutesAjoutees,
  }) async {
    state = const AsyncValue.loading();
    try {
      await supabase.rpc('prolonger_reservation', params: {
        'p_reservation_id': reservationId,
        'p_minutes': minutesAjoutees,
      });
      state = const AsyncValue.data(null);
      return true;
    } on PostgrestException catch (e, st) {
      state = AsyncValue.error(e.message, st);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> modifierCreneau({
    required String reservationId,
    required DateTime nouveauDebut,
    required DateTime nouveauFin,
  }) async {
    state = const AsyncValue.loading();
    try {
      await supabase.from('reservations').update({
        'date_debut': nouveauDebut.toIso8601String(),
        'date_fin': nouveauFin.toIso8601String(),
      }).eq('id', reservationId);
      state = const AsyncValue.data(null);
      return true;
    } on PostgrestException catch (e, st) {
      if (e.code == '23P01') {
        state = AsyncValue.error('Ce créneau chevauche une autre réservation existante', st);
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

final reservationActionsControllerProvider =
    StateNotifierProvider<ReservationActionsController, AsyncValue<void>>((ref) {
  return ReservationActionsController();
});