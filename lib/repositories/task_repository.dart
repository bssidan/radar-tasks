import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/task.dart';
import '../models/enums.dart';
import '../models/app_settings_model.dart';

const _uuid = Uuid();

/// שכבת גישה לנתונים. כל הקריאות/כתיבות עוברות כאן.
class TaskRepository {
  final AppDatabase db;
  TaskRepository(this.db);

  // ---------- המרות בין שורת DB למודל ----------
  Task _toModel(TaskRow r) {
    return Task(
      id: r.id,
      title: r.title,
      description: r.description,
      category: TaskCategoryX.fromDb(r.category),
      priority: TaskPriorityX.fromDb(r.priority),
      status: TaskStatusX.fromDb(r.status),
      dueDate: r.dueDate,
      dueTimeMinutes: r.dueTimeMinutes,
      reminderDateTime: r.reminderDateTime,
      reminderType: ReminderTypeX.fromDb(r.reminderType),
      contactName: r.contactName,
      contactPhone: r.contactPhone,
      contactEmail: r.contactEmail,
      contactRole: r.contactRole,
      notes: r.notes,
      tags: r.tags.isEmpty ? const [] : r.tags.split('|'),
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
      completedAt: r.completedAt,
      orderIndex: r.orderIndex,
      notificationId: r.notificationId,
    );
  }

  TasksCompanion _toCompanion(Task t) {
    return TasksCompanion(
      id: Value(t.id),
      title: Value(t.title),
      description: Value(t.description),
      category: Value(t.category.dbValue),
      priority: Value(t.priority.dbValue),
      status: Value(t.status.dbValue),
      dueDate: Value(t.dueDate),
      dueTimeMinutes: Value(t.dueTimeMinutes),
      reminderDateTime: Value(t.reminderDateTime),
      reminderType: Value(t.reminderType.dbValue),
      contactName: Value(t.contactName),
      contactPhone: Value(t.contactPhone),
      contactEmail: Value(t.contactEmail),
      contactRole: Value(t.contactRole),
      notes: Value(t.notes),
      tags: Value(t.tags.join('|')),
      createdAt: Value(t.createdAt),
      updatedAt: Value(t.updatedAt),
      completedAt: Value(t.completedAt),
      orderIndex: Value(t.orderIndex),
      notificationId: Value(t.notificationId),
    );
  }

  // ---------- שאילתות ----------
  Future<List<Task>> getAllTasks() async {
    final rows = await db.select(db.tasks).get();
    return rows.map(_toModel).toList();
  }

  /// זרם חי של כל המשימות — מתעדכן אוטומטית בכל שינוי DB.
  Stream<List<Task>> watchAllTasks() {
    return db.select(db.tasks).watch().map(
          (rows) => rows.map(_toModel).toList(),
        );
  }

