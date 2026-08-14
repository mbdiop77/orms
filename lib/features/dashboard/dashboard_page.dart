import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/salles_temps_reel_provider.dart';
import '../../providers/current_profile_provider.dart';
import '../../models/salle_temps_reel.dart';
import '../reservation/reservation_dialog.dart';
import '../disponibilite/salles_disponibles_section.dart';
import '../historique/reservation_historique.dart';
import 'widgets/salle_card.dart';
import '../admin/admin_window.dart';
import '../admin/gestion_utilisateurs_window.dart';
import '../notifications/notifications_watcher.dart';
import '../notifications/notifications_bell.dart';

const _kFondDebut = Color(0xFF0B1120);
const _kFondFin = Color(0xFF1E293B);
const _kIndigoClair = Color(0xFFA5B4FC);
const _kTexteClair = Color(0xFFF1F5F9);

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sallesAsync = ref.watch(sallesTempsReelProvider);
    final profilAsync = ref.watch(currentProfileProvider);

    final peutReserver = profilAsync.maybeWhen(
      data: (p) => p['role'] != 'visiteur',
      orElse: () => false, // par défaut, tant qu'on ne sait pas, on masque (plus prudent)
    );

    final estAdmin = profilAsync.maybeWhen(
      data: (p) => p['role'] == 'admin',
      orElse: () => false,
    );

 return NotificationsWatcher(
     child: Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 72,
        backgroundColor: Colors.transparent,
        elevation: 5,
        automaticallyImplyLeading: false,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF111827).withValues(alpha: 0.92),
                    const Color(0xFF1E293B).withValues(alpha: 0.85),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 1.2),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.30), blurRadius: 18, offset: const Offset(0, 5)),
                ],
              ),
            ),
          ),
        ),
        titleSpacing: 18,
        title: Row(
          children: [
         //   Image.asset('assets/images/app_logo.png', height: 48),
             ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  height: 48,
                  width: 48,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "OFFICE ROOM MANAGEMENT SYSTEM",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _kTexteClair,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (estAdmin) ...[
            IconButton(
          //  tooltip: "add user",
            icon: const Icon(Icons.settings, color: _kTexteClair),
            onPressed: () => showGestionUtilisateursWindow(context),
          ),
            IconButton(
             // tooltip: "admin window",
              icon: const Icon(Icons.admin_panel_settings_outlined, color: _kTexteClair),
              onPressed: () => showAdminWindow(context),
            ),
          ],
          const NotificationsBell(),
          IconButton(
          //  tooltip: "logout",
            icon: const Icon(Icons.logout, color: _kTexteClair),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
          const SizedBox(width: 2),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_kFondDebut, _kFondFin],
          ),
        ),
        child: sallesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: _kIndigoClair)),
          error: (err, stack) => Center(
            child: Text('Erreur : $err', style: const TextStyle(color: _kTexteClair)),
          ),
          data: (salles) {
            if (salles.isEmpty) {
              return const Center(
                child: Text('Aucune salle enregistrée.', style: TextStyle(color: _kTexteClair)),
              );
            }

            final parDepartement = <String, List<SalleTempsReel>>{};
            for (final s in salles) {
              parDepartement.putIfAbsent(s.departementLabel, () => []).add(s);
            }
            final departementsTries = parDepartement.keys.toList()
              ..sort((a, b) {
                if (a.toUpperCase() == 'SUPPORT') return -1;
                if (b.toUpperCase() == 'SUPPORT') return 1;
                return a.compareTo(b);
              });

            return ListView(
              padding: const EdgeInsets.only(top: 100, bottom: 12),
              children: [
                ...departementsTries.map((nomDepartement) {
                  final sallesDepartement = parDepartement[nomDepartement]!;
                  final occupeesDept =
                      sallesDepartement.where((s) => s.statutActuel == 'occupee').length;

                  return _DepartementGroup(
                    titre: nomDepartement,
                    sousTitre: '${sallesDepartement.length} salle${sallesDepartement.length > 1 ? 's' : ''}'
                        '${occupeesDept > 0 ? ' • $occupeesDept occupée${occupeesDept > 1 ? 's' : ''}' : ''}',
                    salles: sallesDepartement,
                    peutReserver: peutReserver,
                  );
                }),
                const SizedBox(height: 8),
                const SallesDisponiblesSection(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
                ),
                const ReservationHistoriqueSection(),
              ],
            );
          },
        ),
      ),
    ),
  );
  }
}

// Enveloppe glass réutilisable pour les 3 niveaux de groupes
class _GlassContainer extends StatelessWidget {
  final Widget child;
  final double opaciteFond;

