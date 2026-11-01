import 'dart:async';
import 'package:flutter/material.dart';
import 'SupervisorSchedule.dart';
import 'Supervisor_theme.dart';
import 'auth_store.dart';
import 'auth_api.dart';
import 'api_paths.dart';
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
  static const Color _orange = Color(0xFFC94F1B);
  static const Color _darkText = Color(0xFF292524);
  static const Color _secondaryText = Color(0xFF78716C);
  static const Color _cream = Color(0xFFFFF8F4);
  static const Color _borderColor = Color(0xFFE8C7B8);
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
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'lib/img/app logo.png',
                width: 42,
                height: 42,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _titles[_selectedIndex],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: Drawer(
        backgroundColor: _cream,
        child: SafeArea(
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(
                  '${supervisor?.name ?? 'Supervisor'} '
                      '${supervisor?.surname ?? ''}'.trim(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                accountEmail: Text(
                  supervisor?.email ?? 'Supervisor',
                  style: const TextStyle(color: Colors.white70),
                ),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: AssetImage('lib/img/app logo.png'),
                ),
                decoration: const BoxDecoration(
                  color: _orange,
                ),
              ),
              _menuItem(0, Icons.dashboard_outlined, 'Dashboard'),
              _menuItem(1, Icons.contact_mail_outlined, 'Contact-us'),
              _menuItem(2, Icons.person_outline, 'Profile'),
              _menuItem(3, Icons.settings_outlined, 'Settings'),
              const Spacer(),
              const Divider(color: _borderColor, height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: _orange),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: _darkText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
  Widget _menuItem(int index, IconData icon, String label) {
    return ListTile(
      selected: _selectedIndex == index,
      selectedColor: _orange,
      selectedTileColor: const Color(0xFFFFE9DC),
      leading: Icon(
        icon,
        color: _selectedIndex == index ? _orange : _secondaryText,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: _selectedIndex == index ? _orange : _darkText,
          fontWeight:
          _selectedIndex == index ? FontWeight.bold : FontWeight.w500,
        ),
      ),
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
  static const Color _orange = Color(0xFFC94F1B);
  static const Color _darkText = Color(0xFF292524);
  static const Color _secondaryText = Color(0xFF78716C);
  static const Color _borderColor = Color(0xFFE8C7B8);
  static const Color _cream = Color(0xFFFFF8F4);
  DateTime _now = DateTime.now();
  Timer? _clockTimer;
  // Reports fetched from the backend for the logged-in supervisor.
  List<ReportRequest> _supervisorReports = [];
  bool _isLoadingReports = true;
  String? _reportsError;
  @override
  void initState() {
    super.initState();
    _loadSupervisorReports();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }
  // Fetch only the reports assigned to the logged-in supervisor.
  Future<void> _loadSupervisorReports() async {
    final supervisor = AuthStore.currentUser;
    if (supervisor == null) {
      if (!mounted) return;
      setState(() {
        _isLoadingReports = false;
        _reportsError = 'No logged-in supervisor found.';
      });
      return;
    }
    try {
      final reports =
      await AuthStore.withAccessToken<List<ReportRequest>>(
            (api, accessToken) async {
          final response = await api.getRaw(
            ApiPaths.reportsForSupervisor(supervisor.username),
            accessToken: accessToken,
          );
          return response
              .whereType<Map>()
              .map(
                (report) => ReportRequest.fromJson(
              Map<String, dynamic>.from(report),
            ),
          )
              .toList();
        },
      );
      if (!mounted) return;
      setState(() {
        _supervisorReports = reports;
        _isLoadingReports = false;
        _reportsError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingReports = false;
        _reportsError = e.toString();
      });
    }
  }
  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final supervisor = AuthStore.currentUser;
    // Use the reports returned by the backend for the dashboard totals.
    final reports = _supervisorReports;
    // The schedule still uses the existing local ReportStore data.
    final todayJobs = ReportStore.reportsForSupervisorOnDate(
      supervisorUsername: supervisor?.username ?? '',
      date: _now,
    );
    final todayJobCount = ReportStore.groupReports(todayJobs).length;
    final today = DateTime.now();
    // Count reports created today that are assigned to this supervisor.
    final dailyReports = reports.where((report) {
      final createdAt = report.createdAt.toLocal();
      return createdAt.year == today.year &&
          createdAt.month == today.month &&
          createdAt.day == today.day;
    }).length;
    final reported = reports
        .where((report) => report.status == 'Reported')
        .length;
    final inProgress = reports
        .where((report) => report.status == 'In progress')
        .length;
    final resolved = reports
        .where((report) => report.status == 'Resolved')
        .length;
    return Container(
      decoration: pageBackgroundDecoration(isSupervisor: true),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Supervisor dashboard',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              color: _darkText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Monitor incoming reports and field activity.',
            style: TextStyle(
              color: _secondaryText,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 20),
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
          // Show the loading or error message while fetching dashboard data.
          if (_isLoadingReports)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: CircularProgressIndicator(
                  color: _orange,
                ),
              ),
            )
          else if (_reportsError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Text(
                    'Could not load assigned reports.\n$_reportsError',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: _loadSupervisorReports,
                    child: const Text(
                      'Try again',
                      style: TextStyle(
                        color: _orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const Text(
            'REPORT OVERVIEW',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _darkText,
            ),
          ),
          const SizedBox(height: 12),
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
                label: 'Reported',
                value: reported,
                icon: Icons.assignment_outlined,
              ),
              _StatCard(
                label: 'In progress',
                value: inProgress,
                icon: Icons.build_circle_outlined,
              ),
              _StatCard(
                label: 'Resolved',
                value: resolved,
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _borderColor),
        ),
        title: Text(
          '${AuthStore.currentUser?.supervisorIssueType ?? 'All'} reports',
          style: const TextStyle(
            color: _darkText,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: 480,
          child: groupedReports.isEmpty
              ? const Text(
            'No reports found for this report type.',
            style: TextStyle(color: _secondaryText),
          )
              : ListView.separated(
            shrinkWrap: true,
            itemCount: groupedReports.length,
            separatorBuilder: (_, _) => const Divider(
              color: _borderColor,
            ),
            itemBuilder: (context, index) {
              final group = groupedReports[index];
              final report = group.firstReport;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                title: Text(
                  'Report #${report.id}: '
                      '${report.issueType} - ${report.issue}',
                  style: const TextStyle(
                    color: _darkText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Reported by ${group.reporterCount} '
                      '${group.reporterCount == 1 ? 'person' : 'people'} '
                      '(first: ${report.senderName})\n'
                      'Date: ${report.createdAt.toLocal()}\n'
                      'Area: ${report.area} • Status: ${report.status}'
                      '${report.description.isEmpty ? '' : '\n${report.description}'}',
                  style: const TextStyle(
                    color: _secondaryText,
                    height: 1.5,
                  ),
                ),
                isThreeLine: true,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Close',
              style: TextStyle(
                color: _orange,
                fontWeight: FontWeight.w600,
              ),
            ),
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
  static const Color _orange = Color(0xFFC94F1B);
  static const Color _darkText = Color(0xFF292524);
  static const Color _secondaryText = Color(0xFF78716C);
  static const Color _borderColor = Color(0xFFE8C7B8);
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
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: _borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: _orange,
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
                        color: _darkText,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$date • $time',
                      style: const TextStyle(
                        color: _secondaryText,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$jobCount job(s) allocated today',
                      style: const TextStyle(
                        color: _secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: _orange,
              ),
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
  static const Color _orange = Color(0xFFC94F1B);
  static const Color _darkText = Color(0xFF292524);
  static const Color _secondaryText = Color(0xFF78716C);
  static const Color _borderColor = Color(0xFFE8C7B8);
  final String? reportType;
  final int count;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: _orange,
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
                        color: _darkText,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reportType == null
                          ? 'Tap to view today’s reports'
                          : 'Tap to view today’s $reportType reports',
                      style: const TextStyle(
                        color: _secondaryText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: _orange,
              ),
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
  static const Color _orange = Color(0xFFC94F1B);
  static const Color _darkText = Color(0xFF292524);
  static const Color _secondaryText = Color(0xFF78716C);
  static const Color _borderColor = Color(0xFFE8C7B8);
  final String label;
  final int value;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 155,
      child: Card(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: _borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: _orange,
                size: 27,
              ),
              const SizedBox(height: 12),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: _darkText,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  color: _secondaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}