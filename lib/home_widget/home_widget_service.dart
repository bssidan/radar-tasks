import 'package:home_widget/home_widget.dart';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../models/enums.dart';

/// מעדכן את ה-Widget במסך הבית של המכשיר.
/// שומר נתונים שה-Widget הנייטיב קורא מהם.
class HomeWidgetService {
  HomeWidgetService._();
  static final HomeWidgetService instance = HomeWidgetService._();

  // שם ה-provider של ה-Widget ב-Android (חייב להתאים ל-AndroidManifest).
  static const String _androidWidgetName = 'RadarWidgetProvider';
  static const String _iOSWidgetName = 'RadarWidget';
  static const String _appGroupId = 'group.com.radartasks.app';

  Future<void> init() async {
    // נדרש ל-iOS App Group; ב-Android לא מזיק.
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  /// מחשב נתונים מהמשימות ושולח אותם ל-Widget.
  Future<void> updateWidget(List<Task> allTasks) async {
    try {
      final active = allTasks
          .where((t) => !t.status.isClosed)
          .toList();

      final waitingOnMe = active
          .where((t) => t.category == TaskCategory.waitingOnMe)
          .length;
      final activeCount =
          active.where((t) => t.category == TaskCategory.active).length;
      final overdue = active.where((t) => t.isOverdue).length;

      // המשימה הקרובה ביותר (לפי תאריך יעד) מבין הפעילות עם תאריך.
      final withDue = active
          .where((t) => t.effectiveDueDateTime != null)
          .toList()
        ..sort((a, b) =>
            a.effectiveDueDateTime!.compareTo(b.effectiveDueDateTime!));
      final nextTitle = withDue.isNotEmpty ? withDue.first.title : 'אין משימות קרובות';

      await HomeWidget.saveWidgetData<int>('waiting_on_me', waitingOnMe);
      await HomeWidget.saveWidgetData<int>('active', activeCount);
      await HomeWidget.saveWidgetData<int>('overdue', overdue);
      await HomeWidget.saveWidgetData<String>('next_task', nextTitle);
      await HomeWidget.saveWidgetData<String>('title', 'Radar Tasks');

      await HomeWidget.updateWidget(
        androidName: _androidWidgetName,
        iOSName: _iOSWidgetName,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Widget update failed: $e');
    }
  }
}
