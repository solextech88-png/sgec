import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/session_provider.dart';

final consentFormsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  return await api.get('/consent/forms') as List<dynamic>;
});

/// Lets a student read the current consent-form text and sign it, either by
/// drawing a signature or typing their full legal name. See
/// backend/src/controllers/consentController.js for what gets recorded
/// (document hash, IP, timestamp) and the legal caveats.
class ConsentSignScreen extends ConsumerStatefulWidget {
  const ConsentSignScreen({super.key});
  @override
  ConsumerState<ConsentSignScreen> createState() => _ConsentSignScreenState();
}

class _ConsentSignScreenState extends ConsumerState<ConsentSignScreen> {
  final _signatureController = SignatureController(penStrokeWidth: 3, penColor: Colors.black);
  final _typedName = TextEditingController();
  bool _submitting = false;

  Future<void> _sign(String consentFormId) async {
    setState(() => _submitting = true);
    try {
      final api = ref.read(apiClientProvider);
      String? filePath;

      if (_signatureController.isNotEmpty) {
        final bytes = await _signatureController.toPngBytes();
        if (bytes != null) {
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/signature.png');
          await file.writeAsBytes(bytes);
          filePath = file.path;
        }
      }

      if (filePath != null) {
        await api.uploadFile(
          '/consent/sign',
          fieldName: 'signatureImage',
          filePath: filePath,
          fields: {'consentFormId': consentFormId, 'typedFullName': _typedName.text},
        );
      } else {
        await api.post('/consent/sign', body: {
          'consentFormId': consentFormId,
          'typedFullName': _typedName.text,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Consent signed')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formsAsync = ref.watch(consentFormsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Authorization to act on your behalf')),
      body: formsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (forms) {
          if (forms.isEmpty) {
            return const Center(child: Text('No consent form is configured yet.'));
          }
          final form = forms.first; // latest version
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(form['title'] ?? '', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(form['bodyMarkdown'] ?? ''),
                ),
                const SizedBox(height: 16),
                Text('Draw your signature:', style: Theme.of(context).textTheme.titleSmall),
                Container(
                  height: 160,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                  child: Signature(controller: _signatureController, backgroundColor: Colors.white),
                ),
                TextButton(
                  onPressed: () => _signatureController.clear(),
                  child: const Text('Clear signature'),
                ),
                const SizedBox(height: 8),
                Text('...or type your full legal name instead:'),
                TextField(
                  controller: _typedName,
                  decoration: const InputDecoration(labelText: 'Full legal name'),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _submitting ? null : () => _sign(form['id']),
                  child: _submitting
                      ? const CircularProgressIndicator()
                      : const Text('I agree and sign'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