  const _GlassContainer({required this.child, this.opaciteFond = 0.35});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: opaciteFond * 0.12),
                Colors.white.withValues(alpha: opaciteFond * 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ============================================================
// Niveau 1 : Département
// ============================================================
class _DepartementGroup extends StatefulWidget {
  final String titre;
  final String sousTitre;
  final List<SalleTempsReel> salles;
  final bool peutReserver;

  const _DepartementGroup({
    required this.titre,
    required this.sousTitre,
    required this.salles,
    required this.peutReserver,
  });

  @override
  State<_DepartementGroup> createState() => _DepartementGroupState();
}

class _DepartementGroupState extends State<_DepartementGroup> {
  bool _ouvert = false;

  @override
  Widget build(BuildContext context) {
    final parEtage = <int, List<SalleTempsReel>>{};
    final labelParEtage = <int, String>{};
    for (final s in widget.salles) {
      parEtage.putIfAbsent(s.etageNumero, () => []).add(s);
      labelParEtage[s.etageNumero] = s.etageLabel;
    }
    final etagesTries = parEtage.keys.toList()..sort((a, b) => b.compareTo(a));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: _GlassContainer(
        opaciteFond: 0.45,
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _ouvert = !_ouvert),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    AnimatedRotation(
                      turns: _ouvert ? 0.125 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _kIndigoClair.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(Icons.add, size: 19, color: _kIndigoClair),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.titre,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _kTexteClair)),
                          const SizedBox(height: 2),
                          Text(widget.sousTitre, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade400)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: _ouvert
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 10, left: 8, right: 8),
                      child: Column(
                        children: etagesTries.map((numeroEtage) {
                          final sallesEtage = parEtage[numeroEtage]!;
                          final occupeesEtage = sallesEtage.where((s) => s.statutActuel == 'occupee').length;

                          return _EtageGroup(
                            titre: labelParEtage[numeroEtage]!,
                            sousTitre: '${sallesEtage.length} salle${sallesEtage.length > 1 ? 's' : ''}'
                                '${occupeesEtage > 0 ? ' • $occupeesEtage occupée${occupeesEtage > 1 ? 's' : ''}' : ''}',
                            salles: sallesEtage,
                            peutReserver: widget.peutReserver,
                          );
                        }).toList(),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Niveau 2 : Étage
// ============================================================
class _EtageGroup extends StatefulWidget {
  final String titre;
  final String sousTitre;
  final List<SalleTempsReel> salles;
  final bool peutReserver;

  const _EtageGroup({
    required this.titre,
    required this.sousTitre,
    required this.salles,
    required this.peutReserver,
  });

  @override
  State<_EtageGroup> createState() => _EtageGroupState();
}

class _EtageGroupState extends State<_EtageGroup> {
  bool _ouvert = false;

  @override
  Widget build(BuildContext context) {
    final parCompartiment = <String, List<SalleTempsReel>>{};
    for (final s in widget.salles) {
      parCompartiment.putIfAbsent(s.compartimentLabel, () => []).add(s);
    }
    final compartimentsTries = parCompartiment.keys.toList()..sort();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: _GlassContainer(
        opaciteFond: 0.25,
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _ouvert = !_ouvert),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    AnimatedRotation(
                      turns: _ouvert ? 0.125 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Icon(Icons.add, size: 16, color: _kIndigoClair),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.titre,
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _kTexteClair)),
                          const SizedBox(height: 1),
                          Text(widget.sousTitre, style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: _ouvert
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 6, right: 6),
                      child: Column(
                        children: compartimentsTries.map((nomCompartiment) {
                          final sallesCompartiment = parCompartiment[nomCompartiment]!;
                          return _CompartimentGroup(
                            titre: nomCompartiment,
                            salles: sallesCompartiment,
                            peutReserver: widget.peutReserver,
                          );
                        }).toList(),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Niveau 3 : Compartiment
// ============================================================
class _CompartimentGroup extends StatefulWidget {
  final String titre;
  final List<SalleTempsReel> salles;
  final bool peutReserver;

  const _CompartimentGroup({
    required this.titre,
    required this.salles,
    required this.peutReserver,
  });

  @override
  State<_CompartimentGroup> createState() => _CompartimentGroupState();
}

class _CompartimentGroupState extends State<_CompartimentGroup> {
  bool _ouvert = false;

  @override
  Widget build(BuildContext context) {
    final occupees = widget.salles.where((s) => s.statutActuel == 'occupee').length;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: _GlassContainer(
        opaciteFond: 0.15,
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _ouvert = !_ouvert),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    AnimatedRotation(
                      turns: _ouvert ? 0.125 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.add, size: 14, color: Colors.grey.shade300),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        widget.titre,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _kTexteClair),
                      ),
                    ),
                    Text(
                      '${widget.salles.length} salle${widget.salles.length > 1 ? 's' : ''}'
                      '${occupees > 0 ? ' • $occupees occ.' : ''}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: _ouvert
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Column(
                        children: widget.salles
                            .map((s) => SalleCard(
                                  salle: s,
                                  onReserver: () => showReservationDialog(context, s),
                                  peutReserver: widget.peutReserver,
                                ))
                            .toList(),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}