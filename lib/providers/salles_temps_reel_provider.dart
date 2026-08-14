import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../models/salle_temps_reel.dart';

final sallesTempsReelProvider = StreamProvider<List<SalleTempsReel>>((ref) {
  final controller = StreamController<List<SalleTempsReel>>();

  Future<void> fetchAndEmit() async {
    try {
      final data = await supabase.from('vue_salles_temps_reel').select();
      final salles = (data as List)
          .map((e) => SalleTempsReel.fromMap(e as Map<String, dynamic>))
          .toList();
      if (!controller.isClosed) controller.add(salles);
    } catch (e, st) {
      if (!controller.isClosed) controller.addError(e, st);
    }
  }

  // Chargement initial
  fetchAndEmit();

  // Écoute Realtime : rafraîchit immédiatement à chaque écriture en base
  final channel = supabase.channel('salles_temps_reel_changes')
    ..onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'reservations',
      callback: (payload) => fetchAndEmit(),
    )
    ..onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'salles',
      callback: (payload) => fetchAndEmit(),
    )
    ..subscribe();

  // Rafraîchissement périodique : couvre les changements de statut liés au
  // simple écoulement du temps (ex: une réservation qui se termine),
  // qui ne déclenchent aucun événement Realtime puisqu'aucune écriture n'a lieu.
  final minuteur = Timer.periodic(const Duration(seconds: 30), (_) => fetchAndEmit());

  ref.onDispose(() {
    supabase.removeChannel(channel);
    minuteur.cancel();
    controller.close();
  });

  return controller.stream;
});