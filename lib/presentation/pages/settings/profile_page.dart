import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth/auth_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _displayNameController = TextEditingController();
  bool _isEditing = false;
  TimeOfDay? _quietHoursStart;
  TimeOfDay? _quietHoursEnd;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final profile = ref.read(currentProfileProvider);
    if (profile != null) {
      _displayNameController.text = profile.displayName ?? '';

      if (profile.defaultQuietHoursStart != null) {
        final parts = profile.defaultQuietHoursStart!.split(':');
        _quietHoursStart = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
      if (profile.defaultQuietHoursEnd != null) {
        final parts = profile.defaultQuietHoursEnd!.split(':');
        _quietHoursEnd = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _selectQuietHours() async {
    final start = await showTimePicker(
      context: context,
      initialTime: _quietHoursStart ?? const TimeOfDay(hour: 22, minute: 0),
      helpText: 'Select quiet hours start',
    );

    if (start != null && mounted) {
      final end = await showTimePicker(
        context: context,
        initialTime: _quietHoursEnd ?? const TimeOfDay(hour: 8, minute: 0),
        helpText: 'Select quiet hours end',
      );

      if (end != null) {
        setState(() {
          _quietHoursStart = start;
          _quietHoursEnd = end;
        });
      }
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _saveProfile() async {
    await ref.read(authProvider.notifier).updateProfile(
          displayName: _displayNameController.text.trim().isEmpty
              ? null
              : _displayNameController.text.trim(),
          defaultQuietHoursStart: _quietHoursStart != null
              ? _formatTimeOfDay(_quietHoursStart!)
              : null,
          defaultQuietHoursEnd: _quietHoursEnd != null
              ? _formatTimeOfDay(_quietHoursEnd!)
              : null,
        );

    if (mounted) {
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _saveProfile,
              child: const Text('Save'),
            )
          else
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              child: const Text('Edit'),
            ),
        ],
      ),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              children: [
                // Avatar
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppTheme.surfaceVariant,
                        child: Text(
                          profile.initials,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppTheme.secondary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.spacingLg),

                // Email (non-editable)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email'),
                  subtitle: Text(profile.email ?? 'Not set'),
                ),

                const Divider(),

                // Display name
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Display Name'),
                  subtitle: _isEditing
                      ? TextField(
                          controller: _displayNameController,
                          decoration: const InputDecoration(
                            hintText: 'Enter your name',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        )
                      : Text(profile.displayName ?? 'Not set'),
                ),

                const Divider(),

                // Default quiet hours
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.nights_stay_outlined),
                  title: const Text('Default Quiet Hours'),
                  subtitle: Text(
                    _quietHoursStart != null && _quietHoursEnd != null
                        ? '${_quietHoursStart!.format(context)} - ${_quietHoursEnd!.format(context)}'
                        : 'Not set (AI calls allowed anytime)',
                  ),
                  trailing: _isEditing
                      ? const Icon(Icons.chevron_right)
                      : null,
                  onTap: _isEditing ? _selectQuietHours : null,
                ),

                const Divider(),

                // Preferred voice
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.record_voice_over_outlined),
                  title: const Text('Preferred AI Voice'),
                  subtitle: Text(profile.preferredVoice ?? 'Default'),
                  trailing: _isEditing
                      ? const Icon(Icons.chevron_right)
                      : null,
                  onTap: _isEditing
                      ? () {
                          // TODO: Voice selection
                        }
                      : null,
                ),

                const Divider(),

                // Notifications enabled
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('Push Notifications'),
                  value: profile.notificationsEnabled,
                  onChanged: _isEditing
                      ? (value) {
                          ref.read(authProvider.notifier).updateProfile(
                                notificationsEnabled: value,
                              );
                        }
                      : null,
                  activeColor: AppTheme.secondary,
                ),

                // AI Calls enabled
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.phone_outlined),
                  title: const Text('AI Calls'),
                  subtitle: const Text('Allow AI to call for missed goals'),
                  value: profile.aiCallsEnabled,
                  onChanged: _isEditing
                      ? (value) {
                          ref.read(authProvider.notifier).updateProfile(
                                aiCallsEnabled: value,
                              );
                        }
                      : null,
                  activeColor: AppTheme.secondary,
                ),

                const SizedBox(height: AppTheme.spacingXl),

                // AI Insights section
                Text(
                  'AI Insights',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppTheme.spacingMd),

                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (profile.aiPersonalitySummary != null) ...[
                        _InsightRow(
                          label: 'Personality',
                          value: profile.aiPersonalitySummary!,
                        ),
                        const Divider(),
                      ],
                      if (profile.aiCommunicationStyle != null) ...[
                        _InsightRow(
                          label: 'Communication Style',
                          value: profile.aiCommunicationStyle!,
                        ),
                        const Divider(),
                      ],
                      if (profile.aiProductivityPatterns != null) ...[
                        _InsightRow(
                          label: 'Productivity Patterns',
                          value: profile.aiProductivityPatterns!,
                        ),
                      ],
                      if (profile.aiPersonalitySummary == null &&
                          profile.aiCommunicationStyle == null &&
                          profile.aiProductivityPatterns == null)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.spacingMd),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 32,
                                  color: AppTheme.textTertiary,
                                ),
                                const SizedBox(height: AppTheme.spacingSm),
                                Text(
                                  'Journal more to unlock AI insights',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final String label;
  final String value;

  const _InsightRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
