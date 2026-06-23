import 'enums.dart';

/// מודל משימה לשימוש ב-UI ובלוגיקה (נפרד משורת ה-DB של Drift).
class Task {
  final String id;
  final String title;
  final String description;
  final TaskCategory category;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? dueDate;
  final int? dueTimeMinutes; // דקות מחצות, null = ללא שעה
  final DateTime? reminderDateTime;
  final ReminderType reminderType;
  final String? contactName;
  final String? contactPhone;
  final String? contactEmail;
  final String? contactRole;
  final String notes;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final int orderIndex;
  final int? notificationId;

  const Task({
    required this.id,
    required this.title,
    this.description = '',
    required this.category,
    this.priority = TaskPriority.normal,
    this.status = TaskStatus.open,
    this.dueDate,
    this.dueTimeMinutes,
    this.reminderDateTime,
    this.reminderType = ReminderType.none,
    this.contactName,
    this.contactPhone,
    this.contactEmail,
    this.contactRole,
    this.notes = '',
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.orderIndex = 0,
    this.notificationId,
  });

  /// האם המשימה באיחור: יש תאריך עבר, וסטטוס פעיל.
  bool get isOverdue {
    if (dueDate == null) return false;
    if (status.isClosed) return false;
    final now = DateTime.now();
    final due = effectiveDueDateTime ?? dueDate!;
    return due.isBefore(now);
  }

  /// תאריך+שעת היעד המשולבים, אם קיימים.
  DateTime? get effectiveDueDateTime {
    if (dueDate == null) return null;
    if (dueTimeMinutes == null) {
      // ללא שעה — מתייחסים לסוף היום לצורך בדיקת איחור.
      return DateTime(dueDate!.year, dueDate!.month, dueDate!.day, 23, 59);
    }
    return DateTime(
      dueDate!.year,
      dueDate!.month,
      dueDate!.day,
      dueTimeMinutes! ~/ 60,
      dueTimeMinutes! % 60,
    );
  }

  /// האם תאריך היעד הוא היום.
  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  Task copyWith({
    String? title,
    String? description,
    TaskCategory? category,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    bool clearDueDate = false,
    int? dueTimeMinutes,
    bool clearDueTime = false,
    DateTime? reminderDateTime,
    bool clearReminder = false,
    ReminderType? reminderType,
    String? contactName,
    String? contactPhone,
    String? contactEmail,
    String? contactRole,
    String? notes,
    List<String>? tags,
    DateTime? updatedAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    int? orderIndex,
    int? notificationId,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      dueTimeMinutes:
          clearDueTime ? null : (dueTimeMinutes ?? this.dueTimeMinutes),
      reminderDateTime:
          clearReminder ? null : (reminderDateTime ?? this.reminderDateTime),
      reminderType: reminderType ?? this.reminderType,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      contactRole: contactRole ?? this.contactRole,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      orderIndex: orderIndex ?? this.orderIndex,
      notificationId: notificationId ?? this.notificationId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category.dbValue,
        'priority': priority.dbValue,
        'status': status.dbValue,
        'dueDate': dueDate?.toIso8601String(),
        'dueTimeMinutes': dueTimeMinutes,
        'reminderDateTime': reminderDateTime?.toIso8601String(),
        'reminderType': reminderType.dbValue,
        'contactName': contactName,
        'contactPhone': contactPhone,
        'contactEmail': contactEmail,
        'contactRole': contactRole,
        'notes': notes,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'orderIndex': orderIndex,
        'notificationId': notificationId,
      };

  factory Task.fromJson(Map<String, dynamic> j) {
    return Task(
      id: j['id'] as String,
      title: j['title'] as String,
      description: (j['description'] as String?) ?? '',
      category: TaskCategoryX.fromDb(j['category'] as String),
      priority: TaskPriorityX.fromDb(j['priority'] as String),
      status: TaskStatusX.fromDb(j['status'] as String),
      dueDate:
          j['dueDate'] != null ? DateTime.parse(j['dueDate'] as String) : null,
      dueTimeMinutes: j['dueTimeMinutes'] as int?,
      reminderDateTime: j['reminderDateTime'] != null
          ? DateTime.parse(j['reminderDateTime'] as String)
          : null,
      reminderType: ReminderTypeX.fromDb(
          (j['reminderType'] as String?) ?? 'none'),
      contactName: j['contactName'] as String?,
      contactPhone: j['contactPhone'] as String?,
      contactEmail: j['contactEmail'] as String?,
      contactRole: j['contactRole'] as String?,
      notes: (j['notes'] as String?) ?? '',
      tags: (j['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      createdAt: DateTime.parse(j['createdAt'] as String),
      updatedAt: DateTime.parse(j['updatedAt'] as String),
      completedAt: j['completedAt'] != null
          ? DateTime.parse(j['completedAt'] as String)
          : null,
      orderIndex: (j['orderIndex'] as int?) ?? 0,
      notificationId: j['notificationId'] as int?,
    );
  }
}
