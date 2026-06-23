import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/enums.dart';
import '../models/app_settings_model.dart';
import '../repositories/task_repository.dart';
import '../notifications/notification_service.dart';
import '../home_widget/home_widget_service.dart';

const _uuid = Uuid();

/// מצב מרכזי של האפליקציה. מקור אמת יחיד למסכים.
class AppState extends ChangeNotifier {
  final TaskRepository repo;
  AppState(this.repo);

  List<Task> _tasks = [];
  AppSettingsModel _settings = const AppSettingsModel();
  bool _loading = true;

  List<Task> get allTasks => _tasks;
  AppSettingsModel get settings => _settings;
  bool get loading => _loading;

  /// משימות פעילות בלבד (לא הושלמו/בוטלו).
  List<Task> get activeTasks =>
      _tasks.where((t) => !t.status.isClosed).toList();

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _settings = await repo.getSettings();
    _tasks = await repo.getAllTasks();
    _loading = false;
    notifyListeners();
    await _refreshWidget();
    await _rescheduleMorningReminder();
  }

  // ---------- שאילתות נגזרות ----------
  List<Task> tasksForCategory(TaskCategory category,
      {bool includeCompleted = false}) {
    var list = _tasks.where((t) => t.category == category).toList();
    if (!includeCompleted) {
      list = list.where((t) => !t.status.isClosed).toList();
    }
    return _sortTasks(list);
  }

  int openCountForCategory(TaskCategory category) {
    return _tasks
        .where((t) => t.category == category && !t.status.isClosed)
        .length;
  }

  int get overdueCount => activeTasks.where((t) => t.isOverdue).length;

  /// משימות "היום שלי": מחכים לי + בטיפול פעיל + איחור + להיום.
  List<Task> get todayTasks {
    final set = <String, Task>{};
    for (final t in activeTasks) {
      if (t.category == TaskCategory.waitingOnMe ||
          t.category == TaskCategory.active ||
          t.isOverdue ||
          t.isDueToday) {
        set[t.id] = t;
      }
    }
    return _sortTasks(set.values.toList());
  }

  /// 5 המשימות החשובות ביותר (להתחל יום).
  List<Task> get topPriorityTasks => todayTasks.take(5).toList();

  /// מיון: איחור קודם, אז קריטי, אז עדיפות, אז תאריך יעד.
  List<Task> _sortTasks(List<Task> list) {
    final sorted = [...list];
    sorted.sort((a, b) {
      // איחור קודם
      if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
      // קריטי תמיד לפני
      final critA = a.priority == TaskPriority.critical;
      final critB = b.priority == TaskPriority.critical;
      if (critA != critB) return critA ? -1 : 1;
      // עדיפות גבוהה יותר קודם
      if (a.priority.weight != b.priority.weight) {
        return b.priority.weight.compareTo(a.priority.weight);
      }
      // תאריך יעד מוקדם יותר קודם
      final ad = a.effectiveDueDateTime;
      final bd = b.effectiveDueDateTime;
      if (ad != null && bd != null) return ad.compareTo(bd);
      if (ad != null) return -1;
      if (bd != null) return 1;
      // orderIndex כברירת מחדל
      return a.orderIndex.compareTo(b.orderIndex);
    });
    return sorted;
  }

  /// תצוגה מקוצרת לכרטיסייה — עד N משימות.
  List<Task> previewForCategory(TaskCategory category, {int limit = 3}) {
    return tasksForCategory(category).take(limit).toList();
  }

  // ---------- פעולות CRUD ----------
  Future<Task> addTask({
    required String title,
    String description = '',
    required TaskCategory category,
    TaskPriority priority = TaskPriority.normal,
    TaskStatus status = TaskStatus.open,
    DateTime? dueDate,
    int? dueTimeMinutes,
    ReminderType reminderType = ReminderType.none,
    DateTime? customReminder,
    String? contactName,
    String? contactPhone,
    String? contactEmail,
    String? contactRole,
    String notes = '',
    List<String> tags = const [],
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    final reminder = _computeReminder(
        dueDate, dueTimeMinutes, reminderType, customReminder);

    final maxOrder = _tasks
        .where((t) => t.category == category)
        .fold<int>(0, (m, t) => t.orderIndex > m ? t.orderIndex : m);

    var task = Task(
      id: id,
      title: title.trim(),
      description: description.trim(),
      category: category,
      priority: priority,
      status: status,
      dueDate: dueDate,
      dueTimeMinutes: dueTimeMinutes,
      reminderDateTime: reminder,
      reminderType: reminderType,
      contactName: _nullIfEmpty(contactName),
      contactPhone: _nullIfEmpty(contactPhone),
      contactEmail: _nullIfEmpty(contactEmail),
      contactRole: _nullIfEmpty(contactRole),
      notes: notes.trim(),
      tags: tags,
      createdAt: now,
      updatedAt: now,
      orderIndex: maxOrder + 1,
    );

    task = await repo.createTask(task);
    _tasks.add(task);
    notifyListeners();

    await NotificationService.instance.scheduleTaskReminder(task);
    await _refreshWidget();
    await _rescheduleMorningReminder();
    return task;
  }

  Future<void> updateTask(Task oldTask, Task newTask, {
    ReminderType? reminderType,
    DateTime? customReminder,
  }) async {
    // חישוב תזכורת מחדש אם השתנה תאריך/סוג תזכורת.
    final rType = reminderType ?? newTask.reminderType;
    final reminder = _computeReminder(
        newTask.dueDate, newTask.dueTimeMinutes, rType, customReminder);
    var updated = newTask.copyWith(
      reminderType: rType,
      reminderDateTime: reminder,
      clearReminder: reminder == null,
    );

    updated = await repo.updateTaskWithHistory(oldTask, updated);
    _replaceInList(updated);
    notifyListeners();

    // עדכון תזכורת.
    if (updated.notificationId != null) {
      await NotificationService.instance
          .cancelTaskReminder(updated.notificationId!);
      await NotificationService.instance.scheduleTaskReminder(updated);
    }
    await _refreshWidget();
    await _rescheduleMorningReminder();
  }

  Future<void> changeCategory(Task task, TaskCategory newCategory) async {
    if (task.category == newCategory) return;
    final updated = task.copyWith(category: newCategory);
    await repo.updateTaskWithHistory(task, updated);
    _replaceInList(updated);
    notifyListeners();
    await _refreshWidget();
  }

  Future<void> completeTask(Task task) async {
    final updated = await repo.completeTask(task);
    _replaceInList(updated);
    notifyListeners();
    // משימה שהושלמה — מבטלים תזכורת עתידית.
    if (updated.notificationId != null) {
      await NotificationService.instance
          .cancelTaskReminder(updated.notificationId!);
    }
    await _refreshWidget();
    await _rescheduleMorningReminder();
  }

  Future<void> reopenTask(Task task) async {
    final updated = await repo.reopenTask(task);
    _replaceInList(updated);
    notifyListeners();
    await NotificationService.instance.scheduleTaskReminder(updated);
    await _refreshWidget();
    await _rescheduleMorningReminder();
  }

  Future<void> deleteTask(Task task) async {
    await repo.deleteTask(task.id);
    _tasks.removeWhere((t) => t.id == task.id);
    notifyListeners();
    if (task.notificationId != null) {
      await NotificationService.instance
          .cancelTaskReminder(task.notificationId!);
    }
    await _refreshWidget();
    await _rescheduleMorningReminder();
  }

  // ---------- הגדרות ----------
  Future<void> updateSettings(AppSettingsModel s) async {
    _settings = s;
    await repo.saveSettings(s);
    notifyListeners();
    await _rescheduleMorningReminder();
  }

  Future<void> markOnboardingDone() async {
    await updateSettings(_settings.copyWith(onboardingDone: true));
  }

  // ---------- ייצוא / ייבוא / מחיקה ----------
  Future<Map<String, dynamic>> exportData() => repo.exportToMap();

  Future<int> importData(Map<String, dynamic> data,
      {required bool replace}) async {
    final count = await repo.importFromMap(data, replace: replace);
    await load();
    // תזמון מחדש של תזכורות למשימות מיובאות.
    for (final t in _tasks) {
      await NotificationService.instance.scheduleTaskReminder(t);
    }
    return count;
  }

  Future<void> deleteAllData() async {
    await repo.deleteAllData();
    await NotificationService.instance.cancelAll();
    _tasks = [];
    notifyListeners();
    await _refreshWidget();
  }

  // ---------- עזרים ----------
  void _replaceInList(Task t) {
    final idx = _tasks.indexWhere((e) => e.id == t.id);
    if (idx >= 0) _tasks[idx] = t;
  }

  String? _nullIfEmpty(String? s) =>
      (s == null || s.trim().isEmpty) ? null : s.trim();

  DateTime? _computeReminder(DateTime? dueDate, int? dueTimeMinutes,
      ReminderType type, DateTime? custom) {
    if (type == ReminderType.none) return null;
    if (type == ReminderType.custom) return custom;
    if (dueDate == null) return null;
    final base = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      dueTimeMinutes != null ? dueTimeMinutes ~/ 60 : 9,
      dueTimeMinutes != null ? dueTimeMinutes % 60 : 0,
    );
    switch (type) {
      case ReminderType.atTime:
        return base;
      case ReminderType.tenMinBefore:
        return base.subtract(const Duration(minutes: 10));
      case ReminderType.hourBefore:
        return base.subtract(const Duration(hours: 1));
      case ReminderType.dayBefore:
        return base.subtract(const Duration(days: 1));
      default:
        return null;
    }
  }

  Future<void> _refreshWidget() async {
    if (!_settings.widgetRefreshEnabled) return;
    await HomeWidgetService.instance.updateWidget(_tasks);
  }

  Future<void> _rescheduleMorningReminder() async {
    if (!_settings.morningReminderEnabled) {
      await NotificationService.instance.cancelMorningReminder();
      return;
    }
    await NotificationService.instance.scheduleMorningReminder(
      minutesFromMidnight: _settings.morningReminderMinutes,
      waitingOnMeCount: openCountForCategory(TaskCategory.waitingOnMe),
      activeCount: openCountForCategory(TaskCategory.active),
    );
  }
}
