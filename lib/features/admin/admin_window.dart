import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/compartiment.dart';
import '../../models/salle_admin.dart';
import '../../models/etage.dart';
import '../../providers/compartiments_provider.dart';
import '../../providers/salles_admin_provider.dart';
import '../../providers/etages_provider.dart';
import '../../providers/admin_crud_controller.dart';
import '../../providers/departements_provider.dart';
const _kFondDebut = Color(0xFF0F172A);
const _kFondFin = Color(0xFF1E293B);
const _kIndigo = Color(0xFF4F46E5);
const _kIndigoClair = Color(0xFFA5B4FC);
const _kTexteClair = Color(0xFFF1F5F9);
const _kRouge = Color(0xFFF87171);
const _kVert = Color(0xFF4ADE80);

Future<void> showAdminWindow(BuildContext context) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => const _AdminWindow(),
  );
}

class _AdminWindow extends StatelessWidget {
  const _AdminWindow();

  @override
  Widget build(BuildContext context) {
    final taille = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 980,
          maxHeight: taille.height * 1.00,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_kFondDebut, _kFondFin],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(22, 18, 16, 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_kIndigo, Color(0xFF6366F1)]),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Gestion des salles & compartiments',
                            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionSalles(),
                          SizedBox(height: 28),
                          _SectionCompartiments(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// En-tête de section réutilisable
// ============================================================
class _EnteteSection extends StatelessWidget {
  final IconData icone;
  final String titre;
  final Color couleur;

  const _EnteteSection({required this.icone, required this.titre, required this.couleur});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: couleur.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(10)),
          child: Icon(icone, size: 17, color: couleur),
        ),
        const SizedBox(width: 10),
        Text(titre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _kTexteClair)),
      ],
    );
  }
}

// ============================================================
// SECTION SALLES
// ============================================================
class _SectionSalles extends ConsumerStatefulWidget {
  const _SectionSalles();

  @override
  ConsumerState<_SectionSalles> createState() => _SectionSallesState();
}

class _SectionSallesState extends ConsumerState<_SectionSalles> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _capaciteCtrl = TextEditingController(text: '0');

  String? _compartimentId;
  String? _departementId;
  String _statut = 'libre';
  bool _actif = true;
  String? _idEnEdition;

