import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session_provider.dart';

final countriesProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  return await api.get('/countries') as List<dynamic>;
});

/// Read-only view of the country catalog (backed by GET /countries, which
/// already returns university counts per country). Intake periods live on
/// individual Programmes (intakeCycle / isNextIntake), not on Country — so
/// editing those happens per-programme, not here. Full country/programme
/// CRUD editing forms are a TODO; this screen answers "what's actually in
/// the catalog right now" without pretending there's an edit flow that
/// doesn't exist yet.
class CountryListScreen extends ConsumerWidget {
  const CountryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countriesAsync = ref.watch(countriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Countries')),
      body: countriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (countries) {
          if (countries.isEmpty) {
            return const Center(child: Text('No countries in the catalog yet.'));
          }

          final Map<String, List<dynamic>> byRegion = {};
          for (final c in countries) {
            final region = (c['region'] as String?) ?? 'Other';
            byRegion.putIfAbsent(region, () => []).add(c);
          }
          final regions = byRegion.keys.toList()..sort();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Card(
                color: Color(0xFFEFF6FF),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Intake periods are set per programme, not per country. '
                    'To change an intake cycle, edit the relevant programme '
                    '(programme editing UI is a future addition).',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...regions.map((region) {
                final items = byRegion[region]!;
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    title: Text(region, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${items.length} countries'),
                    initiallyExpanded: true,
                    children: items.map((c) {
                      final uniCount = c['_count']?['universities'] ?? 0;
                      return ListTile(
                        title: Text(c['name'] ?? ''),
                        subtitle: Text(c['isoCode'] ?? ''),
                        trailing: Text('$uniCount ${uniCount == 1 ? 'university' : 'universities'}'),
                      );
                    }).toList(),
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
