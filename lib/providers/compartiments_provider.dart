import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../models/compartiment.dart';

final compartimentsProvider = StreamProvider<List<Compartiment>>((ref) {
  final controller = StreamController<List<Compartiment>>();

  Future<void> fetchAndEmit() async {
    try {
      final data = await supabase.from('compartiments').select().order('nom');
      final liste = (data as List).map((e) => Compartiment.fromMap(e as Map<String, dynamic>)).toList();
      if (!controller.isClosed) controller.add(liste);
    } catch (e, st) {
      if (!controller.isClosed) controller.addError(e, st);
    }
  }

  fetchAndEmit();

  final channel = supabase.channel('compartiments_admin_changes')
    ..onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'compartiments',
      callback: (payload) => fetchAndEmit(),
    )
    ..subscribe();

  ref.onDispose(() {
    supabase.removeChannel(channel);
    controller.close();
  });

  return controller.stream;
});