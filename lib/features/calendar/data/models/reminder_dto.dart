import 'package:rojnivis/features/calendar/domain/entities/reminder.dart';

class ReminderDto {
  const ReminderDto({
    required this.id,
    required this.title,
    required this.date,
    required this.importanceLevel,
    this.description,
  });

  final String id;
  final String title;
  final DateTime date;
  final String importanceLevel;
  final String? description;

  factory ReminderDto.fromJson(Map<String, dynamic> json) => ReminderDto(
    id: json['id'] as String,
    title: json['title'] as String,
    date: DateTime.parse(json['date'] as String),
    importanceLevel: json['importanceLevel'] as String,
    description: json['description'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date.toIso8601String(),
    'importanceLevel': importanceLevel,
    if (description != null) 'description': description,
  };

  Reminder toEntity() {
    return Reminder(
      id: id,
      title: title,
      date: date,
      importanceLevel: ImportanceLevel.values.firstWhere(
        (e) => e.name == importanceLevel,
        orElse: () => ImportanceLevel.low,
      ),
      description: description,
    );
  }

  factory ReminderDto.fromEntity(Reminder entity) {
    return ReminderDto(
      id: entity.id,
      title: entity.title,
      date: entity.date,
      importanceLevel: entity.importanceLevel.name,
      description: entity.description,
    );
  }
}
