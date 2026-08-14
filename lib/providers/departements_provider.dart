import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase_client.dart';
import '../models/departement.dart';

final departementsProvider = FutureProvider<List<Departement>>((ref) async {
  final data = await supabase.from('departements').select().order('nom');
  return (data as List).map((e) => Departement.fromMap(e as Map<String, dynamic>)).toList();
});