import 'package:flutter/material.dart';
import '../universities/university_list_screen.dart';
import '../applications/application_tracker_screen.dart';
import '../documents/document_upload_screen.dart';
import '../ai_assistant/ai_assistant_screen.dart';
import '../chat/chat_screen.dart';
import '../profile/profile_screen.dart';

/// Bottom-nav shell for the STUDENT role. Consultants and admins get their
/// own shells (see consultant_dashboard/ and admin/) — kept separate rather
/// than one shell with conditional tabs, since the two audiences' workflows
/// don't overlap much.
class StudentHomeShell extends StatefulWidget {
  const StudentHomeShell({super.key});
  @override
  State<StudentHomeShell> createState() => _StudentHomeShellState();
}

class _StudentHomeShellState extends State<StudentHomeShell> {
  int _index = 0;

  static const _screens = [
    UniversityListScreen(),
    ApplicationTrackerScreen(),
    DocumentUploadScreen(),
    AiAssistantScreen(),
    ChatScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.school_outlined), label: 'Universities'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), label: 'Applications'),
          NavigationDestination(icon: Icon(Icons.upload_file_outlined), label: 'Documents'),
          NavigationDestination(icon: Icon(Icons.smart_toy_outlined), label: 'AI Assistant'),
          NavigationDestination(icon: Icon(Icons.chat_outlined), label: 'Chat'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
