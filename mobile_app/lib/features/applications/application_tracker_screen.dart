import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session_provider.dart';

final myApplicationsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  return await api.get('/applications/mine') as List<dynamic>;
});

const _statusOrder = [
  'DRAFT', 'AI_REVIEWED', 'CONSULTANT_REVIEWED', 'SUBMITTED',
  'UNDER_REVIEW_BY_UNIVERSITY', 'OFFER_CONDITIONAL', 'OFFER_UNCONDITIONAL',
  'DEPOSIT_PAID', 'CAS_ISSUED', 'VISA_APPLIED', 'VISA_GRANTED', 'ENROLLED',
];

class ApplicationTrackerScreen extends ConsumerWidget {
  const ApplicationTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(myApplicationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My applications')),
      body: appsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (apps) {
          if (apps.isEmpty) {
            return const Center(child: Text('No applications yet. Browse universities to start one.'));
          }
          return ListView.builder(
            itemCount: apps.length,
            itemBuilder: (context, i) {
              final a = apps[i];
              final programme = a['programme'];
              final university = programme?['university'];
              final status = a['status'] ?? 'DRAFT';
              final progress = (_statusOrder.indexOf(status) + 1) / _statusOrder.length;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(programme?['name'] ?? '', style: Theme.of(context).textTheme.titleMedium),
                      Text(university?['name'] ?? ''),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: progress.clamp(0, 1)),
                      const SizedBox(height: 4),
                      Text(status.toString().replaceAll('_', ' ')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
