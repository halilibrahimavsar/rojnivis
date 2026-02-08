import 'package:equatable/equatable.dart';

class JournalFilter extends Equatable {
  final String query;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String>? categoryIds;
  final List<String>? tags;

  const JournalFilter({
    this.query = '',
    this.startDate,
    this.endDate,
    this.categoryIds,
    this.tags,
  });

  bool get isEmpty =>
      query.isEmpty &&
      startDate == null &&
      endDate == null &&
      (categoryIds == null || categoryIds!.isEmpty) &&
      (tags == null || tags!.isEmpty);

  JournalFilter copyWith({
    String? query,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categoryIds,
    List<String>? tags,
  }) {
    return JournalFilter(
      query: query ?? this.query,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      categoryIds: categoryIds ?? this.categoryIds,
      tags: tags ?? this.tags,
    );
  }

  @override
  List<Object?> get props => [query, startDate, endDate, categoryIds, tags];
}
