import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:geoattend_employee/core/services/app_services.dart';
import 'package:geoattend_employee/core/theme/app_colors.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mobileOverviewProvider);
    return Scaffold(
      backgroundColor: dashboardBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
            child: TextButton(
                onPressed: () => ref.invalidate(mobileOverviewProvider),
                child: const Text('Retry loading notifications'))),
        data: (overview) => overview.notifications.isEmpty
            ? const Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.notifications_none_rounded,
                    size: 48, color: dashboardMuted),
                SizedBox(height: 10),
                Text('No notifications yet',
                    style: TextStyle(color: dashboardMuted))
              ]))
            : RefreshIndicator(
                onRefresh: () => ref.refresh(mobileOverviewProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: overview.notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = overview.notifications[index];
                    return Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xffe2e8f0))),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                    color: Color(0xffdbeafe),
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.notifications_rounded,
                                    size: 20, color: dashboardBlue)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(item.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: dashboardText)),
                                  const SizedBox(height: 4),
                                  Text(item.body,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          height: 1.4,
                                          color: dashboardMuted)),
                                  const SizedBox(height: 7),
                                  Text(_relative(item.createdAt),
                                      style: const TextStyle(
                                          fontSize: 10, color: dashboardMuted))
                                ])),
                            if (item.readAt == null)
                              Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                      color: dashboardBlue,
                                      shape: BoxShape.circle)),
                          ]),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

String _relative(DateTime date) {
  final difference = DateTime.now().difference(date);
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes.clamp(1, 59)}m ago';
  }
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  return '${difference.inDays}d ago';
}
