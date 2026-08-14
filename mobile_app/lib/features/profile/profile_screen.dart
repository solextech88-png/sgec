import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/session_provider.dart';
import 'edit_profile_screen.dart';

final myProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  return await api.get('/students/me') as Map<String, dynamic>;
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(sessionProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (p) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('${p['firstName']} ${p['lastName']}',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            ListTile(
                title: const Text('Nationality'), subtitle: Text(p['nationality'] ?? '—')),
            ListTile(
                title: const Text('Country of residence'),
                subtitle: Text(p['countryOfResidence'] ?? '—')),
            ListTile(
                title: const Text('Passport number'),
                subtitle: Text(p['passportNumber'] ?? '—')),
            ListTile(
                title: const Text('Highest qualification'),
                subtitle: Text(p['highestQualification'] ?? '—')),
            ListTile(
                title: const Text('Grade / GPA'),
                subtitle: Text(p['gpaOrGrade'] ?? '—')),
            ListTile(
                title: const Text('English proficiency'),
                subtitle: Text(
                  (p['englishTestType'] != null && p['englishTestScore'] != null)
                      ? '${p['englishTestType']}: ${p['englishTestScore']}'
                      : '—',
                )),
            ListTile(
              title: const Text('Assigned consultant'),
              subtitle: Text(p['assignedConsultant'] != null
                  ? '${p['assignedConsultant']['firstName']} ${p['assignedConsultant']['lastName']}'
                  : 'Not yet assigned'),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => EditProfileScreen(initialProfile: p)),
                );
              },
              child: const Text('Edit profile'),
            ),
          ],
        ),
      ),
    );
  }
}
