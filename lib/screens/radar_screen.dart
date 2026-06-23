import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/enums.dart';
import '../models/task.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import 'add_edit_task_screen.dart';
import 'category_screen.dart';

/// מסך הרדאר — מרכז עם "אני" וארבע כרטיסיות קטגוריה.
class RadarScreen extends StatelessWidget {
  const RadarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('רדאר התלויות הניהולי', style: TextStyle(fontSize: 18)),
            Text('לא רשימת משימות — ניהול תלויות בין אנשים',
                style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // שורת סיכום עליונה
              _summaryBar(context, state),
              const SizedBox(height: 12),
              // רשת 2x2 עם המרכז
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              // שמאל למעלה — אני מחכה להם
                              Expanded(
                                child: _CategoryCard(
                                  category: TaskCategory.waitingOnThem,
                                ),
                              ),
                              const SizedBox(width: 10),
                              // ימין למעלה — מחכים לי
                              Expanded(
                                child: _CategoryCard(
                                  category: TaskCategory.waitingOnMe,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Row(
                            children: [
                              // שמאל למטה — יום אחד / מוקפא
                              Expanded(
                                child: _CategoryCard(
                                  category: TaskCategory.parked,
                                ),
                              ),
                              const SizedBox(width: 10),
                              // ימין למטה — בטיפול פעיל
                              Expanded(
                                child: _CategoryCard(
                                  category: TaskCategory.active,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // מרכז "אני"
                    _meCircle(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const AddEditTaskScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('הוסף משימה'),
      ),
    );
  }

  Widget _summaryBar(BuildContext context, AppState state) {
    final overdue = state.overdueCount;
    final today = state.todayTasks.length;
    return Row(
      children: [
        Expanded(
          child: _statPill('באיחור', overdue, AppTheme.red),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statPill('להיום', today, AppTheme.accent),
        ),
      ],
    );
  }

  Widget _statPill(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$count',
              style: TextStyle(
                  color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _meCircle() {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.accent,
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 32, color: Color(0xFF1A1A1A)),
          Text('אני',
              style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ],
      ),
    );
  }
}

/// כרטיסיית קטגוריה ברדאר.
class _CategoryCard extends StatelessWidget {
  final TaskCategory category;
  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final count = state.openCountForCategory(category);
    final preview = state.previewForCategory(category, limit: 3);

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => CategoryScreen(category: category)),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: category.color, width: 1.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(category.icon, color: category.color, size: 22),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: category.color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$count',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AddEditTaskScreen(initialCategory: category),
                    ),
                  ),
                  child: Icon(Icons.add_circle,
                      color: category.color.withOpacity(0.8), size: 22),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(category.titleHe,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(category.titleEn,
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const Divider(height: 12),
            Expanded(
              child: preview.isEmpty
                  ? const Center(
                      child: Text('אין משימות',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.textSecondary)),
                    )
                  : ListView(
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      children: preview
                          .map((t) => _miniTask(t))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniTask(Task t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: t.isOverdue ? AppTheme.red : t.priority.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(t.title,
                style: const TextStyle(fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
