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

  NotificationModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? type,
    bool? isRead,
    DateTime? createdAt,
    String? referenceId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      referenceId: referenceId ?? this.referenceId,
    );
  }
}