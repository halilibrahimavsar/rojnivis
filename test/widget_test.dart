import 'dart:io';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rojnivis/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rojnivis/di/injection.dart';
import 'package:rojnivis/features/categories/data/models/category_model.dart';
import 'package:rojnivis/features/journal/data/models/journal_entry_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();

    final dir = await Directory.systemTemp.createTemp('rojnivis_test_');
    Hive.init(dir.path);
    Hive.registerAdapter(CategoryModelAdapter());
    Hive.registerAdapter(JournalEntryModelAdapter());
    await Hive.openBox<CategoryModel>(CategoryModel.boxName);
    await Hive.openBox<JournalEntryModel>(JournalEntryModel.boxName);

    await configureDependencies();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  testWidgets('App pumps', (WidgetTester tester) async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],
        path: 'assets/translations',
        fallbackLocale: const Locale('tr', 'TR'),
        child: const RojnivisApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Rojnivis'), findsWidgets);
  });
}
