import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/session_provider.dart';

const documentTypes = [
  'PASSPORT', 'PHOTOGRAPH', 'TRANSCRIPT', 'CERTIFICATE', 'ENGLISH_TEST',
  'CV', 'PERSONAL_STATEMENT', 'RESEARCH_PROPOSAL', 'RECOMMENDATION_LETTER', 'OTHER',
];

final myDocumentsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  return await api.get('/documents/mine') as List<dynamic>;
});

class DocumentUploadScreen extends ConsumerStatefulWidget {
  const DocumentUploadScreen({super.key});
  @override
  ConsumerState<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends ConsumerState<DocumentUploadScreen> {
  String _selectedType = documentTypes.first;
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.pickFiles(withData: false);
    if (result == null || result.files.single.path == null) return;

    setState(() => _uploading = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.uploadFile(
        '/documents',
        fieldName: 'file',
        filePath: result.files.single.path!,
        fields: {'type': _selectedType},
      );
      ref.invalidate(myDocumentsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(myDocumentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My documents')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedType,
                    items: documentTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedType = v!),
                    decoration: const InputDecoration(labelText: 'Document type'),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _uploading ? null : _pickAndUpload,
                  icon: _uploading
                      ? const SizedBox(
                          width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.upload_file),
                  label: const Text('Upload'),
                ),
              ],
            ),
          ),
          Expanded(
            child: docsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed to load: $e')),
              data: (docs) => ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final d = docs[i];
                  return ListTile(
                    leading: Icon(d['verifiedByConsultant'] == true
                        ? Icons.verified
                        : Icons.hourglass_empty),
                    title: Text(d['fileName'] ?? ''),
                    subtitle: Text(d['type'] ?? ''),
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
