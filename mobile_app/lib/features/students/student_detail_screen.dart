import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session_provider.dart';

final studentDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, studentId) async {
  final api = ref.read(apiClientProvider);
  return await api.get('/students/$studentId') as Map<String, dynamic>;
});

/// This is the screen consultants/admins actually need: everything about
/// one student in one place — profile, uploaded documents (with a
/// mark-as-verified action), signed consent forms (with the audit fields
/// that matter: status, signed date, IP), and their applications so far.
/// Backed by GET /students/:id, which already returns all of this nested.
class StudentDetailScreen extends ConsumerStatefulWidget {
  final String studentId;
  const StudentDetailScreen({super.key, required this.studentId});

  @override
  ConsumerState<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends ConsumerState<StudentDetailScreen> {
  Future<void> _verifyDocument(String documentId) async {
    final api = ref.read(apiClientProvider);
    try {
      await api.put('/documents/$documentId/verify');
      ref.invalidate(studentDetailProvider(widget.studentId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(studentDetailProvider(widget.studentId));

    return Scaffold(
      appBar: AppBar(title: const Text('Student')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (s) {
          final documents = (s['documents'] as List? ?? []);
          final consentSignatures = (s['consentSignatures'] as List? ?? []);
          final applications = (s['applications'] as List? ?? []);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('${s['firstName'] ?? ''} ${s['lastName'] ?? ''}',
                  style: Theme.of(context).textTheme.headlineSmall),
              Text(s['user']?['email'] ?? s['user']?['phone'] ?? ''),
              const SizedBox(height: 8),
              Wrap(spacing: 16, children: [
                Text('Nationality: ${s['nationality'] ?? '—'}'),
                Text('Country of residence: ${s['countryOfResidence'] ?? '—'}'),
              ]),
              const Divider(height: 32),

              Text('Consent forms', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (consentSignatures.isEmpty)
                const Text('No consent form signed yet.', style: TextStyle(color: Colors.black54))
              else
                ...consentSignatures.map((c) => Card(
                      child: ListTile(
                        leading: Icon(
                          c['status'] == 'SIGNED' ? Icons.check_circle : Icons.circle_outlined,
                          color: c['status'] == 'SIGNED' ? Colors.green : null,
                        ),
                        title: Text(c['consentForm']?['title'] ?? 'Consent form'),
                        subtitle: Text(
                          '${c['status']} · v${c['consentForm']?['version'] ?? '?'}'
                          '${c['signedAt'] != null ? ' · signed ${c['signedAt'].toString().split('T').first}' : ''}',
                        ),
                      ),
                    )),
              const SizedBox(height: 24),

              Text('Documents (${documents.length})', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (documents.isEmpty)
                const Text('No documents uploaded yet.', style: TextStyle(color: Colors.black54))
              else
                ...documents.map((d) => Card(
                      child: ListTile(
                        leading: Icon(d['verifiedByConsultant'] == true
                            ? Icons.verified
                            : Icons.hourglass_empty),
                        title: Text(d['fileName'] ?? ''),
                        subtitle: Text(d['type'] ?? ''),
                        trailing: d['verifiedByConsultant'] == true
                            ? null
                            : TextButton(
                                onPressed: () => _verifyDocument(d['id']),
                                child: const Text('Mark verified'),
                              ),
                      ),
                    )),
              const SizedBox(height: 24),

              Text('Applications (${applications.length})', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (applications.isEmpty)
                const Text('No applications yet.', style: TextStyle(color: Colors.black54))
              else
                ...applications.map((a) => Card(
                      child: ListTile(
                        title: Text(a['programme']?['name'] ?? ''),
                        subtitle: Text(
                          '${a['programme']?['university']?['name'] ?? ''} · ${a['status']}',
                        ),
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }
}
