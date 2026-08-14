enum TypeNotification { bientot, decalage, annulation }

class AppNotification {
  final String id;
  final TypeNotification type;
  final String message;
  final DateTime horodatage;
  final bool lue;

  AppNotification({
    required this.id,
    required this.type,
    required this.message,
    required this.horodatage,
    this.lue = false,
  });

  AppNotification copierAvec({bool? lue}) {
    return AppNotification(
      id: id,
      type: type,
      message: message,
      horodatage: horodatage,
      lue: lue ?? this.lue,
    );
  }
}