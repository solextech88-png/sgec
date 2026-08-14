import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session_provider.dart';
import 'programme_detail_screen.dart';

final universityDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final api = ref.read(apiClientProvider);
  return await api.get('/universities/$id') as Map<String, dynamic>;
});

class UniversityDetailScreen extends ConsumerWidget {
  final String universityId;
  const UniversityDetailScreen({super.key, required this.universityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(universityDetailProvider(universityId));

    return Scaffold(
      appBar: AppBar(title: const Text('University')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (u) {
          final programmes = (u['programmes'] as List? ?? []).cast<Map<String, dynamic>>();

          // Group by faculty so students can scan a large catalogue by
          // department instead of one long flat list. Programmes without a
          // faculty set (older seed data, or admin-added entries that
          // skipped it) fall into a plain "Other programmes" bucket rather
          // than being hidden.
          final Map<String, List<Map<String, dynamic>>> byFaculty = {};
          for (final p in programmes) {
            final faculty = (p['faculty'] as String?)?.trim();
            final key = (faculty == null || faculty.isEmpty) ? 'Other programmes' : faculty;
            byFaculty.putIfAbsent(key, () => []).add(p);
          }
          final facultyNames = byFaculty.keys.toList()..sort();

          Widget programmeTile(Map<String, dynamic> p) {
            return Card(
              child: ListTile(
                title: Text(p['name'] ?? ''),
                subtitle: Text(
                  '${p['level'] ?? ''} · ${p['durationMonths'] ?? '?'} months · '
                  '${p['tuitionFeeCurrency'] ?? ''} ${p['tuitionFeeAmount'] ?? ''}',
                ),
                trailing: p['isNextIntake'] == true
                    ? const Chip(label: Text('Next intake'))
                    : null,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProgrammeDetailScreen(
                        programme: p,
                        universityName: u['name'] ?? '',
                      ),
                    ),
                  );
                },
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(u['name'] ?? '', style: Theme.of(context).textTheme.headlineSmall),
              Text('${u['city'] ?? ''} · ${u['country']?['name'] ?? ''}'),
              const SizedBox(height: 16),
              Text('Programmes (${programmes.length})',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (facultyNames.length <= 1)
                // Only one group (or none) — no point showing a collapsed
                // section for a single faculty, just list them directly.
                ...programmes.map(programmeTile)
              else
                ...facultyNames.map((faculty) {
                  final items = byFaculty[faculty]!;
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: ExpansionTile(
                      title: Text(faculty, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${items.length} programme${items.length == 1 ? '' : 's'}'),
                      initiallyExpanded: true,
                      children: items.map(programmeTile).toList(),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
