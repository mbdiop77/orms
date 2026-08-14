import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../models/reservation_historique.dart';
import 'current_profile_provider.dart';

final historiqueReservationsProvider = StreamProvider<List<ReservationHistorique>>((ref) {
  final controller = StreamController<List<ReservationHistorique>>();

  Future<void> fetchAndEmit() async {
    try {
      final profil = await ref.read(currentProfileProvider.future);
      final estAdmin = profil['role'] == 'admin';
      final userId = supabase.auth.currentUser!.id;

      final base = supabase.from('vue_historique_reservations').select();
      final data = estAdmin
          ? await base.order('date_debut', ascending: false)
          : await base.eq('formateur_id', userId).order('date_debut', ascending: false);

      final liste = (data as List)
          .map((e) => ReservationHistorique.fromMap(e as Map<String, dynamic>))
          .toList();
      if (!controller.isClosed) controller.add(liste);
    } catch (e, st) {
      if (!controller.isClosed) controller.addError(e, st);
    }
  }

  // Chargement initial
  fetchAndEmit();

  // Écoute Realtime : rafraîchit immédiatement à chaque écriture en base
  final channel = supabase.channel('historique_reservations_changes')
    ..onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'reservations',
      callback: (payload) => fetchAndEmit(),
    )
    ..subscribe();

  // Rafraîchissement périodique : couvre le passage automatique
  // "en cours" -> "terminée" lié au simple écoulement du temps,
  // qui ne déclenche aucun événement Realtime.
  final minuteur = Timer.periodic(const Duration(seconds: 30), (_) => fetchAndEmit());

  ref.onDispose(() {
    supabase.removeChannel(channel);
    minuteur.cancel();
    controller.close();
  });

  return controller.stream;
});