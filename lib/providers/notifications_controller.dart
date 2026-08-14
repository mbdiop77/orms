import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_notification.dart';

class NotificationsController extends StateNotifier<List<AppNotification>> {
  NotificationsController() : super([]);

  void ajouter(AppNotification notification) {
    state = [notification, ...state].take(30).toList();
  }

  void marquerToutesLues() {
    state = state.map((n) => n.copierAvec(lue: true)).toList();
  }

  void toutEffacer() {
    state = [];
  }

  int get nonLues => state.where((n) => !n.lue).length;
}

final notificationsControllerProvider =
    StateNotifierProvider<NotificationsController, List<AppNotification>>((ref) {
  return NotificationsController();
});