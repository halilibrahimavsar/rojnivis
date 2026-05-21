import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rojnivis/core/errors/failures.dart';
import 'package:rojnivis/features/calendar/data/datasources/local/calendar_local_data_source.dart';
import 'package:rojnivis/core/services/notification_service.dart';
import 'package:rojnivis/features/calendar/data/models/reminder_dto.dart';
import 'package:rojnivis/features/calendar/domain/entities/reminder.dart';
import 'package:rojnivis/features/calendar/domain/repositories/calendar_repository.dart';

@LazySingleton(as: CalendarRepository)
class CalendarRepositoryImpl implements CalendarRepository {
  CalendarRepositoryImpl(this.localDataSource);

  final CalendarLocalDataSource localDataSource;

  @override
  Future<Either<Failure, List<Reminder>>> getReminders(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final dtos = await localDataSource.getReminders(startDate, endDate);
      final entities = dtos.map((dto) => dto.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addReminder(Reminder reminder) async {
    try {
      final dto = ReminderDto.fromEntity(reminder);
      await localDataSource.addReminder(dto);
      await NotificationService().scheduleReminderNotification(reminder);
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReminder(String id) async {
    try {
      await localDataSource.deleteReminder(id);
      await NotificationService().cancelReminderNotification(id);
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
