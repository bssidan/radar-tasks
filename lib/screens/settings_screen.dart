import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/enums.dart';
import '../services/app_state.dart';
import '../notifications/notification_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('הגדרות')),
      body: ListView(
        children: [
          _header('תזכורת בוקר'),
          SwitchListTile(
            title: const Text('הפעל תזכורת בוקר יומית'),
            value: s.morningReminderEnabled,
            activeColor: AppTheme.accent,
            onChanged: (v) => state.updateSettings(
                s.copyWith(morningReminderEnabled: v)),
          ),
          ListTile(
            enabled: s.morningReminderEnabled,
            leading: const Icon(Icons.access_time),
            title: const Text('שעת תזכורת בוקר'),
            trailing: Text(s.morningReminderTimeLabel,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                    hour: s.morningReminderMinutes ~/ 60,
                    minute: s.morningReminderMinutes % 60),
              );
              if (picked != null) {
                state.updateSettings(s.copyWith(
                    morningReminderMinutes:
                        picked.hour * 60 + picked.minute));
              }
            },
          ),
          const Divider(),
          _header('תצוגה'),
          SwitchListTile(
            title: const Text('הצג משימות שהושלמו'),
            value: s.showCompletedTasks,
            activeColor: AppTheme.accent,
            onChanged: (v) =>
                state.updateSettings(s.copyWith(showCompletedTasks: v)),
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('קטגוריית ברירת מחדל'),
            trailing: DropdownButton<TaskCategory>(
              value: s.defaultCategory,
              dropdownColor: AppTheme.surface,
              underline: const SizedBox(),
              items: TaskCategory.values
                  .map((c) => DropdownMenuItem(
                      value: c, child: Text(c.titleHe)))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  state.updateSettings(s.copyWith(defaultCategory: v));
                }
              },
            ),
          ),
          SwitchListTile(
            title: const Text('עדכון אוטומטי של Widget'),
            value: s.widgetRefreshEnabled,
            activeColor: AppTheme.accent,
            onChanged: (v) =>
                state.updateSettings(s.copyWith(widgetRefreshEnabled: v)),
          ),
          const Divider(),
          _header('גיבוי ונתונים'),
          ListTile(
            leading: const Icon(Icons.upload_file, color: AppTheme.green),
            title: const Text('ייצוא נתונים (JSON)'),
            subtitle: const Text('שמירת גיבוי של כל המשימות'),
            onTap: () => _exportData(context, state),
          ),
          ListTile(
            leading: const Icon(Icons.download, color: AppTheme.blue),
            title: const Text('ייבוא נתונים (JSON)'),
            subtitle: const Text('שחזור מקובץ גיבוי'),
            onTap: () => _importData(context, state),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active,
                color: AppTheme.accent),
            title: const Text('בדיקת התראה'),
            subtitle: const Text('שלח התראת בדיקה מיידית'),
            onTap: () async {
              await NotificationService.instance.showTestNotification();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppTheme.red),
            title: const Text('מחק את כל הנתונים'),
            subtitle: const Text('פעולה בלתי הפיכה'),
            onTap: () => _deleteAll(context, state),
          ),
          const Divider(),
          _header('אודות'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('רדאר התלויות הניהולי'),
            subtitle: Text(
                'גרסה 1.0.0\nניהול משימות, תלויות ותזכורות — מקומי לחלוטין, ללא ענן.'),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _header(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(text,
            style: const TextStyle(
                color: AppTheme.accent,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
      );

  Future<void> _exportData(BuildContext context, AppState state) async {
    try {
      final data = await state.exportData();
      final json = const JsonEncoder.withIndent('  ').convert(data);
      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final file = File('${dir.path}/radar_tasks_backup_$stamp.json');
      await file.writeAsString(json);
      await Share.shareXFiles([XFile(file.path)],
          subject: 'גיבוי Radar Tasks');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('שגיאה בייצוא: $e')));
      }
    }
  }

  Future<void> _importData(BuildContext context, AppState state) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      // בדיקת תקינות
      if (!_isValid(data)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('הקובץ אינו תקין')));
        }
        return;
      }

      if (!context.mounted) return;
      // אזהרה: מיזוג או החלפה
      final mode = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('ייבוא נתונים'),
          content: const Text(
              'כיצד לייבא את הנתונים?\n\nמיזוג — מוסיף/מעדכן משימות קיימות.\nהחלפה — מוחק את כל הנתונים הקיימים ומחליף.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('ביטול')),
            TextButton(
                onPressed: () => Navigator.pop(context, 'merge'),
                child: const Text('מיזוג')),
            TextButton(
                onPressed: () => Navigator.pop(context, 'replace'),
                child: const Text('החלפה',
                    style: TextStyle(color: AppTheme.red))),
          ],
        ),
      );
      if (mode == null) return;

      final count =
          await state.importData(data, replace: mode == 'replace');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('יובאו $count משימות בהצלחה')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('שגיאה בייבוא: $e')));
      }
    }
  }

  bool _isValid(Map<String, dynamic> data) {
    return data.containsKey('tasks') && data['tasks'] is List;
  }

  Future<void> _deleteAll(BuildContext context, AppState state) async {
    // אישור ראשון
    final first = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('מחיקת כל הנתונים'),
        content: const Text('האם אתה בטוח? כל המשימות יימחקו לצמיתות.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ביטול')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('המשך')),
        ],
      ),
    );
    if (first != true || !context.mounted) return;

    // אישור שני
    final second = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('אישור סופי'),
        content: const Text('פעולה זו בלתי הפיכה. למחוק הכל?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ביטול')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('מחק הכל',
                  style: TextStyle(color: AppTheme.red))),
        ],
      ),
    );
    if (second == true) {
      await state.deleteAllData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('כל הנתונים נמחקו')));
      }
    }
  }
}
