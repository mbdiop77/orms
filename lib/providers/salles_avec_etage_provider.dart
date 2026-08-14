/*
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'salles_temps_reel_provider.dart';
import 'etages_provider.dart';
import '../models/salle_temps_reel.dart';

class SalleAffichage {
  final SalleTempsReel salle;
  final String etageLabel;

  SalleAffichage({required this.salle, required this.etageLabel});
}

final sallesAvecEtageProvider = Provider<AsyncValue<List<SalleAffichage>>>((ref) {
  final sallesAsync = ref.watch(sallesTempsReelProvider);
  final etagesAsync = ref.watch(etagesProvider);

  if (sallesAsync.isLoading || etagesAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (sallesAsync.hasError) {
    return AsyncValue.error(sallesAsync.error!, sallesAsync.stackTrace!);
  }
  if (etagesAsync.hasError) {
    return AsyncValue.error(etagesAsync.error!, etagesAsync.stackTrace!);
  }

  final etagesById = {for (final e in etagesAsync.value!) e.id: e};

  final result = sallesAsync.value!.map((salle) {
    final etage = etagesById[salle.etageId];
    final label = etage == null
        ? 'Étage ?'
        : (etage.nom?.isNotEmpty == true ? etage.nom! : 'Étage ${etage.numero}');
    return SalleAffichage(salle: salle, etageLabel: label);
  }).toList();

  return AsyncValue.data(result);
});
*/