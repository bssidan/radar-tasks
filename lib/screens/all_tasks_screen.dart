import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/enums.dart';
import '../models/task.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/task_tile.dart';
import '../widgets/empty_state.dart';
import 'add_edit_task_screen.dart';
import 'task_details_screen.dart';

class AllTasksScreen extends StatefulWidget {
  const AllTasksScreen({super.key});

  @override
  State<AllTasksScreen> createState() => _AllTasksScreenState();
}

class _AllTasksScreenState extends State<AllTasksScreen> {
  String _search = '';
  TaskCategory? _catFilter;
  TaskStatus? _statusFilter;
  TaskPriority? _priorityFilter;
  bool _overdueOnly = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final showCompleted = state.settings.showCompletedTasks;

    var tasks = state.allTasks.where((t) {
      if (!showCompleted && t.status.isClosed) return false;
      if (_search.isNotEmpty &&
          !t.title.toLowerCase().contains(_search.toLowerCase()) &&
          !t.description.toLowerCase().contains(_search.toLowerCase()) &&
          !(t.contactName ?? '').toLowerCase().contains(_search.toLowerCase())) {
        return false;
      }
      if (_catFilter != null && t.category != _catFilter) return false;
      if (_statusFilter != null && t.status != _statusFilter) return false;
      if (_priorityFilter != null && t.priority != _priorityFilter) {
        return false;
      }
      if (_overdueOnly && !t.isOverdue) return false;
      return true;
    }).toList();

    tasks.sort((a, b) {
      if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
      if (a.priority.weight != b.priority.weight) {
        return b.priority.weight.compareTo(a.priority.weight);
      }
      final ad = a.effectiveDueDateTime;
      final bd = b.effectiveDueDateTime;
      if (ad != null && bd != null) return ad.compareTo(bd);
      return 0;
    });

    return Scaffold(
      appBar: AppBar(title: const Text('כל המשימות')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'חיפוש גלובלי...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                FilterChip(
                  label: const Text('באיחור בלבד'),
                  selected: _overdueOnly,
                  selectedColor: AppTheme.red,
                  onSelected: (v) => setState(() => _overdueOnly = v),
                ),
                const SizedBox(width: 8),
                _menuChip<TaskCategory?>(
                  _catFilter?.titleHe ?? 'קטגוריה',
                  _catFilter,
                  [
                    const PopupMenuItem(value: null, child: Text('הכל')),
                    ...TaskCategory.values.map((c) =>
                        PopupMenuItem(value: c, child: Text(c.titleHe))),
                  ],
                  (v) => setState(() => _catFilter = v),
                ),
                const SizedBox(width: 8),
                _menuChip<TaskStatus?>(
                  _statusFilter?.titleHe ?? 'סטטוס',
                  _statusFilter,
                  [
                    const PopupMenuItem(value: null, child: Text('הכל')),
                    ...TaskStatus.values.map((s) =>
                        PopupMenuItem(value: s, child: Text(s.titleHe))),
                  ],
                  (v) => setState(() => _statusFilter = v),
                ),
                const SizedBox(width: 8),
                _menuChip<TaskPriority?>(
                  _priorityFilter?.titleHe ?? 'עדיפות',
                  _priorityFilter,
                  [
                    const PopupMenuItem(value: null, child: Text('הכל')),
                    ...TaskPriority.values.map((p) =>
                        PopupMenuItem(value: p, child: Text(p.titleHe))),
                  ],
                  (v) => setState(() => _priorityFilter = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: tasks.isEmpty
                ? const EmptyState(
                    icon: Icons.inbox,
                    message: 'לא נמצאו משימות',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80, top: 4),
                    itemCount: tasks.length,
                    itemBuilder: (_, i) {
                      final t = tasks[i];
                      return TaskTile(
                        task: t,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  TaskDetailsScreen(taskId: t.id)),
                        ),
                        onComplete: () => state.completeTask(t),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditTaskScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _menuChip<T>(String label, T value,
      List<PopupMenuEntry<T>> items, ValueChanged<T> onSelected) {
    return PopupMenuButton<T>(
      itemBuilder: (_) => items,
      onSelected: onSelected,
      color: AppTheme.surface,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 13)),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
    );
  }
}
