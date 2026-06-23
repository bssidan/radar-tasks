import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/enums.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart' as du;

/// מסך הוספה/עריכה של משימה.
class AddEditTaskScreen extends StatefulWidget {
  final Task? existing;
  final TaskCategory? initialCategory;

  const AddEditTaskScreen({super.key, this.existing, this.initialCategory});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _contactNameCtrl;
  late TextEditingController _contactPhoneCtrl;
  late TextEditingController _contactEmailCtrl;
  late TextEditingController _contactRoleCtrl;
  late TextEditingController _tagsCtrl;

  late TaskCategory _category;
  TaskPriority _priority = TaskPriority.normal;
  TaskStatus _status = TaskStatus.open;
  DateTime? _dueDate;
  int? _dueTimeMinutes;
  ReminderType _reminderType = ReminderType.none;
  DateTime? _customReminder;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _notesCtrl = TextEditingController(text: t?.notes ?? '');
    _contactNameCtrl = TextEditingController(text: t?.contactName ?? '');
    _contactPhoneCtrl = TextEditingController(text: t?.contactPhone ?? '');
    _contactEmailCtrl = TextEditingController(text: t?.contactEmail ?? '');
    _contactRoleCtrl = TextEditingController(text: t?.contactRole ?? '');
    _tagsCtrl = TextEditingController(text: t?.tags.join(', ') ?? '');

