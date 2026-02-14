import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/goals/goals_provider.dart';

class GoalCreatePage extends ConsumerStatefulWidget {
  const GoalCreatePage({super.key});

  @override
  ConsumerState<GoalCreatePage> createState() => _GoalCreatePageState();
}

class _GoalCreatePageState extends ConsumerState<GoalCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetController = TextEditingController();
  final _unitController = TextEditingController();

  GoalCategory _selectedCategory = GoalCategory.personal;
  ReminderFrequency _reminderFrequency = ReminderFrequency.daily;
  EscalationLevel _escalationLevel = EscalationLevel.pushOnly;
  DateTime? _deadline;
  TimeOfDay? _reminderTime;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final goal = await ref.read(goalsProvider.notifier).createGoal(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            category: _selectedCategory,
            targetValue: _targetController.text.isNotEmpty
                ? double.tryParse(_targetController.text)
                : null,
            unit: _unitController.text.trim().isEmpty
                ? null
                : _unitController.text.trim(),
            deadline: _deadline,
            reminderFrequency: _reminderFrequency,
            reminderTime: _reminderTime != null
                ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
                : null,
            escalationLevel: _escalationLevel,
          );

      if (goal != null && mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Goal created!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create goal: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('New Goal'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveGoal,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Goal Title',
                  hintText: 'e.g., Run 5km every day',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppTheme.spacingLg),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Add more details about your goal...',
                ),
              ),

              const SizedBox(height: AppTheme.spacingLg),

              // Category
              Text(
                'Category',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: GoalCategory.values.map((category) {
                  return ChoiceChip(
                    label: Text(category.displayName),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = category);
                      }
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: AppTheme.spacingXl),

              // Target and Unit
              Text(
                'Target (optional)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _targetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Target Value',
                        hintText: 'e.g., 10',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        hintText: 'e.g., km',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.spacingXl),

              // Deadline
              Text(
                'Deadline (optional)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.calendar_today, color: AppTheme.secondary),
                title: Text(
                  _deadline != null
                      ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                      : 'No deadline set',
                ),
                trailing: _deadline != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _deadline = null),
                      )
                    : null,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (date != null) {
                    setState(() => _deadline = date);
                  }
                },
              ),

              const SizedBox(height: AppTheme.spacingXl),

              // Reminder Settings
              Text(
                'Reminders',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              DropdownButtonFormField<ReminderFrequency>(
                value: _reminderFrequency,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                ),
                items: ReminderFrequency.values.map((freq) {
                  return DropdownMenuItem(
                    value: freq,
                    child: Text(freq.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _reminderFrequency = value);
                  }
                },
              ),

              if (_reminderFrequency != ReminderFrequency.none) ...[
                const SizedBox(height: AppTheme.spacingMd),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.access_time, color: AppTheme.secondary),
                  title: Text(
                    _reminderTime != null
                        ? _reminderTime!.format(context)
                        : 'Set reminder time',
                  ),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime:
                          _reminderTime ?? const TimeOfDay(hour: 9, minute: 0),
                    );
                    if (time != null) {
                      setState(() => _reminderTime = time);
                    }
                  },
                ),
              ],

              const SizedBox(height: AppTheme.spacingXl),

              // Escalation Level
              Text(
                'AI Accountability Level',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                'How persistent should the AI be?',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              ...EscalationLevel.values.map((level) {
                return RadioListTile<EscalationLevel>(
                  value: level,
                  groupValue: _escalationLevel,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _escalationLevel = value);
                    }
                  },
                  title: Text(level.displayName),
                  subtitle: Text(level.description),
                  contentPadding: EdgeInsets.zero,
                );
              }),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
