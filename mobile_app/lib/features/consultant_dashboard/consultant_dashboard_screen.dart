import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/session_provider.dart';

final consultantStudentsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  return await api.get('/students') as List<dynamic>;
});

final consultantApplicationsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  return await api.get('/applications') as List<dynamic>;
});

/// Centralized dashboard for consultants: review students' documents,
/// recommend/prepare/submit applications, and track decisions. This is a
/// working list view against the real API — the deeper per-student review
/// workflow (approving documents, drafting recommendations) hangs off
/// the student-detail screen this pushes to (TODO: build that screen using
/// GET /students/:id, which already returns documents + consent + applications).
class ConsultantDashboardScreen extends ConsumerStatefulWidget {
  const ConsultantDashboardScreen({super.key});
  @override
  ConsumerState<ConsultantDashboardScreen> createState() => _ConsultantDashboardScreenState();
}

class _ConsultantDashboardScreenState extends ConsumerState<ConsultantDashboardScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultant dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(sessionProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _tabButton('Students', 0),
              const SizedBox(width: 16),
              _tabButton('Applications', 1),
            ],
          ),
        ),
      ),
      body: _tab == 0 ? const _StudentsTab() : const _ApplicationsTab(),
    );
  }

  Widget _tabButton(String label, int index) {
    final selected = _tab == index;
    return TextButton(
      onPressed: () => setState(() => _tab = index),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.white70,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _StudentsTab extends ConsumerWidget {
  const _StudentsTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(consultantStudentsProvider);
    return studentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load: $e')),
      data: (students) => ListView.builder(
        itemCount: students.length,
        itemBuilder: (context, i) {
          final s = students[i];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text('${s['firstName']} ${s['lastName']}'),
            subtitle: Text(s['user']?['email'] ?? s['user']?['phone'] ?? ''),
            onTap: () {
              // TODO: push StudentDetailScreen(studentId: s['id'])
            },
          );
        },
      ),
    );
  }
}

class _ApplicationsTab extends ConsumerWidget {
  const _ApplicationsTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(consultantApplicationsProvider);
    return appsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load: $e')),
      data: (apps) => ListView.builder(
        itemCount: apps.length,
        itemBuilder: (context, i) {
          final a = apps[i];
          return ListTile(
            title: Text(a['programme']?['name'] ?? ''),
            subtitle: Text('${a['student']?['user']?['email'] ?? ''} · ${a['status']}'),
          );
        },
      ),
    );
  }
}
