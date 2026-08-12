import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/session_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String userId;
  final String channel;
  const OtpScreen({super.key, required this.userId, required this.channel});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _code = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _confirm() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.post('/auth/otp/confirm', body: {
        'userId': widget.userId,
        'code': _code.text.trim(),
        'channel': widget.channel,
      });
      await ref.read(sessionProvider.notifier).loginSucceeded(res['token'], res['role']);
      if (!mounted) return;
      context.go('/');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    final api = ref.read(apiClientProvider);
    await api.post('/auth/otp/send', body: {'userId': widget.userId, 'channel': widget.channel});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code resent')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify your account')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Enter the 6-digit code sent to your ${widget.channel}',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 20),
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(labelText: 'Verification code'),
              ),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loading ? null : _confirm,
                child: _loading ? const CircularProgressIndicator() : const Text('Verify'),
              ),
              TextButton(onPressed: _resend, child: const Text('Resend code')),
            ],
          ),
        ),
      ),
    );
  }
}
