import 'package:flutter/material.dart';

/// ארבע הקטגוריות הקבועות של רדאר התלויות הניהולי.
enum TaskCategory {
  waitingOnMe, // מחכים לי - אדום
  active, // בטיפול פעיל - ירוק
  waitingOnThem, // אני מחכה להם - כחול
  parked, // יום אחד / מוקפא - אפור
}

extension TaskCategoryX on TaskCategory {
  /// מזהה יציב לשמירה במסד הנתונים (לא להשתמש ב-index שעלול להשתנות).
  String get dbValue {
    switch (this) {
      case TaskCategory.waitingOnMe:
        return 'waiting_on_me';
      case TaskCategory.active:
        return 'active';
      case TaskCategory.waitingOnThem:
        return 'waiting_on_them';
      case TaskCategory.parked:
        return 'parked';
    }
  }

  static TaskCategory fromDb(String value) {
    switch (value) {
      case 'waiting_on_me':
        return TaskCategory.waitingOnMe;
      case 'active':
        return TaskCategory.active;
      case 'waiting_on_them':
        return TaskCategory.waitingOnThem;
      case 'parked':
        return TaskCategory.parked;
      default:
        return TaskCategory.active;
    }
  }

  String get titleHe {
    switch (this) {
      case TaskCategory.waitingOnMe:
        return 'מחכים לי';
      case TaskCategory.active:
        return 'בטיפול פעיל';
      case TaskCategory.waitingOnThem:
        return 'אני מחכה להם';
      case TaskCategory.parked:
        return 'יום אחד / מוקפא';
    }
  }

  String get titleEn {
    switch (this) {
      case TaskCategory.waitingOnMe:
        return "They're waiting on me";
      case TaskCategory.active:
        return 'Active — in my hands';
      case TaskCategory.waitingOnThem:
        return 'Waiting on them';
      case TaskCategory.parked:
        return 'Parked — not now';
    }
  }

  Color get color {
    switch (this) {
      case TaskCategory.waitingOnMe:
        return const Color(0xFFE53935); // אדום
      case TaskCategory.active:
        return const Color(0xFF43A047); // ירוק
      case TaskCategory.waitingOnThem:
        return const Color(0xFF1E88E5); // כחול
      case TaskCategory.parked:
        return const Color(0xFF757575); // אפור
    }
  }

  IconData get icon {
    switch (this) {
      case TaskCategory.waitingOnMe:
        return Icons.local_fire_department; // להבה / דחיפות
      case TaskCategory.active:
        return Icons.bolt; // ברק
      case TaskCategory.waitingOnThem:
        return Icons.hourglass_bottom; // שעון חול
      case TaskCategory.parked:
        return Icons.pause_circle_outline; // Pause
    }
  }
}

/// עדיפות המשימה.
enum TaskPriority { low, normal, high, critical }

extension TaskPriorityX on TaskPriority {
  String get dbValue {
    switch (this) {
      case TaskPriority.low:
        return 'low';
      case TaskPriority.normal:
        return 'normal';
      case TaskPriority.high:
        return 'high';
      case TaskPriority.critical:
        return 'critical';
    }
  }

  static TaskPriority fromDb(String value) {
    switch (value) {
      case 'low':
        return TaskPriority.low;
      case 'normal':
        return TaskPriority.normal;
      case 'high':
        return TaskPriority.high;
      case 'critical':
        return TaskPriority.critical;
      default:
        return TaskPriority.normal;
    }
  }

  String get titleHe {
    switch (this) {
      case TaskPriority.low:
        return 'נמוכה';
      case TaskPriority.normal:
        return 'רגילה';
      case TaskPriority.high:
        return 'גבוהה';
      case TaskPriority.critical:
        return 'קריטית';
    }
  }

  /// ערך מספרי למיון - גבוה יותר = דחוף יותר.
  int get weight {
    switch (this) {
      case TaskPriority.low:
        return 0;
      case TaskPriority.normal:
        return 1;
      case TaskPriority.high:
        return 2;
      case TaskPriority.critical:
        return 3;
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.low:
        return const Color(0xFF90A4AE);
      case TaskPriority.normal:
        return const Color(0xFF64B5F6);
      case TaskPriority.high:
        return const Color(0xFFFFB300);
      case TaskPriority.critical:
        return const Color(0xFFE53935);
    }
  }
}

/// סטטוס המשימה.
enum TaskStatus { open, inProgress, waiting, completed, cancelled }

extension TaskStatusX on TaskStatus {
  String get dbValue {
    switch (this) {
      case TaskStatus.open:
        return 'open';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.waiting:
        return 'waiting';
      case TaskStatus.completed:
        return 'completed';
      case TaskStatus.cancelled:
        return 'cancelled';
    }
  }

  static TaskStatus fromDb(String value) {
    switch (value) {
      case 'open':
        return TaskStatus.open;
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'waiting':
        return TaskStatus.waiting;
      case 'completed':
        return TaskStatus.completed;
      case 'cancelled':
        return TaskStatus.cancelled;
      default:
        return TaskStatus.open;
    }
  }

  String get titleHe {
    switch (this) {
      case TaskStatus.open:
        return 'פתוחה';
      case TaskStatus.inProgress:
        return 'בטיפול';
      case TaskStatus.waiting:
        return 'ממתינה';
      case TaskStatus.completed:
        return 'הושלמה';
      case TaskStatus.cancelled:
        return 'בוטלה';
    }
  }

  /// משימה שאינה פעילה (לא נחשבת באיחור, לא נכנסת לרשימות פעילות).
  bool get isClosed =>
      this == TaskStatus.completed || this == TaskStatus.cancelled;
}

/// סוגי תזכורת מוגדרים מראש.
enum ReminderType {
  none,
  atTime,
  tenMinBefore,
  hourBefore,
  dayBefore,
  custom,
}

extension ReminderTypeX on ReminderType {
  String get dbValue {
    switch (this) {
      case ReminderType.none:
        return 'none';
      case ReminderType.atTime:
        return 'at_time';
      case ReminderType.tenMinBefore:
        return 'ten_min';
      case ReminderType.hourBefore:
        return 'hour';
      case ReminderType.dayBefore:
        return 'day';
      case ReminderType.custom:
        return 'custom';
    }
  }

  static ReminderType fromDb(String value) {
    switch (value) {
      case 'at_time':
        return ReminderType.atTime;
      case 'ten_min':
        return ReminderType.tenMinBefore;
      case 'hour':
        return ReminderType.hourBefore;
      case 'day':
        return ReminderType.dayBefore;
      case 'custom':
        return ReminderType.custom;
      default:
        return ReminderType.none;
    }
  }

  String get titleHe {
    switch (this) {
      case ReminderType.none:
        return 'ללא';
      case ReminderType.atTime:
        return 'בזמן המשימה';
      case ReminderType.tenMinBefore:
        return '10 דקות לפני';
      case ReminderType.hourBefore:
        return 'שעה לפני';
      case ReminderType.dayBefore:
        return 'יום לפני';
      case ReminderType.custom:
        return 'מותאם אישית';
    }
  }
}
