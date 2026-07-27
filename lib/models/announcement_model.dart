class AnnouncementModel {
  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.actionType,
    required this.priority,
    required this.isActive,
    required this.language,
    this.imageUrl,
    this.buttonText,
    this.actionValue,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) =>
      AnnouncementModel(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        imageUrl: json['image_url'] as String?,
        buttonText: json['button_text'] as String?,
        actionType: json['action_type'] as String? ?? 'none',
        actionValue: json['action_value'] as String?,
        category: json['category'] as String? ?? 'general',
        priority: (json['priority'] as num?)?.toInt() ?? 0,
        isActive: json['is_active'] as bool? ?? true,
        language: json['language'] as String? ?? 'en',
        startDate: _dateFromJson(json['start_date']),
        endDate: _dateFromJson(json['end_date']),
        createdAt: _dateFromJson(json['created_at']),
        updatedAt: _dateFromJson(json['updated_at']),
      );

  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? buttonText;
  final String actionType;
  final String? actionValue;
  final String category;
  final int priority;
  final bool isActive;
  final String language;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static DateTime? _dateFromJson(dynamic value) =>
      value is String ? DateTime.tryParse(value) : null;
}
