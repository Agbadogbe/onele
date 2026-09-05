class AppNotification {
  final int id;
  final int? demandeId;
  final String message;
  final bool lue;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.demandeId,
    required this.message,
    required this.lue,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      demandeId: json['demande_id'] as int?,
      message: json['message'] as String,
      lue: json['lue'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
