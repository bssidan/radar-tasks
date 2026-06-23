import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'app_database.g.dart';

/// טבלת המשימות.
/// שם מחלקת השורה שנוצרת הוא TaskRow כדי למנוע התנגשות עם מודל Task שלנו.
@DataClassName('TaskRow')
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get category => text()(); // dbValue של TaskCategory
  TextColumn get priority => text()(); // dbValue של TaskPriority
  TextColumn get status => text()(); // dbValue של TaskStatus
  DateTimeColumn get dueDate => dateTime().nullable()();
  // שעת היעד נשמרת כדקות מחצות (0-1439), null = ללא שעה.
  IntColumn get dueTimeMinutes => integer().nullable()();
  DateTimeColumn get reminderDateTime => dateTime().nullable()();
  TextColumn get reminderType => text().withDefault(const Constant('none'))();
  TextColumn get contactName => text().nullable()();
  TextColumn get contactPhone => text().nullable()();
  TextColumn get contactEmail => text().nullable()();
  TextColumn get contactRole => text().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get tags => text().withDefault(const Constant(''))(); // CSV
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  // מזהה התראה מקומי יציב (לביטול/עדכון).
  IntColumn get notificationId => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// טבלת היסטוריית שינויים.
@DataClassName('TaskHistoryRow')
class TaskHistories extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text()();
  TextColumn get actionType => text()(); // created/status/category/updated...
  TextColumn get oldValue => text().nullable()();
  TextColumn get newValue => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// טבלת הגדרות - שורה בודדת (id=1).
class AppSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  BoolColumn get morningReminderEnabled =>
      boolean().withDefault(const Constant(true))();
  // שעת תזכורת בוקר בדקות מחצות. ברירת מחדל 08:00 = 480.
  IntColumn get morningReminderMinutes =>
      integer().withDefault(const Constant(480))();
  TextColumn get defaultCategory =>
      text().withDefault(const Constant('active'))();
  BoolColumn get darkMode => boolean().withDefault(const Constant(true))();
  TextColumn get language => text().withDefault(const Constant('he'))();
  BoolColumn get showCompletedTasks =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get widgetRefreshEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get onboardingDone =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Tasks, TaskHistories, AppSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // קונסטרקטור לטסטים עם executor מותאם.
  AppDatabase.forTesting(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          // יוצר שורת הגדרות ברירת מחדל.
          await into(appSettings).insert(
            const AppSettingsCompanion(id: Value(1)),
            mode: InsertMode.insertOrIgnore,
          );
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          // מוודא שקיימת שורת הגדרות.
          final count = await (selectOnly(appSettings)
                ..addColumns([appSettings.id.count()]))
              .getSingle();
          final c = count.read(appSettings.id.count()) ?? 0;
          if (c == 0) {
            await into(appSettings).insert(
              const AppSettingsCompanion(id: Value(1)),
              mode: InsertMode.insertOrIgnore,
            );
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'radar_tasks.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
