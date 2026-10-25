import 'dart:io';

import 'package:flutter/material.dart';

import 'ContactUs.dart';
import 'Help.dart';
import 'OtherReports.dart';
import 'Profile.dart';
import 'Reporting.dart';
import 'Settings.dart';
import 'StartUp.dart';
import 'auth_store.dart';
import 'report_store.dart';
import 'report_summary_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final locationController = TextEditingController();
  final addInfoController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  File? imageIssue;
  final issue = [
    'Potholes',
    'Faulty traffic lights',
    'Broken street lights',
    'Burst water pipes',
    'Road closure',
    'Other',
  ];
  final formKey = GlobalKey<FormState>();

  String? choice;
  String location = '';
  String? additionalInfo;
  late final String selectedArea;

  final areaReportCounts = const {
    'Water': 1,
    'Road': 2,
    'Electricity': 3,
    'Waste': 1,
  };

  @override
  void initState() {
    super.initState();
    selectedArea = AuthStore.currentUser?.ward ?? 'Not set';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'FIX MY CITY',
              style: TextStyle(color: Colors.white, fontSize: 30),
            ),
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(6)),
              child: Image.asset(
                'lib/img/app logo.png',
                width: 42,
                height: 42,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.help, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpPage()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.red),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'lib/img/app logo.png',
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Menu',
                    style: TextStyle(color: Colors.white, fontSize: 25),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Contact Us'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ContactPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('My Ward'),
              subtitle: Text(selectedArea),
              onTap: _openMyWard,
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                AuthStore.logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const StartupPage()),
                      (_) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F5F5), Color(0xFFF5F5F5)],
          ),
        ),
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildAreaStatistics(context),
              const SizedBox(height: 20),
              _buildMyAreaSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        backgroundColor: Colors.red,
        selectedItemColor: Colors.white,
        onTap: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OtherReportsPage()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportingPage()),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'View Complaints',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'New Report'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  void _openMyWard() {
    Navigator.pop(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AreaDetailPage(areaName: selectedArea),
        ),
      );
    });
  }

  Widget _buildMyAreaSection() {
    final inProgressGroups = ReportStore.groupReports(
      ReportStore.reportsForArea(
        selectedArea,
      ).where((report) => report.status.trim().toLowerCase() == 'in progress'),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Ward',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  selectedArea,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AreaDetailPage(areaName: selectedArea),
                  ),
                ),
                icon: const Icon(Icons.open_in_new),
                label: const Text('View ward reports'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.assignment_outlined, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      'Reports in progress • $selectedArea',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (inProgressGroups.isEmpty)
                  Text('No reports in progress for $selectedArea.')
                else
                  ...inProgressGroups.map(
                        (group) => ReportSummaryTile(group: group),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaStatistics(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Statistics of Area',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'DESAINAGAR',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 22),
          const Text(
            'Problems in area',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _statRow(
            context,
            label: 'Water',
            count: areaReportCounts['Water']!,
            filter: 'Water and Sanitation',
            icon: Icons.water_drop_outlined,
            color: Colors.blue,
          ),
          _statRow(
            context,
            label: 'Road',
            count: areaReportCounts['Road']!,
            filter: 'Roads and Stormwater',
            icon: Icons.alt_route,
            color: const Color(0xFFC94F1B),
          ),
          _statRow(
            context,
            label: 'Electricity',
            count: areaReportCounts['Electricity']!,
            filter: 'Electricity',
            icon: Icons.bolt,
            color: Colors.blueGrey,
          ),
          _statRow(
            context,
            label: 'Waste',
            count: areaReportCounts['Waste']!,
            filter: 'Waste Management',
            icon: Icons.delete_outline,
            color: Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _statRow(
      BuildContext context, {
        required String label,
        required int count,
        required String filter,
        required IconData icon,
        required Color color,
      }) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtherReportsPage(initialFilter: filter),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '$count reports',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    locationController.dispose();
    addInfoController.dispose();
    super.dispose();
  }
}

class AreaDetailPage extends StatefulWidget {
  const AreaDetailPage({super.key, required this.areaName});

  final String areaName;

  @override
  State<AreaDetailPage> createState() => _AreaDetailPageState();
}

class _AreaDetailPageState extends State<AreaDetailPage> {
  @override
  Widget build(BuildContext context) {
    final areaReports = ReportStore.reportsForArea(widget.areaName);
    final groupedAreaReports = ReportStore.groupReports(areaReports);

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white, title: Text(widget.areaName)),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F5F5), Color(0xFFF5F5F5)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reports for ${widget.areaName}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Ward updates and reports are grouped here for quick access.',
                        style: TextStyle(color: Colors.black87),
                      ),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AreaReportsPage(areaName: widget.areaName),
                              ),
                            );
                          },
                          icon: const Icon(Icons.assignment_turned_in),
                          label: Text('Reports for ${widget.areaName}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.assignment_outlined,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Community reports • ${widget.areaName}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Read-only updates for this area.',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      if (groupedAreaReports.isEmpty)
                        Text('No reports available for ${widget.areaName}.')
                      else
                        ...groupedAreaReports.map(
                              (group) => ReportSummaryTile(group: group),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AreaReportsPage extends StatelessWidget {
  const AreaReportsPage({super.key, required this.areaName});

  final String areaName;

  @override
  Widget build(BuildContext context) {
    final areaReports = ReportStore.reportsForArea(areaName);
    final groupedAreaReports = ReportStore.groupReports(areaReports);

    return Scaffold(
      appBar: AppBar(
        title: Text('Reports for $areaName'),
        backgroundColor: Colors.red,
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        color: const Color(0xFFF5F5F5),
        child: groupedAreaReports.isEmpty
            ? Center(
          child: Text(
            'No reports available for $areaName yet.',
            style: const TextStyle(fontSize: 18),
          ),
        )
            : ListView.builder(
          itemCount: groupedAreaReports.length,
          itemBuilder: (context, index) {
            final group = groupedAreaReports[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ReportSummaryTile(group: group),
              ),
            );
          },
        ),
      ),
    );
  }
}