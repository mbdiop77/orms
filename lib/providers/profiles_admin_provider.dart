import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../models/profil_admin.dart';

final profilesAdminProvider = StreamProvider<List<ProfilAdmin>>((ref) {
  final controller = StreamController<List<ProfilAdmin>>();

  Future<void> fetchAndEmit() async {
    try {
      final data = await supabase.from('profiles').select().order('nom');
      final liste = (data as List).map((e) => ProfilAdmin.fromMap(e as Map<String, dynamic>)).toList();
      if (!controller.isClosed) controller.add(liste);
    } catch (e, st) {
      if (!controller.isClosed) controller.addError(e, st);
    }
  }

  fetchAndEmit();

  final channel = supabase.channel('profiles_admin_changes')
    ..onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'profiles',
      callback: (payload) => fetchAndEmit(),
    )
    ..subscribe();

  ref.onDispose(() {
    supabase.removeChannel(channel);
    controller.close();
  });

  return controller.stream;
});