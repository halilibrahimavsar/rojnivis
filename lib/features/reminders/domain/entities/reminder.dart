import 'package:equatable/equatable.dart';

enum ImportanceLevel { low, medium, high }

class Reminder extends Equatable {
  const Reminder({
    required this.id,
    required this.title,
    required this.date,
    required this.importanceLevel,
    this.description,
  });

  final String id;
  final String title;
  final DateTime date;
  final ImportanceLevel importanceLevel;
  final String? description;

  Reminder copyWith({
    String? id,
    String? title,
    DateTime? date,
    ImportanceLevel? importanceLevel,
    String? description,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      importanceLevel: importanceLevel ?? this.importanceLevel,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [id, title, date, importanceLevel, description];
}
