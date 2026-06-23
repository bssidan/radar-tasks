import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/enums.dart';
import '../database/app_database.dart';
import '../services/app_state.dart';
import '../services/communication_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart' as du;
import 'add_edit_task_screen.dart';

class TaskDetailsScreen extends StatelessWidget {
  final String taskId;
  const TaskDetailsScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    Task? task;
    for (final t in state.allTasks) {
      if (t.id == taskId) {
        task = t;
        break;
      }
    }

    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('משימה')),
        body: const Center(child: Text('המשימה לא נמצאה')),
      );
    }

    final t = task;
    return Scaffold(
      appBar: AppBar(
        title: const Text('פרטי משימה'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'ערוך',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AddEditTaskScreen(existing: t)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'מחק',
            onPressed: () => _confirmDelete(context, state, t),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // כותרת + עדיפות
          Row(
            children: [
              Container(
                width: 6,
                height: 40,
                decoration: BoxDecoration(
                  color: t.priority.color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(t.title,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _badge(t.category.titleHe, t.category.color, t.category.icon),
              _badge(t.priority.titleHe, t.priority.color, Icons.flag),
              _badge(t.status.titleHe, AppTheme.blue, Icons.info_outline),
              if (t.isOverdue)
                _badge('באיחור', AppTheme.red, Icons.warning),
            ],
          ),
          const SizedBox(height: 16),
          if (t.description.isNotEmpty) ...[
            _section('תיאור', t.description),
            const SizedBox(height: 12),
          ],
          _infoRow(Icons.event, 'תאריך יעד',
              du.DateUtils.formatDate(t.dueDate)),
          if (t.dueTimeMinutes != null)
            _infoRow(Icons.access_time, 'שעת יעד',
                du.DateUtils.formatTime(t.dueTimeMinutes)),
          if (t.reminderDateTime != null)
            _infoRow(Icons.notifications_active, 'תזכורת',
                du.DateUtils.formatDateTime(t.reminderDateTime)),
          if (t.tags.isNotEmpty)
            _infoRow(Icons.label, 'תגיות', t.tags.join(', ')),
          if (t.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            _section('הערות', t.notes),
          ],

          // איש קשר
          if (t.contactName != null || t.contactPhone != null ||
              t.contactEmail != null) ...[
            const SizedBox(height: 16),
            _contactCard(context, t),
          ],

          const SizedBox(height: 20),
          // פעולות סטטוס
          if (t.status != TaskStatus.completed)
            ElevatedButton.icon(
              onPressed: () => state.completeTask(t),
              icon: const Icon(Icons.check_circle),
              label: const Text('סמן כהושלם'),
            )
          else
            OutlinedButton.icon(
              onPressed: () => state.reopenTask(t),
              icon: const Icon(Icons.replay),
              label: const Text('החזר לפתוחה'),
            ),

          const SizedBox(height: 24),
          // היסטוריה
          _historySection(context, state, t),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _section(String title, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(content, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 10),
          Text('$label: ',
              style: const TextStyle(color: AppTheme.textSecondary)),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _contactCard(BuildContext context, Task t) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: AppTheme.accent),
              const SizedBox(width: 8),
              Text(t.contactName ?? 'איש קשר',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              if (t.contactRole != null) ...[
                const SizedBox(width: 8),
                Text('(${t.contactRole})',
                    style: const TextStyle(color: AppTheme.textSecondary)),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (t.contactPhone != null)
                _actionBtn(Icons.call, 'התקשר', AppTheme.green,
                    () => CommunicationService.call(t.contactPhone!)),
              if (t.contactPhone != null)
                _actionBtn(Icons.chat, 'וואטסאפ', const Color(0xFF25D366),
                    () => CommunicationService.whatsapp(t.contactPhone!,
                        message: 'בנוגע ל: ${t.title}')),
              if (t.contactEmail != null)
                _actionBtn(Icons.email, 'מייל', AppTheme.blue,
                    () => CommunicationService.email(t.contactEmail!,
                        subject: t.title)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }

  Widget _historySection(BuildContext context, AppState state, Task t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('היסטוריית שינויים',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _infoRow(Icons.add_circle_outline, 'נוצרה',
            du.DateUtils.formatDateTime(t.createdAt)),
        _infoRow(Icons.update, 'עודכן לאחרונה',
            du.DateUtils.formatDateTime(t.updatedAt)),
        if (t.completedAt != null)
          _infoRow(Icons.check, 'הושלמה',
              du.DateUtils.formatDateTime(t.completedAt)),
        const SizedBox(height: 8),
        FutureBuilder<List<TaskHistoryRow>>(
          future: state.repo.getHistory(t.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(8),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final history = snapshot.data!;
            if (history.isEmpty) {
              return const Text('אין שינויים מתועדים',
                  style: TextStyle(color: AppTheme.textSecondary));
            }
            return Column(
              children: history.map((h) {
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history, size: 18),
                  title: Text(_historyLabel(h),
                      style: const TextStyle(fontSize: 14)),
                  subtitle: Text(du.DateUtils.formatDateTime(h.createdAt),
                      style: const TextStyle(fontSize: 11)),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  String _historyLabel(TaskHistoryRow h) {
    switch (h.actionType) {
      case 'created':
        return 'המשימה נוצרה';
      case 'category':
        return 'הועברה: ${h.oldValue} ← ${h.newValue}';
      case 'status':
        return 'סטטוס: ${h.oldValue} ← ${h.newValue}';
      case 'updated':
        return h.newValue ?? 'עודכן';
      default:
        return h.actionType;
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, AppState state, Task t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('מחיקת משימה'),
        content: Text('למחוק את "${t.title}"? פעולה זו אינה הפיכה.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ביטול')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('מחק',
                  style: TextStyle(color: AppTheme.red))),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await state.deleteTask(t);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('המשימה נמחקה')));
      }
    }
  }
}
