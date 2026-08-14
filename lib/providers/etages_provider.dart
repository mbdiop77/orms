import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase_client.dart';
import '../models/etage.dart';

final etagesProvider = FutureProvider<List<Etage>>((ref) async {
  final data = await supabase.from('etages').select();
  return (data as List).map((e) => Etage.fromMap(e as Map<String, dynamic>)).toList();
});