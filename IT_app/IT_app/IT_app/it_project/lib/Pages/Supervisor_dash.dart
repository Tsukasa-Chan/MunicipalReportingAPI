import 'dart:async';

import 'package:flutter/material.dart';

import 'SupervisorSchedule.dart';
import 'Supervisor_theme.dart';
import 'auth_store.dart';
import 'ContactUs.dart';
import 'Profile.dart';
import 'report_store.dart';
import 'Settings.dart';
import 'StartUp.dart';

class SupervisorDashboardPage extends StatefulWidget {
  const SupervisorDashboardPage({super.key});

  @override
  State<SupervisorDashboardPage> createState() =>
      _SupervisorDashboardPageState();
}

class _SupervisorDashboardPageState extends State<SupervisorDashboardPage> {
  int _selectedIndex = 0;

  static const _pages = [
    _SupervisorOverview(),
    ContactPage(),
    ProfilePage(),
    SettingsPage(),
  ];

  static const _titles = [
    'Supervisor dashboard',
    'Contact-us',
    'Profile',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    final supervisor = AuthStore.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'lib/img/app logo.png',
                width: 42,
                height: 42,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            Text(_titles[_selectedIndex]),
          ],
        ),
        backgroundColor: const Color(0xFFC94F1B),
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(
                  '${supervisor?.name ?? 'Supervisor'} '
                          '${supervisor?.surname ?? ''}'
                      .trim(),
                ),
                accountEmail: Text(supervisor?.email ?? 'Supervisor'),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: AssetImage('lib/img/app logo.png'),
                ),
                decoration: BoxDecoration(color: Color(0xFFC94F1B)),
              ),
              _menuItem(0, Icons.dashboard_outlined, 'Dashboard'),
              _menuItem(1, Icons.contact_mail_outlined, 'Contact-us'),
              _menuItem(2, Icons.person_outline, 'Profile'),
              _menuItem(3, Icons.settings_outlined, 'Settings'),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
      body: const _SupervisorOverview(),
    );
  }

  Widget _menuItem(int index, IconData icon, String label) {
    return ListTile(
      selected: _selectedIndex == index,
      selectedColor: const Color(0xFFC94F1B),
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        if (index == 0) {
          setState(() => _selectedIndex = 0);
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _pages[index]),
        );
      },
    );
  }

  void _logout() {
    AuthStore.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const StartupPage()),
      (_) => false,
    );
  }
}

class _SupervisorOverview extends StatefulWidget {
  const _SupervisorOverview();

  @override
  State<_SupervisorOverview> createState() => _SupervisorOverviewState();
}

class _SupervisorOverviewState extends State<_SupervisorOverview> {
  DateTime _now = DateTime.now();
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supervisor = AuthStore.currentUser;
    final reports = ReportStore.reports
        .where(
          (report) =>
              supervisor == null ||
              AuthStore.canSuperviseIssue(
                supervisorUsername: supervisor.username,
                issueType: report.issueType,
              ),
        )
        .toList();
    final todayJobs = ReportStore.reportsForSupervisorOnDate(
      supervisorUsername: supervisor?.username ?? '',
      date: _now,
    );
    final todayJobCount = ReportStore.groupReports(todayJobs).length;
    final today = DateTime.now();
    final dailyReports = reports.where((report) {
      final createdAt = report.createdAt.toLocal();
      return createdAt.year == today.year &&
          createdAt.month == today.month &&
          createdAt.day == today.day;
    }).length;
    final pending = reports
        .where((report) => report.status == 'Pending')
        .length;
    final inProgress = reports
        .where((report) => report.status == 'In progress')
        .length;
    final onSite = reports.where((report) => report.status == 'On-site').length;
    final finished = reports
        .where(
          (report) =>
              report.status == 'Completed' || report.status == 'Finished',
        )
        .length;
    return Container(
      decoration: pageBackgroundDecoration(isSupervisor: true),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Supervisor dashboard',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC94F1B),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Monitor incoming reports and field activity.'),
          const SizedBox(height: 16),
          _ScheduleCard(
            now: _now,
            jobCount: todayJobCount,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SupervisorSchedulePage(day: _now),
              ),
            ).then((_) {
              if (mounted) setState(() {});
            }),
          ),
          const SizedBox(height: 20),
          _DailyReportsBubble(
            reportType: supervisor?.supervisorIssueType,
            count: dailyReports,
            onTap: () => _showReports(context, reports),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatCard(
                label: 'Total',
                value: reports.length,
                icon: Icons.inbox_outlined,
              ),
              _StatCard(
                label: 'Pending',
                value: pending,
                icon: Icons.pending_actions,
              ),
              _StatCard(
                label: 'In progress',
                value: inProgress,
                icon: Icons.build_circle_outlined,
              ),
              _StatCard(
                label: 'On-site',
                value: onSite,
                icon: Icons.location_on_outlined,
              ),
              _StatCard(
                label: 'Completed',
                value: finished,
                icon: Icons.check_circle_outline,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReports(BuildContext context, List<ReportRequest> reports) {
    final groupedReports = ReportStore.groupReports(reports);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          '${AuthStore.currentUser?.supervisorIssueType ?? 'All'} reports',
        ),
        content: SizedBox(
          width: 480,
          child: groupedReports.isEmpty
              ? const Text('No reports found for this report type.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: groupedReports.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final group = groupedReports[index];
                    final report = group.firstReport;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Report #${report.id}: ${report.issueType} - ${report.issue}',
                      ),
                      subtitle: Text(
                        'Reported by ${group.reporterCount} '
                        '${group.reporterCount == 1 ? 'person' : 'people'} '
                        '(first: ${report.senderName})\n'
                        'Date: ${report.createdAt.toLocal()}\n'
                        'Area: ${report.area} • Status: ${report.status}'
                        '${report.description.isEmpty ? '' : '\n${report.description}'}',
                      ),
                      isThreeLine: true,
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.now,
    required this.jobCount,
    required this.onTap,
  });

  final DateTime now;
  final int jobCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date =
        '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/${now.year}';
    final time =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';

    return Card(
      color: Colors.white.withValues(alpha: 0.92),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFC94F1B),
                foregroundColor: Colors.white,
                child: Icon(Icons.calendar_month_outlined),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Today’s schedule',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    Text('$date • $time'),
                    Text('$jobCount job(s) allocated today'),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyReportsBubble extends StatelessWidget {
  const _DailyReportsBubble({
    required this.reportType,
    required this.count,
    required this.onTap,
  });

  final String? reportType;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFC94F1B),
                foregroundColor: Colors.white,
                child: Text(
                  '$count',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reportType == null
                          ? 'Today’s reports'
                          : 'Today’s $reportType reports',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      reportType == null
                          ? 'Tap to view today’s reports'
                          : 'Tap to view today’s $reportType reports',
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 155,
      child: Card(
        color: Colors.white.withValues(alpha: 0.88),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFFC94F1B)),
              const SizedBox(height: 12),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
