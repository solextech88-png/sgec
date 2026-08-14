import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session_provider.dart';
import 'profile_screen.dart' show myProfileProvider;

const _englishTestTypes = ['IELTS', 'TOEFL', 'PTE', 'Duolingo', 'Other'];

/// Real edit form wired to PUT /students/me. Includes the fields UK and
/// European university applications typically ask for up front: passport
/// number, highest qualification + grade, and English proficiency test
/// result — beyond what document uploads alone capture, since consultants
/// need this as structured data to match students against entry
/// requirements, not just a PDF to open.
class EditProfileScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> initialProfile;
  const EditProfileScreen({super.key, required this.initialProfile});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstName;
  late TextEditingController _lastName;
  late TextEditingController _nationality;
  late TextEditingController _countryOfResidence;
  late TextEditingController _passportNumber;
  late TextEditingController _highestQualification;
  late TextEditingController _gpaOrGrade;
  late TextEditingController _englishTestScore;
  String? _gender;
  String? _englishTestType;
  DateTime? _dateOfBirth;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile;
    _firstName = TextEditingController(text: p['firstName'] ?? '');
    _lastName = TextEditingController(text: p['lastName'] ?? '');
    _nationality = TextEditingController(text: p['nationality'] ?? '');
    _countryOfResidence = TextEditingController(text: p['countryOfResidence'] ?? '');
    _passportNumber = TextEditingController(text: p['passportNumber'] ?? '');
    _highestQualification = TextEditingController(text: p['highestQualification'] ?? '');
    _gpaOrGrade = TextEditingController(text: p['gpaOrGrade'] ?? '');
    _englishTestScore = TextEditingController(text: p['englishTestScore'] ?? '');
    _gender = p['gender'];
    _englishTestType = _englishTestTypes.contains(p['englishTestType']) ? p['englishTestType'] : null;
    final dob = p['dateOfBirth'];
    _dateOfBirth = dob != null ? DateTime.tryParse(dob.toString()) : null;
  }

  @override
  void dispose() {
    for (final c in [
      _firstName, _lastName, _nationality, _countryOfResidence,
      _passportNumber, _highestQualification, _gpaOrGrade, _englishTestScore,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 20),
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year - 14),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final api = ref.read(apiClientProvider);
    try {
      await api.put('/students/me', body: {
        'firstName': _firstName.text.trim(),
        'lastName': _lastName.text.trim(),
        if (_dateOfBirth != null) 'dateOfBirth': _dateOfBirth!.toIso8601String(),
        'nationality': _nationality.text.trim(),
        'countryOfResidence': _countryOfResidence.text.trim(),
        if (_gender != null) 'gender': _gender,
        'passportNumber': _passportNumber.text.trim(),
        'highestQualification': _highestQualification.text.trim(),
        'gpaOrGrade': _gpaOrGrade.text.trim(),
        if (_englishTestType != null) 'englishTestType': _englishTestType,
        'englishTestScore': _englishTestScore.text.trim(),
      });
      ref.invalidate(myProfileProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _firstName,
              decoration: const InputDecoration(labelText: 'First name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastName,
              decoration: const InputDecoration(labelText: 'Last name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date of birth'),
              subtitle: Text(_dateOfBirth != null
                  ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                  : 'Not set'),
              trailing: const Icon(Icons.calendar_today, size: 18),
              onTap: _pickDateOfBirth,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: const InputDecoration(labelText: 'Gender'),
              items: const [
                DropdownMenuItem(value: 'Female', child: Text('Female')),
                DropdownMenuItem(value: 'Male', child: Text('Male')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
                DropdownMenuItem(value: 'Prefer not to say', child: Text('Prefer not to say')),
              ],
              onChanged: (v) => setState(() => _gender = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nationality,
              decoration: const InputDecoration(
                labelText: 'Nationality',
                hintText: 'e.g. Nigerian, Indian, Brazilian',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _countryOfResidence,
              decoration: const InputDecoration(labelText: 'Country of residence'),
            ),
            const Divider(height: 32),
            Text('For university applications', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passportNumber,
              decoration: const InputDecoration(labelText: 'Passport number'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _highestQualification,
              decoration: const InputDecoration(
                labelText: 'Highest qualification',
                hintText: 'e.g. BSc Computer Science',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _gpaOrGrade,
              decoration: const InputDecoration(
                labelText: 'Grade / GPA / classification',
                hintText: 'e.g. 2:1, 3.6 GPA, First Class',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _englishTestType,
              decoration: const InputDecoration(labelText: 'English proficiency test'),
              items: _englishTestTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _englishTestType = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _englishTestScore,
              decoration: const InputDecoration(
                labelText: 'Test score',
                hintText: 'e.g. 7.0 overall, no band below 6.5',
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'This is a declared score for matching purposes — upload your '
              'actual certificate under the Documents tab so your consultant '
              'can verify it.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
