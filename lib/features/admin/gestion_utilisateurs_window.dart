import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/profil_admin.dart';
import '../../providers/profiles_admin_provider.dart';
import '../../providers/admin_crud_controller.dart';

const _kFondDebut = Color(0xFF0F172A);
const _kFondFin = Color(0xFF1E293B);
const _kIndigo = Color(0xFF4F46E5);
const _kIndigoClair = Color(0xFFA5B4FC);
const _kTexteClair = Color(0xFFF1F5F9);
const _kRouge = Color(0xFFF87171);
const _kVert = Color(0xFF4ADE80);
const _kOr = Color(0xFFFBBF24);
const _kGris = Color(0xFF94A3B8);

const _rolesDisponibles = ['admin', 'utilisateur', 'visiteur'];

Future<void> showGestionUtilisateursWindow(BuildContext context) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => const _GestionUtilisateursWindow(),
  );
}

class _GestionUtilisateursWindow extends ConsumerStatefulWidget {
  const _GestionUtilisateursWindow();

  @override
  ConsumerState<_GestionUtilisateursWindow> createState() => _GestionUtilisateursWindowState();
}

class _GestionUtilisateursWindowState extends ConsumerState<_GestionUtilisateursWindow> {
  final _rechercheCtrl = TextEditingController();
  String _recherche = '';

  @override
  void dispose() {
    _rechercheCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taille = MediaQuery.of(context).size;
    final profilsAsync = ref.watch(profilesAdminProvider);

    ref.listen(adminCrudControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (err, st) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.toString()), backgroundColor: _kRouge, behavior: SnackBarBehavior.floating),
        ),
      );
    });

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 1000, maxHeight: taille.height * 0.88),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
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
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [_kIndigo, Color(0xFF6366F1)]),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Gestion des utilisateurs',
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 08, 20, 0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: TextField(
                          controller: _rechercheCtrl,
                          onChanged: (v) => setState(() => _recherche = v.trim().toLowerCase()),
                          style: const TextStyle(color: _kTexteClair, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Rechercher par nom ou email…',
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
                            suffixIcon: _recherche.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.close_rounded, color: Colors.grey.shade400, size: 18),
                                    onPressed: () => setState(() {
                                      _rechercheCtrl.clear();
                                      _recherche = '';
                                    }),
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.05),
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: _kIndigoClair, width: 1.4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: profilsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator(color: _kIndigoClair)),
                      error: (err, st) => Center(
                        child: Text('Erreur : $err', style: const TextStyle(color: _kTexteClair)),
                      ),
                      data: (profilsBruts) {
                        final profils = _recherche.isEmpty
                            ? profilsBruts
                            : profilsBruts
                                .where((p) =>
                                    p.nom.toLowerCase().contains(_recherche) ||
                                    p.email.toLowerCase().contains(_recherche))
                                .toList();

                        final admins = profils.where((p) => p.role == 'admin').toList();
                        final invites = profils.where((p) => p.role == 'visiteur').toList();
                        final utilisateurs =
                            profils.where((p) => p.role != 'admin' && p.role != 'visiteur').toList();

                        if (profils.isEmpty) {
                          return Center(
                            child: Text(
                              'Aucun utilisateur ne correspond à la recherche.',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          );
                        }

                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _GroupeRole(titre: 'Admin', couleur: _kOr, profils: admins),
                              const SizedBox(height: 26),
                              _GroupeRole(titre: 'Utilisateur', couleur: _kVert, profils: utilisateurs),
                              const SizedBox(height: 26),
                              _GroupeRole(titre: 'Visiteur', couleur: _kGris, profils: invites),
                            ],
                          ),
                        );
                      },
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
// Un groupe (Admin / Utilisateur / Invité), avec ligne remarquable
// ============================================================
class _GroupeRole extends StatelessWidget {
  final String titre;
  final Color couleur;
  final List<ProfilAdmin> profils;

  const _GroupeRole({required this.titre, required this.couleur, required this.profils});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: couleur.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(9)),
              child: Icon(_iconePourTitre(titre), size: 16, color: couleur),
            ),
            const SizedBox(width: 10),
            Text(titre, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: couleur)),
            const SizedBox(width: 8),
            Text('(${profils.length})', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 2,
          decoration: BoxDecoration(color: couleur.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 14),
        if (profils.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('Aucun utilisateur dans ce groupe.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final colonnes = constraints.maxWidth > 760 ? 3 : (constraints.maxWidth > 480 ? 2 : 1);
              const espace = 10.0;
              final largeurCarte = (constraints.maxWidth - (espace * (colonnes - 1))) / colonnes;

              return Wrap(
                spacing: espace,
                runSpacing: espace,
                children: profils
                    .map((p) => SizedBox(
                          width: largeurCarte,
                          child: _CarteUtilisateur(profil: p, couleurGroupe: couleur),
                        ))
                    .toList(),
              );
            },
          ),
      ],
    );
  }

  IconData _iconePourTitre(String titre) {
    switch (titre) {
      case 'Admin':
        return Icons.shield_rounded;
      case 'Visiteur':
        return Icons.visibility_outlined;
      default:
        return Icons.person_rounded;
    }
  }
}

// ============================================================
// Carte individuelle d'utilisateur, cliquable pour changer le rôle
// ============================================================
class _CarteUtilisateur extends ConsumerWidget {
  final ProfilAdmin profil;
  final Color couleurGroupe;

  const _CarteUtilisateur({required this.profil, required this.couleurGroupe});

  IconData get _icone {
    switch (profil.role) {
      case 'admin':
        return Icons.shield_rounded;
      case 'visiteur':
        return Icons.visibility_outlined;
      case 'responsable_departement':
        return Icons.badge_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  Future<void> _ouvrirMenuRoles(BuildContext context, WidgetRef ref, Offset positionGlobale) async {
    final nouveauRole = await showMenu<String>(
      context: context,
      color: _kFondFin,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      position: RelativeRect.fromLTRB(positionGlobale.dx, positionGlobale.dy, positionGlobale.dx, positionGlobale.dy),
      items: _rolesDisponibles
          .map((r) => PopupMenuItem<String>(
                value: r,
                child: Row(
                  children: [
                    if (r == profil.role) const Icon(Icons.check, size: 16, color: _kIndigoClair),
                    if (r == profil.role) const SizedBox(width: 6),
                    Text(r, style: TextStyle(color: r == profil.role ? _kIndigoClair : _kTexteClair)),
                  ],
                ),
              ))
          .toList(),
    );

    if (nouveauRole != null && nouveauRole != profil.role) {
      ref.read(adminCrudControllerProvider.notifier).modifierRoleUtilisateur(
            id: profil.id,
            nouveauRole: nouveauRole,
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTapDown: (details) => _ouvrirMenuRoles(context, ref, details.globalPosition),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white.withValues(alpha: 0.05), Colors.white.withValues(alpha: 0.02)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: couleurGroupe.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(9)),
              child: Icon(_icone, size: 16, color: couleurGroupe),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profil.nom,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kTexteClair),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    profil.email,
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade400),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.expand_more_rounded, size: 16, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }
}