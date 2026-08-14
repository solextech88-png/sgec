import 'package:flutter/material.dart';

/// There's no separate "application form" to fill in beyond the initial
/// Apply action — documents are uploaded once on the Documents tab and
/// reused across every application, and consent is signed once for the
/// whole account, not per-application. This screen exists so tapping an
/// application actually shows something instead of nothing: full
/// programme details plus a clear status, rather than pretending there's
/// a multi-step form to "complete" here.
class ApplicationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> application;
  const ApplicationDetailScreen({super.key, required this.application});

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
    final programme = application['programme'] as Map<String, dynamic>?;
    final university = programme?['university'] as Map<String, dynamic>?;
    final status = (application['status'] ?? 'DRAFT').toString();

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
        ],
      ),
    );
  }
}
