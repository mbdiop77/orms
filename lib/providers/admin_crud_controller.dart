import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';

class AdminCrudController extends StateNotifier<AsyncValue<void>> {
  AdminCrudController() : super(const AsyncValue.data(null));

  Future<bool> creerCompartiment({required String etageId, required String nom, String? code}) =>
      _executer(() => supabase.from('compartiments').insert({
            'etage_id': etageId,
            'nom': nom,
            if (code != null && code.isNotEmpty) 'code': code,
          }));

  Future<bool> modifierCompartiment({
    required String id,
    required String etageId,
    required String nom,
    String? code,
  }) =>
      _executer(() => supabase.from('compartiments').update({
            'etage_id': etageId,
            'nom': nom,
            'code': (code != null && code.isNotEmpty) ? code : null,
          }).eq('id', id));

  Future<bool> supprimerCompartiment(String id) =>
      _executer(() => supabase.from('compartiments').delete().eq('id', id));

  Future<bool> creerSalle({
    required String nom,
    String? code,
    required String compartimentId,
    String? departementId,
    required int capacite,
    required String statut,
    required bool actif,
  }) =>
      _executer(() => supabase.from('salles').insert({
            'nom': nom,
            if (code != null && code.isNotEmpty) 'code': code,
            'compartiment_id': compartimentId,
            'departement_id': departementId,
            'capacite': capacite,
            'statut': statut,
            'actif': actif,
          }));

  Future<bool> modifierSalle({
    required String id,
    required String nom,
    String? code,
    required String compartimentId,
    String? departementId,
    required int capacite,
    required String statut,
    required bool actif,
  }) =>
      _executer(() => supabase.from('salles').update({
            'nom': nom,
            'code': (code != null && code.isNotEmpty) ? code : null,
            'compartiment_id': compartimentId,
            'departement_id': departementId,
            'capacite': capacite,
            'statut': statut,
            'actif': actif,
          }).eq('id', id));

  Future<bool> supprimerSalle(String id) =>
      _executer(() => supabase.from('salles').delete().eq('id', id));
  
  Future<bool> modifierRoleUtilisateur({required String id, required String nouveauRole}) =>
    _executer(() => supabase.from('profiles').update({'role': nouveauRole}).eq('id', id));

  Future<bool> _executer(Future<dynamic> Function() action) async {
    state = const AsyncValue.loading();
    try {
      await action();
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
}

final adminCrudControllerProvider = StateNotifierProvider<AdminCrudController, AsyncValue<void>>((ref) {
  return AdminCrudController();
});