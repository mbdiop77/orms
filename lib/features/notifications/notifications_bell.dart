import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/app_notification.dart';
import '../../providers/notifications_controller.dart';

const _kFondFin = Color(0xFF1E293B);
const _kIndigoClair = Color(0xFFA5B4FC);
const _kTexteClair = Color(0xFFF1F5F9);
const _kOrange = Color(0xFFFBBF24);
const _kRouge = Color(0xFFF87171);

class NotificationsBell extends ConsumerWidget {
  const NotificationsBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsControllerProvider);
    final nonLues = notifications.where((n) => !n.lue).length;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
        //  tooltip: 'Notifications',
          icon: const Icon(Icons.notifications_none_rounded, color: _kTexteClair),
          onPressed: () => _ouvrirPanneau(context, ref),
        ),
        if (nonLues > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: _kRouge, borderRadius: BorderRadius.circular(20)),
              constraints: const BoxConstraints(minWidth: 16),
              child: Text(
                nonLues > 9 ? '9+' : '$nonLues',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }

  void _ouvrirPanneau(BuildContext context, WidgetRef ref) {
    ref.read(notificationsControllerProvider.notifier).marquerToutesLues();

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 70, right: 16),
          child: _PanneauNotifications(),
        ),
      ),
    );
  }
}

class _PanneauNotifications extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsControllerProvider);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 340,
        constraints: const BoxConstraints(maxHeight: 420),
        decoration: BoxDecoration(
          color: _kFondFin,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
              child: Row(
                children: [
                  const Icon(Icons.notifications_rounded, size: 17, color: _kIndigoClair),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Notifications', style: TextStyle(color: _kTexteClair, fontSize: 14, fontWeight: FontWeight.w800)),
                  ),
                  if (notifications.isNotEmpty)
                    TextButton(
                      onPressed: () => ref.read(notificationsControllerProvider.notifier).toutEffacer(),
                      child: Text('Effacer', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                    ),
                ],
              ),
            ),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
            Flexible(
              child: notifications.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Aucune notification pour le moment.',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5)),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) => _LigneNotification(notification: notifications[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LigneNotification extends StatelessWidget {
  final AppNotification notification;

  const _LigneNotification({required this.notification});

  (IconData, Color) get _style {
    switch (notification.type) {
      case TypeNotification.bientot:
        return (Icons.schedule_rounded, _kOrange);
      case TypeNotification.decalage:
        return (Icons.update_rounded, _kOrange);
      case TypeNotification.annulation:
        return (Icons.event_busy_rounded, _kRouge);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icone, couleur) = _style;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: couleur.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(9)),
            child: Icon(icone, size: 14, color: couleur),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.message, style: const TextStyle(color: _kTexteClair, fontSize: 12.5, height: 1.3)),
                const SizedBox(height: 3),
                Text(
                  DateFormat.Hm('fr_FR').format(notification.horodatage),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}