static const _statuts = ['libre', 'maintenance'];
  @override
  void dispose() {
    _nomCtrl.dispose();
    _codeCtrl.dispose();
    _capaciteCtrl.dispose();
    super.dispose();
  }

  void _reinitialiser() {
    setState(() {
      _idEnEdition = null;
      _nomCtrl.clear();
      _codeCtrl.clear();
      _capaciteCtrl.text = '0';
      _compartimentId = null;
      _departementId = null;
      _statut = 'libre';
      _actif = true;
    });
  }

  void _chargerPourEdition(SalleAdmin s) {
    setState(() {
      _idEnEdition = s.id;
      _nomCtrl.text = s.nom;
      _codeCtrl.text = s.code ?? '';
      _capaciteCtrl.text = s.capacite.toString();
      _compartimentId = s.compartimentId;
      _departementId = s.departementId;
      _statut = s.statut;
      _actif = s.actif;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _formKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), curve: Curves.easeOut, alignment: 0.05);
      }
    });
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_compartimentId == null) {
      _erreur('Choisis un compartiment');
      return;
    }

    final controller = ref.read(adminCrudControllerProvider.notifier);
    final capacite = int.tryParse(_capaciteCtrl.text.trim()) ?? 0;

    final succes = _idEnEdition == null
        ? await controller.creerSalle(
            nom: _nomCtrl.text.trim(),
            code: _codeCtrl.text.trim(),
            compartimentId: _compartimentId!,
            departementId: _departementId,
            capacite: capacite,
            statut: _statut,
            actif: _actif,
          )
        : await controller.modifierSalle(
            id: _idEnEdition!,
            nom: _nomCtrl.text.trim(),
            code: _codeCtrl.text.trim(),
            compartimentId: _compartimentId!,
            departementId: _departementId,
            capacite: capacite,
            statut: _statut,
            actif: _actif,
          );

    if (succes) _reinitialiser();
  }

  void _confirmerSuppression(SalleAdmin s) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kFondFin,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer cette salle ?', style: TextStyle(color: _kTexteClair)),
        content: Text('${s.nom} sera définitivement supprimée.', style: TextStyle(color: Colors.grey.shade300)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Retour')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _kRouge),
            onPressed: () {
              Navigator.pop(context);
              ref.read(adminCrudControllerProvider.notifier).supprimerSalle(s.id);
              if (_idEnEdition == s.id) _reinitialiser();
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _erreur(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: _kRouge, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compartimentsAsync = ref.watch(compartimentsProvider);
    final departementsAsync = ref.watch(departementsProvider);
    final sallesAsync = ref.watch(sallesAdminProvider);
    final etagesAsync = ref.watch(etagesProvider);
    final actionState = ref.watch(adminCrudControllerProvider);

    ref.listen(adminCrudControllerProvider, (previous, next) {
      next.whenOrNull(error: (err, st) => _erreur(err.toString()));
    });

    return _CarteSection(
      couleur: _kIndigoClair,
      entete: const _EnteteSection(icone: Icons.meeting_room_rounded, titre: 'Salles', couleur: _kIndigoClair),
      formulaire: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _ChampTexte(
                    controller: _nomCtrl,
                    label: 'Nom de la salle',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: _ChampTexte(controller: _codeCtrl, label: 'Code (optionnel)')),
                const SizedBox(width: 10),
                Expanded(
                  child: _ChampTexte(
                    controller: _capaciteCtrl,
                    label: 'Capacité',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: compartimentsAsync.when(
                    loading: () => const _ChargementMini(),
                    error: (e, s) => Text('Erreur', style: TextStyle(color: _kRouge)),
                    data: (compartiments) {
                      final etagesParId = etagesAsync.maybeWhen(
                        data: (etages) => {for (final e in etages) e.id: e},
                        orElse: () => <String, Etage>{},
                      );
                      return _ChampDropdown<String>(
                        label: 'Compartiment',
                        valeur: _compartimentId,
                        items: compartiments
                            .map((c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(
                                    '${c.nom}${etagesParId[c.etageId] != null ? " • Niveau ${etagesParId[c.etageId]!.numero}" : ""}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _compartimentId = v),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
            Expanded(
              child: departementsAsync.when(
                loading: () => const _ChargementMini(),
                error: (e, s) => Text('Erreur : $e', style: TextStyle(color: _kRouge, fontSize: 11)),
                data: (departements) {
                  final supportId = departements
                      .where((d) => d.nom.toUpperCase() == 'SUPPORT')
                      .map((d) => d.id)
                      .firstOrNull;

                  if (_departementId == null && _idEnEdition == null && supportId != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _departementId = supportId);
                    });
                  }

                  return _ChampDropdown<String?>(
                    label: 'Département',
                    valeur: _departementId,
                    items: [
                    //  const DropdownMenuItem<String?>(value: null, child: Text('Aucun')),
                      ...departements.map(
                        (d) => DropdownMenuItem<String?>(value: d.id, child: Text(d.nom)),
                      ),
                    ],
                    onChanged: (v) => setState(() => _departementId = v),
                  );
                },
              ),
            ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ChampDropdown<String>(
                    label: 'Statut',
                    valeur: _statut,
                    items: _statuts.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _statut = v ?? 'libre'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Switch(
                  value: _actif,
                  activeThumbColor: _kIndigoClair,
                  onChanged: (v) => setState(() => _actif = v),
                ),
                Text('Salle active', style: TextStyle(color: Colors.grey.shade300, fontSize: 13)),
                const Spacer(),
                if (_idEnEdition != null)
                  TextButton(
                    onPressed: _reinitialiser,
                    child: Text('Annuler modif.', style: TextStyle(color: Colors.grey.shade400)),
                  ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _kIndigo, foregroundColor: Colors.white),
                  onPressed: actionState.isLoading ? null : _enregistrer,
                  child: Text(_idEnEdition == null ? 'Ajouter' : 'Enregistrer'),
                ),
              ],
            ),
          ],
        ),
      ),
      liste: sallesAsync.when(
        loading: () => const _ChargementMini(),
        error: (e, s) => Text('Erreur : $e', style: TextStyle(color: _kRouge)),
        data: (salles) {
          if (salles.isEmpty) {
            return Text('Aucune salle enregistrée.', style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5));
          }
          return Column(
            children: salles
                .map((s) => _LigneListe(
                      titre: s.nom,
                     sousTitre: '${s.capacite > 0 ? "${s.capacite} places  •  " : ""}${s.statut}'
                      '${!s.actif ? "  •  inactive" : ""}',
                      enEdition: _idEnEdition == s.id,
                      onModifier: () => _chargerPourEdition(s),
                      onSupprimer: () => _confirmerSuppression(s),
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}

// ============================================================
// SECTION COMPARTIMENTS
// ============================================================
class _SectionCompartiments extends ConsumerStatefulWidget {
  const _SectionCompartiments();

  @override
  ConsumerState<_SectionCompartiments> createState() => _SectionCompartimentsState();
}

class _SectionCompartimentsState extends ConsumerState<_SectionCompartiments> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  String? _etageId;
  String? _idEnEdition;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _reinitialiser() {
    setState(() {
      _idEnEdition = null;
      _nomCtrl.clear();
      _codeCtrl.clear();
      _etageId = null;
    });
  }

  void _chargerPourEdition(Compartiment c) {
    setState(() {
      _idEnEdition = c.id;
      _nomCtrl.text = c.nom;
      _codeCtrl.text = c.code ?? '';
      _etageId = c.etageId;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _formKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          alignment: 0.05,
        );
      }
    });
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_etageId == null) {
      _erreur('Choisis un étage');
      return;
    }

    final controller = ref.read(adminCrudControllerProvider.notifier);

    final succes = _idEnEdition == null
        ? await controller.creerCompartiment(etageId: _etageId!, nom: _nomCtrl.text.trim(), code: _codeCtrl.text.trim())
        : await controller.modifierCompartiment(
            id: _idEnEdition!,
            etageId: _etageId!,
            nom: _nomCtrl.text.trim(),
            code: _codeCtrl.text.trim(),
          );

    if (succes) _reinitialiser();
  }

  void _confirmerSuppression(Compartiment c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kFondFin,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer ce compartiment ?', style: TextStyle(color: _kTexteClair)),
        content: Text(
          '${c.nom} sera supprimé. Impossible si des salles y sont encore rattachées.',
          style: TextStyle(color: Colors.grey.shade300),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Retour')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _kRouge),
            onPressed: () {
              Navigator.pop(context);
              ref.read(adminCrudControllerProvider.notifier).supprimerCompartiment(c.id);
              if (_idEnEdition == c.id) _reinitialiser();
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _erreur(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: _kRouge, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final etagesAsync = ref.watch(etagesProvider);
    final compartimentsAsync = ref.watch(compartimentsProvider);
    final actionState = ref.watch(adminCrudControllerProvider);

    ref.listen(adminCrudControllerProvider, (previous, next) {
      next.whenOrNull(error: (err, st) => _erreur(err.toString()));
    });

    return _CarteSection(
      couleur: _kVert,
      entete: const _EnteteSection(icone: Icons.layers_rounded, titre: 'Compartiments', couleur: _kVert),
      formulaire: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _ChampTexte(
                    controller: _nomCtrl,
                    label: 'Nom du compartiment',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: _ChampTexte(controller: _codeCtrl, label: 'Code (optionnel)')),
                const SizedBox(width: 10),
                Expanded(
                  child: etagesAsync.when(
                    loading: () => const _ChargementMini(),
                    error: (e, s) => Text('Erreur', style: TextStyle(color: _kRouge)),
                    data: (etages) => _ChampDropdown<String>(
                      label: 'Étage',
                      valeur: _etageId,
                      items: etages
                          .map((e) => DropdownMenuItem(
                                value: e.id,
                                child: Text(e.nom?.isNotEmpty == true ? e.nom! : 'Niveau ${e.numero}'),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _etageId = v),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (_idEnEdition != null)
                  TextButton(
                    onPressed: _reinitialiser,
                    child: Text('Annuler modif.', style: TextStyle(color: Colors.grey.shade400)),
                  ),
                const Spacer(),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _kVert, foregroundColor: _kFondDebut),
                  onPressed: actionState.isLoading ? null : _enregistrer,
                  child: Text(_idEnEdition == null ? 'Ajouter' : 'Enregistrer'),
                ),
              ],
            ),
          ],
        ),
      ),
      liste: compartimentsAsync.when(
        loading: () => const _ChargementMini(),
        error: (e, s) => Text('Erreur : $e', style: TextStyle(color: _kRouge)),
        data: (compartiments) {
          if (compartiments.isEmpty) {
            return Text('Aucun compartiment enregistré.', style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5));
          }
          final etagesParId = etagesAsync.maybeWhen(
            data: (etages) => {for (final e in etages) e.id: e},
            orElse: () => <String, Etage>{},
          );
          return Column(
            children: compartiments
                .map((c) => _LigneListe(
                      titre: c.nom,
                      sousTitre: '${c.code ?? "—"}  •  '
                          '${etagesParId[c.etageId] != null ? "Niveau ${etagesParId[c.etageId]!.numero}" : "Étage inconnu"}',
                      enEdition: _idEnEdition == c.id,
                      onModifier: () => _chargerPourEdition(c),
                      onSupprimer: () => _confirmerSuppression(c),
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}

// ============================================================
// Widgets communs
// ============================================================
class _CarteSection extends StatelessWidget {
  final Widget entete;
  final Widget formulaire;
  final Widget liste;
  final Color couleur;

  const _CarteSection({
    required this.entete,
    required this.formulaire,
    required this.liste,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withValues(alpha: 0.05), Colors.white.withValues(alpha: 0.02)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: couleur.withValues(alpha: 0.25)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          entete,
          const SizedBox(height: 14),
          formulaire,
          const SizedBox(height: 18),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 12),
          Text('Liste', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          liste,
        ],
      ),
    );
  }
}

class _LigneListe extends StatelessWidget {
  final String titre;
  final String sousTitre;
  final bool enEdition;
  final VoidCallback onModifier;
  final VoidCallback onSupprimer;

  const _LigneListe({
    required this.titre,
    required this.sousTitre,
    required this.enEdition,
    required this.onModifier,
    required this.onSupprimer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: enEdition ? _kIndigoClair.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: enEdition ? _kIndigoClair.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kTexteClair)),
                Text(sousTitre, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade400)),
              ],
            ),
          ),
          _MiniBouton(icone: Icons.edit_rounded, couleur: _kIndigoClair, onTap: onModifier),
          const SizedBox(width: 6),
          _MiniBouton(icone: Icons.delete_outline_rounded, couleur: _kRouge, onTap: onSupprimer),
        ],
      ),
    );
  }
}

class _MiniBouton extends StatelessWidget {
  final IconData icone;
  final Color couleur;
  final VoidCallback onTap;

  const _MiniBouton({required this.icone, required this.couleur, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: couleur.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
        child: Icon(icone, size: 15, color: couleur),
      ),
    );
  }
}

class _ChampTexte extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _ChampTexte({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: _kTexteClair, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12.5),
        isDense: true,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kIndigoClair, width: 1.3),
        ),
      ),
    );
  }
}

class _ChampDropdown<T> extends StatelessWidget {
  final String label;
  final T? valeur;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _ChampDropdown({
    required this.label,
    required this.valeur,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: valeur,
      isExpanded: true,
      dropdownColor: _kFondFin,
      style: const TextStyle(color: _kTexteClair, fontSize: 13),
      icon: Icon(Icons.expand_more_rounded, color: Colors.grey.shade500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12.5),
        isDense: true,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kIndigoClair, width: 1.3),
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}

class _ChargementMini extends StatelessWidget {
  const _ChargementMini();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Center(child: CircularProgressIndicator(color: _kIndigoClair, strokeWidth: 2)),
    );
  }
}