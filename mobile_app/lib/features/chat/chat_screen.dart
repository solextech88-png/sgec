import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  List<dynamic> _messages = [];
  String? _threadId;
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final api = ref.read(apiClientProvider);
    final thread = await api.get('/chat/thread');
    _threadId = thread['id'];
    await _refresh();
    // Simple polling every 4s. Replace with WebSocket/Firebase for real-time.
    _poller = Timer.periodic(const Duration(seconds: 4), (_) => _refresh());
  }

  Future<void> _refresh() async {
    if (_threadId == null) return;
    final api = ref.read(apiClientProvider);
    final msgs = await api.get('/chat/thread/$_threadId/messages');
    if (mounted) setState(() => _messages = msgs);
  }

  Future<void> _send() async {
    if (_controller.text.trim().isEmpty || _threadId == null) return;
    final api = ref.read(apiClientProvider);
    await api.post('/chat/thread/$_threadId/messages', body: {'body': _controller.text.trim()});
    _controller.clear();
    await _refresh();
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat with your consultant')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: false,
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(m['body'] ?? ''),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: 'Type a message...'),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.send), onPressed: _send),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
