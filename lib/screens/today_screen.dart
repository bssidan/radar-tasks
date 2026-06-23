import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/enums.dart';
import '../models/task.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/task_tile.dart';
import '../widgets/empty_state.dart';
import 'task_details_screen.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final waitingOnMe =
        state.tasksForCategory(TaskCategory.waitingOnMe);
    final active = state.tasksForCategory(TaskCategory.active);
    final overdue = state.activeTasks.where((t) => t.isOverdue).toList();
    final dueToday = state.activeTasks.where((t) => t.isDueToday).toList();

    final allEmpty = waitingOnMe.isEmpty &&
        active.isEmpty &&
        overdue.isEmpty &&
        dueToday.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('היום שלי'),
        actions: [
          TextButton.icon(
            onPressed: () => _startDay(context, state),
            icon: const Icon(Icons.play_arrow, color: AppTheme.accent),
            label: const Text('התחל יום',
                style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
      body: allEmpty
          ? const EmptyState(
              icon: Icons.wb_sunny,
              message: 'אין משימות להיום. יום נקי!',
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                if (overdue.isNotEmpty)
                  _group(context, 'באיחור', overdue, AppTheme.red),
                if (dueToday.isNotEmpty)
                  _group(context, 'להיום', dueToday, AppTheme.accent),
                if (waitingOnMe.isNotEmpty)
                  _group(context, 'מחכים לי', waitingOnMe, AppTheme.red),
                if (active.isNotEmpty)
                  _group(context, 'בטיפול פעיל', active, AppTheme.green),
              ],
            ),
    );
  }

  Widget _group(
      BuildContext context, String title, List<Task> tasks, Color color) {
    // הסרת כפילויות לפי id בתוך הקבוצה
    final seen = <String>{};
    final unique = tasks.where((t) => seen.add(t.id)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            children: [
              Container(width: 4, height: 18, color: color),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(width: 6),
              Text('(${unique.length})',
                  style: const TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        ),
        ...unique.map((t) => TaskTile(
              task: t,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => TaskDetailsScreen(taskId: t.id)),
              ),
              onComplete: () =>
                  context.read<AppState>().completeTask(t),
            )),
      ],
    );
  }

  void _startDay(BuildContext context, AppState state) {
    final top = state.topPriorityTasks;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('5 המשימות החשובות להיום',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (top.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text('אין משימות דחופות. כל הכבוד!')),
              )
            else
              ...top.asMap().entries.map((e) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.accent,
                      radius: 14,
                      child: Text('${e.key + 1}',
                          style: const TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontWeight: FontWeight.bold)),
                    ),
                    title: Text(e.value.title),
                    subtitle: Text(e.value.category.titleHe,
                        style: TextStyle(color: e.value.category.color)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                TaskDetailsScreen(taskId: e.value.id)),
                      );
                    },
                  )),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
