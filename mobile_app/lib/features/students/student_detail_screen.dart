import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session_provider.dart';
import '../consultants/consultant_list_screen.dart' show consultantsProvider;

final studentDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, studentId) async {
  final api = ref.read(apiClientProvider);
  return await api.get('/students/$studentId') as Map<String, dynamic>;
});

/// This is the screen consultants/admins actually need: everything about
/// one student in one place — full profile (including passport, academic
/// qualification, and declared English test score), uploaded documents
/// (with a mark-as-verified action), signed consent forms (with the audit
/// fields that matter: status, signed date, IP), applications so far, and
/// the ability to assign/reassign their consultant. Backed by
/// GET /students/:id, which already returns all of this nested.
class StudentDetailScreen extends ConsumerStatefulWidget {
  final String studentId;
  const StudentDetailScreen({super.key, required this.studentId});

  @override
  ConsumerState<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends ConsumerState<StudentDetailScreen> {
  bool _assigning = false;

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

  Future<void> _showAssignConsultantDialog() async {
    final consultants = await ref.read(consultantsProvider.future);
    if (!mounted) return;

    if (consultants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No consultants exist yet — add one first from the Consultants screen.')),
      );
      return;
    }

    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Assign consultant'),
        children: consultants.map((c) {
          return SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(c as Map<String, dynamic>),
            child: Text('${c['firstName']} ${c['lastName']}'),
          );
        }).toList(),
      ),
    );

    if (selected == null) return;

    setState(() => _assigning = true);
    final api = ref.read(apiClientProvider);
    try {
      await api.put('/students/${widget.studentId}/assign-consultant', body: {
        'consultantId': selected['id'],
      });
      ref.invalidate(studentDetailProvider(widget.studentId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Assigned to ${selected['firstName']} ${selected['lastName']}.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _assigning = false);
    }
  }

  Widget _fact(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
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
          final consultant = s['assignedConsultant'] as Map<String, dynamic>?;
          final englishTest = (s['englishTestType'] != null && s['englishTestScore'] != null)
              ? '${s['englishTestType']}: ${s['englishTestScore']}'
              : null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('${s['firstName'] ?? ''} ${s['lastName'] ?? ''}',
                  style: Theme.of(context).textTheme.headlineSmall),
              Text(s['user']?['email'] ?? s['user']?['phone'] ?? ''),
              const SizedBox(height: 12),
              _fact('Nationality', s['nationality']),
              _fact('Country of residence', s['countryOfResidence']),
              _fact('Gender', s['gender']),
              _fact('Date of birth', s['dateOfBirth']?.toString().split('T').first),
              _fact('Passport number', s['passportNumber']),
              _fact('Highest qualification', s['highestQualification']),
              _fact('Grade / GPA', s['gpaOrGrade']),
              _fact('English proficiency', englishTest),
              const SizedBox(height: 8),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.support_agent),
                  title: const Text('Assigned consultant'),
                  subtitle: Text(
                    consultant != null
                        ? '${consultant['firstName']} ${consultant['lastName']}'
                        : 'Not yet assigned',
                  ),
                  trailing: _assigning
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : TextButton(
                          onPressed: _showAssignConsultantDialog,
                          child: Text(consultant != null ? 'Reassign' : 'Assign'),
                        ),
                ),
              ),
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
