import 'enums.dart';

class AppSettingsModel {
  final bool morningReminderEnabled;
  final int morningReminderMinutes; // דקות מחצות
  final TaskCategory defaultCategory;
  final bool darkMode;
  final String language;
  final bool showCompletedTasks;
  final bool widgetRefreshEnabled;
  final bool onboardingDone;

  const AppSettingsModel({
    this.morningReminderEnabled = true,
    this.morningReminderMinutes = 480, // 08:00
    this.defaultCategory = TaskCategory.active,
    this.darkMode = true,
    this.language = 'he',
    this.showCompletedTasks = false,
    this.widgetRefreshEnabled = true,
    this.onboardingDone = false,
  });

  AppSettingsModel copyWith({
    bool? morningReminderEnabled,
    int? morningReminderMinutes,
    TaskCategory? defaultCategory,
    bool? darkMode,
    String? language,
    bool? showCompletedTasks,
    bool? widgetRefreshEnabled,
    bool? onboardingDone,
  }) {
    return AppSettingsModel(
      morningReminderEnabled:
          morningReminderEnabled ?? this.morningReminderEnabled,
      morningReminderMinutes:
          morningReminderMinutes ?? this.morningReminderMinutes,
      defaultCategory: defaultCategory ?? this.defaultCategory,
      darkMode: darkMode ?? this.darkMode,
      language: language ?? this.language,
      showCompletedTasks: showCompletedTasks ?? this.showCompletedTasks,
      widgetRefreshEnabled: widgetRefreshEnabled ?? this.widgetRefreshEnabled,
      onboardingDone: onboardingDone ?? this.onboardingDone,
    );
  }

  String get morningReminderTimeLabel {
    final h = (morningReminderMinutes ~/ 60).toString().padLeft(2, '0');
    final m = (morningReminderMinutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}
