import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../app/providers.dart';
import '../../../core/design/tokens.dart';
import '../../auth/application/session_controller.dart';
import '../../legal/consent.dart';
import '../../profile/application/profile_controller.dart';
import '../application/settings_controller.dart';
import '../domain/app_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final settingsNotifier = ref.read(settingsControllerProvider.notifier);
    final profile = ref.watch(profileControllerProvider).profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: NGSpacing.xxxl),
        children: [
          _group(context, 'Profile', [
            ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: const Text('Profile & goals'),
              subtitle: Text(profile?.displayName ?? ''),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _editProfile(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.restaurant_menu_outlined),
              title: const Text('Diet preferences'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/diets'),
            ),
            ListTile(
              leading: const Icon(Icons.calculate_outlined),
              title: const Text('Nutrition targets'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/targets'),
            ),
          ]),
          _group(context, 'Preferences', [
            _ThemeTile(settings: settings, notifier: settingsNotifier),
            SwitchListTile(
              secondary: const Icon(Icons.straighten_rounded),
              title: const Text('Metric units'),
              subtitle: Text(
                settings.metricUnits ? 'kg, cm, ml' : 'lb, ft/in, fl oz',
              ),
              value: settings.metricUnits,
              onChanged: (v) =>
                  settingsNotifier.update(settings.copyWith(metricUnits: v)),
            ),
            if (profile != null)
              SwitchListTile(
                secondary: const Icon(Icons.monitor_weight_outlined),
                title: const Text('Hide weight features'),
                subtitle: const Text('Removes weight tracking and charts'),
                value: profile.hideWeightFeatures,
                onChanged: (v) => ref
                    .read(profileControllerProvider.notifier)
                    .saveProfile(
                      profile.copyWith(hideWeightFeatures: v),
                      recomputeTargets: false,
                    ),
              ),
          ]),
          _group(context, 'Notifications', [
            SwitchListTile(
              secondary: const Icon(Icons.lock_outline_rounded),
              title: const Text('Private notifications'),
              subtitle: const Text(
                'Hide diet and health details on the lock screen',
              ),
              value: settings.privateNotifications,
              onChanged: (v) => settingsNotifier.update(
                settings.copyWith(privateNotifications: v),
              ),
            ),
            _reminderTile(
              context,
              'Meal reminders',
              settings.mealReminders,
              (v) =>
                  settingsNotifier.update(settings.copyWith(mealReminders: v)),
            ),
            _reminderTile(
              context,
              'Water reminders',
              settings.waterReminders,
              (v) =>
                  settingsNotifier.update(settings.copyWith(waterReminders: v)),
            ),
            _reminderTile(
              context,
              'Fasting reminders',
              settings.fastingReminders,
              (v) => settingsNotifier.update(
                settings.copyWith(fastingReminders: v),
              ),
            ),
            _reminderTile(
              context,
              'Grocery reminders',
              settings.groceryReminders,
              (v) => settingsNotifier.update(
                settings.copyWith(groceryReminders: v),
              ),
            ),
            _reminderTile(
              context,
              'Weekly progress summary',
              settings.weeklySummary,
              (v) =>
                  settingsNotifier.update(settings.copyWith(weeklySummary: v)),
            ),
            _reminderTile(
              context,
              'Habit reminders',
              settings.habitReminders,
              (v) =>
                  settingsNotifier.update(settings.copyWith(habitReminders: v)),
            ),
          ]),
          _group(context, 'AI & data', [
            ListTile(
              leading: const Icon(Icons.forum_outlined),
              title: const Text('AI data controls'),
              subtitle: const Text('History, transparency, deletion'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/coach/info'),
            ),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Export my data'),
              onTap: () => _exportData(context, ref),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_forever_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Delete account',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              subtitle: const Text('Permanently deletes your account and data'),
              onTap: () => _deleteAccount(context, ref),
            ),
          ]),
          _group(context, 'Privacy & safety', [
            _legalTile(context, 'Privacy Policy', 'privacy'),
            _legalTile(context, 'Terms of Service', 'terms'),
            _legalTile(context, 'Wellness & Medical Disclaimer', 'disclaimer'),
            _legalTile(context, 'AI Transparency Notice', 'ai-transparency'),
            _legalTile(context, 'Acceptable Use Policy', 'acceptable-use'),
            _legalTile(context, 'Data Retention Policy', 'data-retention'),
            _legalTile(context, 'Account Deletion', 'account-deletion'),
          ]),
          _group(context, 'Support', [
            _legalTile(context, 'Support & complaints', 'support'),
            const _VersionTile(),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Open-source licenses'),
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'NutriGuide AI',
              ),
            ),
          ]),
          const Padding(
            padding: EdgeInsets.all(NGSpacing.lg),
            child: Text(
              Consent.productStatement,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ),
          Center(
            child: TextButton.icon(
              onPressed: () =>
                  ref.read(sessionControllerProvider.notifier).signOut(),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _group(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            NGSpacing.lg,
            NGSpacing.xl,
            NGSpacing.lg,
            NGSpacing.sm,
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _reminderTile(
    BuildContext context,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) => SwitchListTile(
    contentPadding: const EdgeInsets.only(left: 56, right: NGSpacing.lg),
    title: Text(title),
    value: value,
    onChanged: onChanged,
  );

  Widget _legalTile(BuildContext context, String title, String doc) => ListTile(
    leading: const Icon(Icons.article_outlined),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: () => context.push('/legal/$doc'),
  );

  Future<void> _editProfile(BuildContext context, WidgetRef ref) async {
    final profile = ref.read(profileControllerProvider).profile;
    if (profile == null) return;
    final nameController = TextEditingController(text: profile.displayName);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: NGSpacing.lg,
          right: NGSpacing.lg,
          top: NGSpacing.sm,
          bottom: MediaQuery.of(context).viewInsets.bottom + NGSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit profile', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: NGSpacing.md),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Preferred name'),
            ),
            const SizedBox(height: NGSpacing.md),
            Text(
              'To change body metrics, activity or goals, tap through — your '
              'targets recalculate automatically and ask before big changes.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: NGSpacing.lg),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) {
      await ref
          .read(profileControllerProvider.notifier)
          .saveProfile(
            profile.copyWith(displayName: nameController.text.trim()),
            recomputeTargets: false,
          );
    }
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final json = await ref.read(accountServiceProvider).exportJson();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your data'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              json.length > 4000 ? '${json.substring(0, 4000)}\n…' : json,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final passwordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This permanently deletes your account and all associated '
              'data. This cannot be undone. Re-enter your password to '
              'confirm it is you.',
            ),
            const SizedBox(height: NGSpacing.md),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(accountServiceProvider)
          .deleteAccount(password: passwordController.text);
      ref.read(sessionControllerProvider.notifier).markSignedOut();
      ref.invalidate(profileControllerProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not delete account: $e')));
      }
    }
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({required this.settings, required this.notifier});
  final AppSettings settings;
  final SettingsController notifier;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.brightness_6_outlined),
      title: const Text('Appearance'),
      trailing: DropdownButton<ThemeMode>(
        value: settings.themeMode,
        underline: const SizedBox.shrink(),
        onChanged: (mode) {
          if (mode != null) {
            notifier.update(settings.copyWith(themeMode: mode));
          }
        },
        items: const [
          DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
          DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
          DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
        ],
      ),
    );
  }
}

class _VersionTile extends StatelessWidget {
  const _VersionTile();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.hasData
            ? '${snapshot.data!.version} (${snapshot.data!.buildNumber})'
            : '—';
        return ListTile(
          leading: const Icon(Icons.info_outline_rounded),
          title: const Text('App version'),
          subtitle: Text(version),
        );
      },
    );
  }
}
