class NotificationModel {
  final String id;
  final String title;
  final String subtitle;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final String? referenceId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.referenceId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      subtitle: json['subtitle'],
      type: json['type'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      referenceId: json['reference_id'],
    );
  }
}