    _category = t?.category ??
        widget.initialCategory ??
        context.read<AppState>().settings.defaultCategory;
    _priority = t?.priority ?? TaskPriority.normal;
    _status = t?.status ?? TaskStatus.open;
    _dueDate = t?.dueDate;
    _dueTimeMinutes = t?.dueTimeMinutes;
    _reminderType = t?.reminderType ?? ReminderType.none;
    _customReminder =
        t?.reminderType == ReminderType.custom ? t?.reminderDateTime : null;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _notesCtrl.dispose();
    _contactNameCtrl.dispose();
    _contactPhoneCtrl.dispose();
    _contactEmailCtrl.dispose();
    _contactRoleCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickTime() async {
    final init = _dueTimeMinutes != null
        ? TimeOfDay(hour: _dueTimeMinutes! ~/ 60, minute: _dueTimeMinutes! % 60)
        : TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: init);
    if (picked != null) {
      setState(() => _dueTimeMinutes = picked.hour * 60 + picked.minute);
    }
  }

  Future<void> _pickCustomReminder() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _customReminder ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_customReminder ?? now),
    );
    if (time == null) return;
    setState(() {
      _customReminder =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final state = context.read<AppState>();
    final tags = _tagsCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    try {
      if (isEditing) {
        final old = widget.existing!;
        final updated = old.copyWith(
          title: _titleCtrl.text,
          description: _descCtrl.text,
          category: _category,
          priority: _priority,
          status: _status,
          dueDate: _dueDate,
          clearDueDate: _dueDate == null,
          dueTimeMinutes: _dueTimeMinutes,
          clearDueTime: _dueTimeMinutes == null,
          notes: _notesCtrl.text,
          tags: tags,
          contactName: _contactNameCtrl.text,
          contactPhone: _contactPhoneCtrl.text,
          contactEmail: _contactEmailCtrl.text,
          contactRole: _contactRoleCtrl.text,
        );
        await state.updateTask(old, updated,
            reminderType: _reminderType, customReminder: _customReminder);
        if (mounted) {
          _showSnack('המשימה עודכנה בהצלחה');
          Navigator.pop(context, true);
        }
      } else {
        await state.addTask(
          title: _titleCtrl.text,
          description: _descCtrl.text,
          category: _category,
          priority: _priority,
          status: _status,
          dueDate: _dueDate,
          dueTimeMinutes: _dueTimeMinutes,
          reminderType: _reminderType,
          customReminder: _customReminder,
          contactName: _contactNameCtrl.text,
          contactPhone: _contactPhoneCtrl.text,
          contactEmail: _contactEmailCtrl.text,
          contactRole: _contactRoleCtrl.text,
          notes: _notesCtrl.text,
          tags: tags,
        );
        if (mounted) {
          _showSnack('המשימה נשמרה בהצלחה');
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) _showSnack('שגיאה בשמירה: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'עריכת משימה' : 'משימה חדשה'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('שמור',
                style: TextStyle(
                    color: AppTheme.accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'כותרת משימה *',
                prefixIcon: Icon(Icons.title),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'יש להזין כותרת' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'תיאור',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _sectionLabel('קטגוריה'),
            _categorySelector(),
            const SizedBox(height: 16),
            _sectionLabel('עדיפות'),
            _prioritySelector(),
            const SizedBox(height: 16),
            _sectionLabel('סטטוס'),
            _statusSelector(),
            const SizedBox(height: 16),
            _sectionLabel('תאריך ושעת יעד'),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(_dueDate == null
                        ? 'בחר תאריך'
                        : du.DateUtils.formatDate(_dueDate)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time, size: 18),
                    label: Text(_dueTimeMinutes == null
                        ? 'בחר שעה'
                        : du.DateUtils.formatTime(_dueTimeMinutes)),
                  ),
                ),
                if (_dueDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => setState(() {
                      _dueDate = null;
                      _dueTimeMinutes = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _sectionLabel('תזכורת'),
            DropdownButtonFormField<ReminderType>(
              value: _reminderType,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.notifications),
              ),
              items: ReminderType.values
                  .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(r.titleHe),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _reminderType = v!),
            ),
            if (_reminderType == ReminderType.custom) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickCustomReminder,
                icon: const Icon(Icons.schedule, size: 18),
                label: Text(_customReminder == null
                    ? 'בחר מועד תזכורת'
                    : du.DateUtils.formatDateTime(_customReminder)),
              ),
            ],
            const SizedBox(height: 16),
            _sectionLabel('איש קשר רלוונטי'),
            TextFormField(
              controller: _contactNameCtrl,
              decoration: const InputDecoration(
                labelText: 'שם',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contactPhoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'טלפון',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contactEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'אימייל',
                prefixIcon: Icon(Icons.email),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim());
                return ok ? null : 'אימייל לא תקין';
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contactRoleCtrl,
              decoration: const InputDecoration(
                labelText: 'תפקיד / הקשר',
                prefixIcon: Icon(Icons.badge),
              ),
            ),
            const SizedBox(height: 16),
            _sectionLabel('נוסף'),
            TextFormField(
              controller: _tagsCtrl,
              decoration: const InputDecoration(
                labelText: 'תגיות (מופרדות בפסיק)',
                prefixIcon: Icon(Icons.label),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'הערות / עדכון אחרון',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: Text(isEditing ? 'עדכן משימה' : 'שמור משימה'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
                fontSize: 13)),
      );

  Widget _categorySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TaskCategory.values.map((c) {
        final selected = _category == c;
        return ChoiceChip(
          label: Text(c.titleHe),
          avatar: Icon(c.icon,
              size: 18, color: selected ? Colors.white : c.color),
          selected: selected,
          selectedColor: c.color,
          backgroundColor: AppTheme.surfaceLight,
          labelStyle: TextStyle(
              color: selected ? Colors.white : AppTheme.textPrimary),
          onSelected: (_) => setState(() => _category = c),
        );
      }).toList(),
    );
  }

  Widget _prioritySelector() {
    return Wrap(
      spacing: 8,
      children: TaskPriority.values.map((p) {
        final selected = _priority == p;
        return ChoiceChip(
          label: Text(p.titleHe),
          selected: selected,
          selectedColor: p.color,
          backgroundColor: AppTheme.surfaceLight,
          labelStyle: TextStyle(
              color: selected ? Colors.white : AppTheme.textPrimary),
          onSelected: (_) => setState(() => _priority = p),
        );
      }).toList(),
    );
  }

  Widget _statusSelector() {
    return Wrap(
      spacing: 8,
      children: TaskStatus.values.map((s) {
        final selected = _status == s;
        return ChoiceChip(
          label: Text(s.titleHe),
          selected: selected,
          selectedColor: AppTheme.blue,
          backgroundColor: AppTheme.surfaceLight,
          labelStyle: TextStyle(
              color: selected ? Colors.white : AppTheme.textPrimary),
          onSelected: (_) => setState(() => _status = s),
        );
      }).toList(),
    );
  }
}
