import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/enums.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart' as du;

/// שורת משימה אחת ברשימה.
class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onCall;

  const TaskTile({
    super.key,
    required this.task,
    required this.onTap,
    this.onComplete,
    this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final overdue = task.isOverdue;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // פס עדיפות צבעוני
              Container(
                width: 5,
                height: 50,
                decoration: BoxDecoration(
                  color: task.priority.color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              decoration: task.status == TaskStatus.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (task.reminderDateTime != null)
                          const Icon(Icons.notifications_active,
                              size: 16, color: AppTheme.textSecondary),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _chip(task.priority.titleHe, task.priority.color),
                        _chip(task.status.titleHe, AppTheme.surfaceLight,
                            textColor: AppTheme.textSecondary),
                        if (task.dueDate != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.event,
                                  size: 13,
                                  color: overdue
                                      ? AppTheme.red
                                      : AppTheme.textSecondary),
                              const SizedBox(width: 3),
                              Text(
                                du.DateUtils.relativeLabel(task.dueDate),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: overdue
                                      ? AppTheme.red
                                      : AppTheme.textSecondary,
                                  fontWeight: overdue
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        if (task.contactName != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person,
                                  size: 13, color: AppTheme.textSecondary),
                              const SizedBox(width: 3),
                              Text(task.contactName!,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary)),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onComplete != null &&
                  task.status != TaskStatus.completed)
                IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  color: AppTheme.green,
                  tooltip: 'סמן כהושלם',
                  onPressed: onComplete,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color, {Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor ?? color,
        ),
      ),
    );
  }
}
