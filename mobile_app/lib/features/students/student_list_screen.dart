import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session_provider.dart';
import 'student_detail_screen.dart';

final allStudentsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  return await api.get('/students') as List<dynamic>;
});

/// Shared between the consultant and admin dashboards — both roles hit the
/// same GET /students endpoint on the backend, so one screen covers both
/// rather than maintaining two near-identical copies.
class StudentListScreen extends ConsumerWidget {
  const StudentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(allStudentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      body: studentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (students) {
          if (students.isEmpty) {
            return const Center(child: Text('No students registered yet.'));
          }
          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, i) {
              final s = students[i];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text('${s['firstName'] ?? ''} ${s['lastName'] ?? ''}'),
                subtitle: Text(s['user']?['email'] ?? s['user']?['phone'] ?? ''),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => StudentDetailScreen(studentId: s['id'])),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
