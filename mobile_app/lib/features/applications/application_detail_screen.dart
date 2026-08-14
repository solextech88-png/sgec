import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session_provider.dart';
import 'application_tracker_screen.dart' show myApplicationsProvider;

/// There's no separate "application form" to fill in beyond the initial
/// Apply action — documents are uploaded once on the Documents tab and
/// reused across every application, and consent is signed once for the
/// whole account, not per-application. This screen exists so tapping an
/// application actually shows something instead of nothing: full
/// programme details, a clear status, and the ability to withdraw.
class ApplicationDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> application;
  const ApplicationDetailScreen({super.key, required this.application});

  @override
  ConsumerState<ApplicationDetailScreen> createState() => _ApplicationDetailScreenState();
}

const _terminalStatuses = ['WITHDRAWN', 'REJECTED', 'ENROLLED'];

class _ApplicationDetailScreenState extends ConsumerState<ApplicationDetailScreen> {
  late Map<String, dynamic> _application;
  bool _withdrawing = false;

  @override
  void initState() {
    super.initState();
    _application = widget.application;
  }

  Future<void> _confirmAndWithdraw() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw this application?'),
        content: const Text(
          'This can\'t be undone. Your consultant will stop working on it, '
          'and if it was already submitted to the university you may need '
          'to contact them separately about the withdrawal.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _withdrawing = true);
    final api = ref.read(apiClientProvider);
    try {
      final updated = await api.put('/applications/${_application['id']}/withdraw') as Map<String, dynamic>;
      ref.invalidate(myApplicationsProvider);
      if (!mounted) return;
      setState(() => _application = {..._application, ...updated});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application withdrawn.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to withdraw: $e')));
      }
    } finally {
      if (mounted) setState(() => _withdrawing = false);
    }
  }

  Widget _row(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 2),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final programme = _application['programme'] as Map<String, dynamic>?;
    final university = programme?['university'] as Map<String, dynamic>?;
    final status = (_application['status'] ?? 'DRAFT').toString();
    final canWithdraw = !_terminalStatuses.contains(status);

    return Scaffold(
      appBar: AppBar(title: const Text('Application')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(university?['name'] ?? '', style: Theme.of(context).textTheme.titleMedium),
          Text(programme?['name'] ?? '', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Chip(label: Text(status.replaceAll('_', ' '))),
          const Divider(height: 32),
          _row('Level', programme?['level']),
          _row('Duration', programme?['durationMonths'] != null ? '${programme?['durationMonths']} months' : null),
          _row('Entry requirements', programme?['entryRequirements']),
          _row('English requirement', programme?['englishRequirement']),
          const SizedBox(height: 24),
          Card(
            color: Colors.blue.shade50,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Your consultant reviews this application using the documents '
                'you\'ve uploaded on the Documents tab and the consent form you '
                'signed — there\'s nothing further to fill in here. You\'ll see '
                'the status above update as they progress it, and can message '
                'them directly from the Chat tab with any questions.',
              ),
            ),
          ),
          if (canWithdraw) ...[
            const SizedBox(height: 24),
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              onPressed: _withdrawing ? null : _confirmAndWithdraw,
              child: _withdrawing
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Withdraw application'),
            ),
          ],
        ],
      ),
    );
  }
}
