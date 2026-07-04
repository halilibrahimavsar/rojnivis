import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rojnivis/core/errors/failures.dart';
import 'package:rojnivis/features/calendar/domain/entities/reminder.dart';
import 'package:rojnivis/features/calendar/domain/repositories/calendar_repository.dart';

@injectable
class GetAllReminders {
  const GetAllReminders(this.repository);

  final CalendarRepository repository;

  Future<Either<Failure, List<Reminder>>> call() async {
    return repository.getAllReminders();
  }
}
