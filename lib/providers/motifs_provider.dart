import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase_client.dart';
import '../models/motif.dart';

final motifsProvider = FutureProvider<List<Motif>>((ref) async {
  final data = await supabase.from('motifs').select();
  return (data as List).map((e) => Motif.fromMap(e as Map<String, dynamic>)).toList();
});