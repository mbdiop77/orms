import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase_client.dart';

final currentProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final userId = supabase.auth.currentUser!.id;
  final data = await supabase.from('profiles').select().eq('id', userId).maybeSingle();
  return data ?? <String, dynamic>{};
});