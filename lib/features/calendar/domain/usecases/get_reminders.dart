import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:rojnivis/core/errors/failures.dart';
import 'package:rojnivis/features/calendar/domain/entities/reminder.dart';
import 'package:rojnivis/features/calendar/domain/repositories/calendar_repository.dart';

@injectable
class GetReminders {
  const GetReminders(this.repository);

  final CalendarRepository repository;

  Future<Either<Failure, List<Reminder>>> call(GetRemindersParams params) {
    return repository.getReminders(params.startDate, params.endDate);
  }
}

class GetRemindersParams extends Equatable {
  const GetRemindersParams({required this.startDate, required this.endDate});

  final DateTime startDate;
  final DateTime endDate;

  @override
  List<Object?> get props => [startDate, endDate];
}
