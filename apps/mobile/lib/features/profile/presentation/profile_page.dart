import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:geoattend_employee/core/services/app_services.dart';
import 'package:geoattend_employee/core/theme/app_colors.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mobileOverviewProvider);
    return Scaffold(
      backgroundColor: dashboardBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Profile',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ProfileError(
            onRetry: () => ref.invalidate(mobileOverviewProvider)),
        data: (overview) {
          final employee = overview.employee;
          final initials = employee.name
              .split(' ')
              .where((part) => part.isNotEmpty)
              .take(2)
              .map((part) => part[0])
              .join();
          return RefreshIndicator(
            onRefresh: () => ref.refresh(mobileOverviewProvider.future),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
              children: [
                Center(
                  child: Column(children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: const Color(0xffdbeafe),
                      child: Text(initials,
                          style: const TextStyle(
                              color: dashboardBlue,
                              fontSize: 22,
                              fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 12),
                    Text(employee.name,
                        style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            color: dashboardText)),
                    const SizedBox(height: 4),
                    Text(
                        '${employee.employeeNumber} · ${employee.department ?? 'Employee'}',
                        style: const TextStyle(color: dashboardMuted)),
                  ]),
                ),
                const SizedBox(height: 28),
                _ProfileCard(children: [
                  _ProfileRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: employee.email),
                  _ProfileRow(
                      icon: Icons.badge_outlined,
                      label: 'Role',
                      value: employee.role),
                  _ProfileRow(
                      icon: Icons.business_outlined,
                      label: 'Worksite',
                      value: employee.worksite?.name ?? 'Not assigned'),
                ]),
                const SizedBox(height: 16),
                _ProfileCard(children: [
                  ListTile(
                    leading: const Icon(Icons.phonelink_lock_outlined),
                    title: const Text('Device registration'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/device-registration'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: const Text('Notifications'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/notifications'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.fact_check_outlined),
                    title: const Text('Reports & readiness'),
                    subtitle: const Text('Phases 7–9 status'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/readiness'),
                  ),
                ]),
                const SizedBox(height: 22),
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authControllerProvider.notifier).logout();
                    ref.invalidate(mobileOverviewProvider);
                    if (context.mounted) context.go('/login');
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Log Out'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xffe2e8f0))),
        child: Column(children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index < children.length - 1)
              const Divider(height: 1, indent: 58),
          ]
        ]),
      );
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: dashboardBlue),
        title: Text(label,
            style: const TextStyle(fontSize: 12, color: dashboardMuted)),
        subtitle: Text(value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: dashboardText)),
      );
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_rounded, size: 42, color: dashboardMuted),
        const SizedBox(height: 12),
        const Text('Could not load your profile.'),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ]));
}
