import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session_provider.dart';

final consultantsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  return await api.get('/consultants') as List<dynamic>;
});

/// Lists all consultants and lets an admin create new ones. There's
/// intentionally no public consultant sign-up — registration always
/// creates a STUDENT account — so this is the only way a consultant
/// account gets made. Assigning a consultant to a specific student
/// happens from that student's detail screen (see StudentDetailScreen),
/// not here, since that action is scoped to one student at a time.
class ConsultantListScreen extends ConsumerWidget {
  const ConsultantListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consultantsAsync = ref.watch(consultantsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Consultants')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddConsultantDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add consultant'),
      ),
      body: consultantsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (consultants) {
          if (consultants.isEmpty) {
            return const Center(child: Text('No consultants yet. Add one to get started.'));
          }
          return ListView.builder(
            itemCount: consultants.length,
            itemBuilder: (context, i) {
              final c = consultants[i];
              final students = (c['students'] as List? ?? []);
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.support_agent)),
                title: Text('${c['firstName'] ?? ''} ${c['lastName'] ?? ''}'),
                subtitle: Text(
                  '${c['user']?['email'] ?? ''} · ${students.length} student${students.length == 1 ? '' : 's'} assigned',
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddConsultantDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final firstName = TextEditingController();
    final lastName = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add consultant'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: firstName,
                    decoration: const InputDecoration(labelText: 'First name'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: lastName,
                    decoration: const InputDecoration(labelText: 'Last name'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: email,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || !v.contains('@')) ? 'Valid email required' : null,
                  ),
                  TextFormField(
                    controller: password,
                    decoration: const InputDecoration(
                      labelText: 'Temporary password',
                      helperText: 'Share this with the consultant so they can log in',
                    ),
                    obscureText: true,
                    validator: (v) => (v == null || v.length < 8) ? 'At least 8 characters' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => saving = true);
                      final api = ref.read(apiClientProvider);
                      try {
                        await api.post('/consultants', body: {
                          'firstName': firstName.text.trim(),
                          'lastName': lastName.text.trim(),
                          'email': email.text.trim(),
                          'password': password.text,
                        });
                        ref.invalidate(consultantsProvider);
                        if (context.mounted) Navigator.of(context).pop();
                      } catch (e) {
                        setState(() => saving = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text('Failed: $e')));
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
