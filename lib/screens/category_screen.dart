import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/enums.dart';
import '../models/task.dart';
import '../services/app_state.dart';
import '../services/communication_service.dart';
import '../theme/app_theme.dart';
import '../widgets/task_tile.dart';
import '../widgets/empty_state.dart';
import 'add_edit_task_screen.dart';
import 'task_details_screen.dart';

class CategoryScreen extends StatefulWidget {
  final TaskCategory category;
  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

enum _SortBy { dueDate, priority }

class _CategoryScreenState extends State<CategoryScreen> {
  String _search = '';
  TaskStatus? _statusFilter;
  TaskPriority? _priorityFilter;
  _SortBy _sortBy = _SortBy.dueDate;

  List<Task> _apply(List<Task> tasks) {
    var list = tasks.where((t) {
      if (_search.isNotEmpty &&
          !t.title.toLowerCase().contains(_search.toLowerCase()) &&
          !t.description.toLowerCase().contains(_search.toLowerCase())) {
        return false;
      }
      if (_statusFilter != null && t.status != _statusFilter) return false;
      if (_priorityFilter != null && t.priority != _priorityFilter) {
        return false;
      }
      return true;
    }).toList();

    list.sort((a, b) {
      // איחור תמיד בראש
      if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
      if (_sortBy == _SortBy.priority) {
        return b.priority.weight.compareTo(a.priority.weight);
      } else {
        final ad = a.effectiveDueDateTime;
        final bd = b.effectiveDueDateTime;
        if (ad != null && bd != null) return ad.compareTo(bd);
        if (ad != null) return -1;
        if (bd != null) return 1;
        return 0;
      }
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cat = widget.category;
    final showCompleted = state.settings.showCompletedTasks;
    final raw = state.tasksForCategory(cat, includeCompleted: showCompleted);
    final tasks = _apply(raw);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(cat.icon, color: cat.color),
            const SizedBox(width: 8),
            Text(cat.titleHe),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'חיפוש משימות...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          _filterBar(),
          Expanded(
            child: tasks.isEmpty
                ? EmptyState(
                    icon: cat.icon,
                    message: 'אין משימות בקטגוריה "${cat.titleHe}"',
                    actionLabel: 'הוסף משימה',
                    onAction: () => _addTask(context, cat),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80, top: 4),
                    itemCount: tasks.length,
                    itemBuilder: (_, i) => _swipeable(context, state, tasks[i]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTask(context, cat),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _filterBar() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _dropdownChip<TaskStatus?>(
            label: _statusFilter?.titleHe ?? 'סטטוס',
            value: _statusFilter,
            items: [
              const DropdownMenuItem(value: null, child: Text('כל הסטטוסים')),
              ...TaskStatus.values.map(
                  (s) => DropdownMenuItem(value: s, child: Text(s.titleHe))),
            ],
            onChanged: (v) => setState(() => _statusFilter = v),
          ),
          const SizedBox(width: 8),
          _dropdownChip<TaskPriority?>(
            label: _priorityFilter?.titleHe ?? 'עדיפות',
            value: _priorityFilter,
            items: [
              const DropdownMenuItem(value: null, child: Text('כל העדיפויות')),
              ...TaskPriority.values.map(
                  (p) => DropdownMenuItem(value: p, child: Text(p.titleHe))),
            ],
            onChanged: (v) => setState(() => _priorityFilter = v),
          ),
          const SizedBox(width: 8),
          _dropdownChip<_SortBy>(
            label: _sortBy == _SortBy.dueDate ? 'מיון: תאריך' : 'מיון: עדיפות',
            value: _sortBy,
            items: const [
              DropdownMenuItem(
                  value: _SortBy.dueDate, child: Text('מיון לפי תאריך')),
              DropdownMenuItem(
                  value: _SortBy.priority, child: Text('מיון לפי עדיפות')),
            ],
            onChanged: (v) => setState(() => _sortBy = v!),
          ),
        ],
      ),
    );
  }

  Widget _dropdownChip<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          dropdownColor: AppTheme.surface,
          hint: Text(label, style: const TextStyle(fontSize: 13)),
          icon: const Icon(Icons.arrow_drop_down, size: 18),
          items: items,
          onChanged: onChanged,
          selectedItemBuilder: (_) =>
              items.map((e) => Center(child: Text(label, style: const TextStyle(fontSize: 13)))).toList(),
        ),
      ),
    );
  }

  Widget _swipeable(BuildContext context, AppState state, Task task) {
    return Dismissible(
      key: ValueKey(task.id),
      background: _swipeBg(Alignment.centerRight, Icons.swap_horiz, 'העבר'),
      secondaryBackground:
          _swipeBg(Alignment.centerLeft, Icons.check, 'הושלם'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // סימון הושלם
          await state.completeTask(task);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('המשימה סומנה כהושלמה')));
          }
          return false; // לא להסיר פיזית — הרשימה תתעדכן
        } else {
          // העברת קטגוריה
          await _showMoveDialog(context, state, task);
          return false;
        }
      },
      child: TaskTile(
        task: task,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => TaskDetailsScreen(taskId: task.id)),
        ),
        onComplete: () => state.completeTask(task),
        onCall: task.contactPhone != null
            ? () => CommunicationService.call(task.contactPhone!)
            : null,
      ),
    );
  }

  Widget _swipeBg(Alignment alignment, IconData icon, String label) {
    return Container(
      color: alignment == Alignment.centerLeft
          ? AppTheme.green
          : AppTheme.blue,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Future<void> _showMoveDialog(
      BuildContext context, AppState state, Task task) async {
    final newCat = await showDialog<TaskCategory>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('העבר לקטגוריה'),
        children: TaskCategory.values
            .where((c) => c != task.category)
            .map((c) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, c),
                  child: Row(
                    children: [
                      Icon(c.icon, color: c.color),
                      const SizedBox(width: 12),
                      Text(c.titleHe),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
    if (newCat != null) {
      await state.changeCategory(task, newCat);
    }
  }

  void _addTask(BuildContext context, TaskCategory cat) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => AddEditTaskScreen(initialCategory: cat)),
    );
  }
}