  Future<Task?> getTaskById(String id) async {
    final row = await (db.select(db.tasks)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  Future<List<Task>> getTasksByCategory(TaskCategory category) async {
    final rows = await (db.select(db.tasks)
          ..where((t) => t.category.equals(category.dbValue)))
        .get();
    return rows.map(_toModel).toList();
  }

  // ---------- כתיבה ----------
  Future<Task> createTask(Task task) async {
    final now = DateTime.now();
    // מזהה התראה יציב (משתמשים ב-hashCode חיובי של ה-id).
    final notifId = task.notificationId ?? (task.id.hashCode & 0x7fffffff);
    final t = task.copyWith(
      updatedAt: now,
      notificationId: notifId,
    );
    await db.into(db.tasks).insert(_toCompanion(t),
        mode: InsertMode.insertOrReplace);
    await _addHistory(t.id, 'created', null, t.title);
    return t;
  }

  Future<Task> updateTask(Task task, {String actionType = 'updated'}) async {
    final t = task.copyWith(updatedAt: DateTime.now());
    await (db.update(db.tasks)..where((tbl) => tbl.id.equals(t.id)))
        .write(_toCompanion(t));
    return t;
  }

  /// עדכון משימה עם תיעוד שינוי קטגוריה/סטטוס בהיסטוריה.
  Future<Task> updateTaskWithHistory(Task oldTask, Task newTask) async {
    final t = newTask.copyWith(updatedAt: DateTime.now());
    await (db.update(db.tasks)..where((tbl) => tbl.id.equals(t.id)))
        .write(_toCompanion(t));

    if (oldTask.category != newTask.category) {
      await _addHistory(t.id, 'category', oldTask.category.titleHe,
          newTask.category.titleHe);
    }
    if (oldTask.status != newTask.status) {
      await _addHistory(
          t.id, 'status', oldTask.status.titleHe, newTask.status.titleHe);
    }
    if (oldTask.title != newTask.title ||
        oldTask.description != newTask.description ||
        oldTask.priority != newTask.priority ||
        oldTask.dueDate != newTask.dueDate) {
      await _addHistory(t.id, 'updated', null, 'עודכנו פרטי המשימה');
    }
    return t;
  }

  Future<void> deleteTask(String id) async {
    await (db.delete(db.tasks)..where((t) => t.id.equals(id))).go();
    await (db.delete(db.taskHistories)..where((h) => h.taskId.equals(id))).go();
  }

  Future<void> deleteAllData() async {
    await db.delete(db.tasks).go();
    await db.delete(db.taskHistories).go();
  }

  /// סימון משימה כהושלמה.
  Future<Task> completeTask(Task task) async {
    final updated = task.copyWith(
      status: TaskStatus.completed,
      completedAt: DateTime.now(),
    );
    await updateTaskWithHistory(task, updated);
    return updated;
  }

  /// החזרת משימה שהושלמה לסטטוס פתוחה.
  Future<Task> reopenTask(Task task) async {
    final updated = task.copyWith(
      status: TaskStatus.open,
      clearCompletedAt: true,
    );
    await updateTaskWithHistory(task, updated);
    return updated;
  }

  // ---------- היסטוריה ----------
  Future<void> _addHistory(
      String taskId, String actionType, String? oldVal, String? newVal) async {
    await db.into(db.taskHistories).insert(
          TaskHistoriesCompanion.insert(
            id: _uuid.v4(),
            taskId: taskId,
            actionType: actionType,
            oldValue: Value(oldVal),
            newValue: Value(newVal),
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<List<TaskHistoryRow>> getHistory(String taskId) async {
    return (db.select(db.taskHistories)
          ..where((h) => h.taskId.equals(taskId))
          ..orderBy([(h) => OrderingTerm.desc(h.createdAt)]))
        .get();
  }

  // ---------- הגדרות ----------
  Future<AppSettingsModel> getSettings() async {
    final row = await (db.select(db.appSettings)
          ..where((s) => s.id.equals(1)))
        .getSingleOrNull();
    if (row == null) {
      await db.into(db.appSettings).insert(
            const AppSettingsCompanion(id: Value(1)),
            mode: InsertMode.insertOrIgnore,
          );
      return const AppSettingsModel();
    }
    return AppSettingsModel(
      morningReminderEnabled: row.morningReminderEnabled,
      morningReminderMinutes: row.morningReminderMinutes,
      defaultCategory: TaskCategoryX.fromDb(row.defaultCategory),
      darkMode: row.darkMode,
      language: row.language,
      showCompletedTasks: row.showCompletedTasks,
      widgetRefreshEnabled: row.widgetRefreshEnabled,
      onboardingDone: row.onboardingDone,
    );
  }

  Future<void> saveSettings(AppSettingsModel s) async {
    await (db.update(db.appSettings)..where((tbl) => tbl.id.equals(1))).write(
      AppSettingsCompanion(
        id: const Value(1),
        morningReminderEnabled: Value(s.morningReminderEnabled),
        morningReminderMinutes: Value(s.morningReminderMinutes),
        defaultCategory: Value(s.defaultCategory.dbValue),
        darkMode: Value(s.darkMode),
        language: Value(s.language),
        showCompletedTasks: Value(s.showCompletedTasks),
        widgetRefreshEnabled: Value(s.widgetRefreshEnabled),
        onboardingDone: Value(s.onboardingDone),
      ),
    );
  }

  // ---------- ייצוא / ייבוא ----------
  Future<Map<String, dynamic>> exportToMap() async {
    final tasks = await getAllTasks();
    final settings = await getSettings();
    return {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'settings': {
        'morningReminderEnabled': settings.morningReminderEnabled,
        'morningReminderMinutes': settings.morningReminderMinutes,
        'defaultCategory': settings.defaultCategory.dbValue,
        'darkMode': settings.darkMode,
        'language': settings.language,
        'showCompletedTasks': settings.showCompletedTasks,
        'widgetRefreshEnabled': settings.widgetRefreshEnabled,
      },
    };
  }

  /// ייבוא. mode = 'replace' מוחק הכל קודם, 'merge' מוסיף/מעדכן.
  /// מחזיר את מספר המשימות שיובאו.
  Future<int> importFromMap(Map<String, dynamic> data,
      {required bool replace}) async {
    if (data['tasks'] is! List) {
      throw const FormatException('הקובץ אינו תקין: חסר שדה tasks');
    }
    final tasksJson = data['tasks'] as List;
    if (replace) {
      await deleteAllData();
    }
    int count = 0;
    for (final tj in tasksJson) {
      final task = Task.fromJson(tj as Map<String, dynamic>);
      await db.into(db.tasks).insert(_toCompanion(task),
          mode: InsertMode.insertOrReplace);
      count++;
    }
    return count;
  }

  /// בדיקת תקינות קובץ ייבוא.
  static bool isValidImport(Map<String, dynamic> data) {
    if (!data.containsKey('tasks')) return false;
    if (data['tasks'] is! List) return false;
    return true;
  }
}
