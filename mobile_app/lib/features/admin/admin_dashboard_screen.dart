import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/session_provider.dart';
import '../universities/university_list_screen.dart';
import '../students/student_list_screen.dart';

/// Admin landing screen. University/programme CRUD reuses
/// UniversityListScreen for browsing; full add/edit forms and the
/// analytics/reporting views are TODOs — the backend already exposes
/// POST/PUT/DELETE on /universities and /programmes (admin-only) plus
/// /students, /applications and /consent/forms for everything else an
/// admin needs to manage.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiles = [
      _AdminTile('Universities & programmes', Icons.school, () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const UniversityListScreen(),
        ));
      }),
      _AdminTile('Students', Icons.people, () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const StudentListScreen(),
        ));
      }),
      _AdminTile('Consultants', Icons.support_agent, () {
        // TODO: consultant CRUD screen (create ConsultantProfile + User w/ role CONSULTANT)
      }),
      _AdminTile('Countries & intake periods', Icons.public, () {
        // TODO: CRUD against /countries and Programme.intakeCycle/isNextIntake
      }),
      _AdminTile('Consent form versions', Icons.gavel, () {
        // TODO: CRUD against /consent/forms
      }),
      _AdminTile('Analytics & reports', Icons.bar_chart, () {
        // TODO: dashboard summarizing applications by status/country/university
      }),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(sessionProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: tiles.map((t) => t.build(context)).toList(),
      ),
    );
  }
}

class _AdminTile {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  _AdminTile(this.title, this.icon, this.onTap);

  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
