import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../home/home_shell.dart';

/// The safety module a caregiver completes before receiving requests. Shows the
/// safety badge once finished. (FR-CM-4)
class SafetyModuleScreen extends ConsumerStatefulWidget {
  const SafetyModuleScreen({super.key});

  static const String route = '/safety-module';

  @override
  ConsumerState<SafetyModuleScreen> createState() => _SafetyModuleScreenState();
}

class _SafetyModuleScreenState extends ConsumerState<SafetyModuleScreen> {
  static const List<_Lesson> _lessons = [
    _Lesson(
      Icons.health_and_safety_outlined,
      'Know your limits',
      'You are not a medical professional. Never give medication, injections '
          'or clinical treatment. Stay within the tasks the care seeker allowed.',
    ),
    _Lesson(
      Icons.domain_outlined,
      'Respect boundaries',
      'Follow the boundary checklist for every visit. Stay out of any room the '
          'care seeker marked as off limits.',
    ),
    _Lesson(
      Icons.emergency_outlined,
      'Use the safety button',
      'At arrival you hand the physical safety button to the care seeker. If '
          'you feel unsafe at any time, use Report or SOS. It ends the session '
          'and notifies support immediately.',
    ),
    _Lesson(
      Icons.lock_outline,
      'Protect privacy',
      'Keep the care seeker\'s details private. Never share their location, '
          'contact details or the visit with anyone outside the platform.',
    ),
  ];

  bool _busy = false;

  Future<void> _complete() async {
    setState(() => _busy = true);
    await ref.read(platformProvider).completeSafetyModule();
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    context.go(HomeShell.route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Safety module')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Four things every caregiver should know.',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ..._lessons.map(
              (lesson) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(lesson.icon, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lesson.title,
                                style: theme.textTheme.titleSmall),
                            const SizedBox(height: 4),
                            Text(lesson.body,
                                style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy ? null : _complete,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Complete the module'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Lesson {
  const _Lesson(this.icon, this.title, this.body);

  final IconData icon;
  final String title;
  final String body;
}
