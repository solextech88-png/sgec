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
          final programmes = (u['programmes'] as List? ?? []);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(u['name'] ?? '', style: Theme.of(context).textTheme.headlineSmall),
              Text('${u['city'] ?? ''} · ${u['country']?['name'] ?? ''}'),
              const SizedBox(height: 16),
              Text('Programmes (${programmes.length})',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...programmes.map((p) => Card(
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
                              programme: p as Map<String, dynamic>,
                              universityName: u['name'] ?? '',
                            ),
                          ),
                        );
                      },
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}
