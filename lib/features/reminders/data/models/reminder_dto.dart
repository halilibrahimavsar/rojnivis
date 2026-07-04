import 'package:hive/hive.dart';
import 'package:rojnivis/core/constants/app_constants.dart';
import 'package:rojnivis/features/reminders/domain/entities/reminder.dart';

part 'reminder_dto.g.dart';

@HiveType(typeId: HiveTypeIds.reminder)
class ReminderDto {
  const ReminderDto({
    required this.id,
    required this.title,
    required this.date,
    required this.importanceLevel,
    this.description,
  });

  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final DateTime date;
  @HiveField(3)
  final String importanceLevel;
  @HiveField(4)
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
