import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session_provider.dart';
import '../../core/api_client.dart';
import '../consent/consent_sign_screen.dart';

/// Full programme detail + the actual "Apply" action. Reached from
/// UniversityDetailScreen, which already fetched the full programme object
/// (entry requirements, deadlines, visa info, etc.) as part of the
/// university payload — so this screen takes that data directly rather
/// than making a second network call.
class ProgrammeDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> programme;
  final String universityName;

  const ProgrammeDetailScreen({
    super.key,
    required this.programme,
    required this.universityName,
  });

  @override
  ConsumerState<ProgrammeDetailScreen> createState() => _ProgrammeDetailScreenState();
}

class _ProgrammeDetailScreenState extends ConsumerState<ProgrammeDetailScreen> {
  bool _applying = false;

  Future<void> _apply() async {
    setState(() => _applying = true);
    final api = ref.read(apiClientProvider);

    try {
      await api.post('/applications', body: {'programmeId': widget.programme['id']});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application started! Check the Applications tab to track it.')),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 403) {
        // Backend enforces: no application without a signed consent form.
        _showConsentRequiredDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Something went wrong: $e')));
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  void _showConsentRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Consent required'),
        content: const Text(
          'You need to sign the authorization form before we can submit '
          'applications on your behalf. This only takes a minute.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ConsentSignScreen()),
              );
            },
            child: const Text('Sign now'),
          ),
        ],
      ),
    );
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
    final p = widget.programme;
    final deadline = p['applicationDeadline'] != null
        ? DateTime.tryParse(p['applicationDeadline'].toString())
        : null;
    final startDates = (p['startDates'] as List?)?.join(', ');

    return Scaffold(
      appBar: AppBar(title: Text(p['name'] ?? 'Programme')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.universityName, style: Theme.of(context).textTheme.titleMedium),
          Text(p['name'] ?? '', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              if (p['level'] != null) Chip(label: Text(p['level'].toString())),
              if (p['isNextIntake'] == true) const Chip(label: Text('Next intake')),
              if (p['casAvailable'] == true) const Chip(label: Text('CAS available')),
            ],
          ),
          const Divider(height: 32),
          _row('Duration', p['durationMonths'] != null ? '${p['durationMonths']} months' : null),
          _row('Tuition fee',
              (p['tuitionFeeAmount'] != null) ? '${p['tuitionFeeCurrency'] ?? ''} ${p['tuitionFeeAmount']} / year' : null),
          _row('Campus', p['campus']),
          _row('Start dates', startDates),
          _row('Application deadline', deadline != null ? '${deadline.day}/${deadline.month}/${deadline.year}' : null),
          _row('Entry requirements', p['entryRequirements']),
          _row('English requirement', p['englishRequirement']),
          _row('Scholarships', p['scholarshipsAvailable']),
          _row('Visa information', p['visaInfo']),
          _row('Post-graduation work rights', p['postGradWorkRights']),
          _row('Dependants policy', p['dependantsPolicy']),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _applying ? null : _apply,
            child: _applying
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
