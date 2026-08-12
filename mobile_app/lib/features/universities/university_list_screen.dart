import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/session_provider.dart';
import '../../models/university.dart';

final universitiesProvider = FutureProvider.family<List<University>, String?>((ref, region) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/universities', query: region == null ? null : {'region': region});
  return (res as List).map((e) => University.fromJson(e)).toList();
});

class UniversityListScreen extends ConsumerStatefulWidget {
  const UniversityListScreen({super.key});
  @override
  ConsumerState<UniversityListScreen> createState() => _UniversityListScreenState();
}

class _UniversityListScreenState extends ConsumerState<UniversityListScreen> {
  String? _region; // null = all, else "UK" | "Ireland" | "Europe"

  @override
  Widget build(BuildContext context) {
    final universitiesAsync = ref.watch(universitiesProvider(_region));

    return Scaffold(
      appBar: AppBar(title: const Text('Universities')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [null, 'UK', 'Ireland', 'Europe'].map((region) {
                final selected = _region == region;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(region ?? 'All'),
                    selected: selected,
                    onSelected: (_) => setState(() => _region = region),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: universitiesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed to load: $e')),
              data: (universities) => ListView.builder(
                itemCount: universities.length,
                itemBuilder: (context, i) {
                  final u = universities[i];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.school)),
                    title: Text(u.name),
                    subtitle: Text([u.city, u.countryName, u.type]
                        .where((s) => s != null && s.isNotEmpty)
                        .join(' · ')),
                    onTap: () => context.push('/universities/${u.id}'),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
