import 'package:flutter/material.dart';

import 'Help.dart';
import 'auth_store.dart';
import 'report_store.dart';
import 'Supervisor_theme.dart';

class StatusPage extends StatefulWidget {
  const StatusPage({super.key});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  List<Map<String, String>> get reports => ReportStore.reports
      .map(
        (report) => {
          'id': report.id.toString().padLeft(3, '0'),
          'issue': report.issue,
          'addInfo': report.description,
          'location': report.locationAddress,
          'createdAt': report.createdAt.toLocal().toString(),
          'submittedAt':
              report.submittedAt?.toLocal().toString() ?? 'Not submitted yet',
          'date': report.createdAt.toLocal().toString(),
          'status': report.status,
          'syncStatus': report.syncStatus,
          'storageType': report.storageType,
        },
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    final isSupervisor = AuthStore.currentUser?.isStaff == true;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: pagePrimaryColor(isSupervisor: isSupervisor),
        title: const Text('Check Status'),
        actions: [
          IconButton(
            tooltip: 'Refresh reports',
            icon: const Icon(Icons.refresh),
            onPressed: _refreshReports,
          ),
          IconButton(
            tooltip: 'Help',
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpPage()),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: pageBackgroundDecoration(isSupervisor: isSupervisor),
        child: SafeArea(
          child: reports.isEmpty
              ? const Center(
                  child: Text(
                    'No reports available.',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    return _reportEntry(context, report);
                  },
                ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: pagePrimaryColor(isSupervisor: isSupervisor),
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpPage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'My Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.help_outline),
            label: 'Help',
          ),
        ],
      ),
    );
  }

  Widget _reportEntry(BuildContext context, Map<String, String> report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFC94F1B),
          child: Icon(Icons.description_outlined, color: Colors.white),
        ),
        title: Text(
          'Report #${report['id']}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Created: ${report['createdAt']}\nSubmitted: ${report['submittedAt']}\n${report['syncStatus'] ?? 'Pending sync'}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ReportDetailsPage(report: report)),
        ),
      ),
    );
  }

  void _refreshReports() {
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reports refreshed.')));
  }
}

class ReportDetailsPage extends StatelessWidget {
  const ReportDetailsPage({super.key, required this.report});

  final Map<String, String> report;

  @override
  Widget build(BuildContext context) {
    final isSupervisor = AuthStore.currentUser?.isStaff == true;
    return Scaffold(
      appBar: AppBar(
        title: Text('Report #${report['id']}'),
        actions: [
          IconButton(
            tooltip: 'Help',
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpPage()),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: pageBackgroundDecoration(isSupervisor: isSupervisor),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Report #${report['id']} details',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _detailField(
                    'Creation time',
                    report['createdAt'] ?? 'Not available',
                  ),
                  _detailField(
                    'Submitted time',
                    report['submittedAt'] ?? 'Not submitted yet',
                  ),
                  _detailField(
                    'Type of issue',
                    report['issue'] ?? 'Not available',
                  ),
                  _detailField(
                    'Location',
                    report['location'] ?? 'Not available',
                  ),
                  _detailField(
                    'Additional information',
                    report['addInfo']?.isEmpty == true
                        ? 'No additional information'
                        : report['addInfo'] ?? 'No additional information',
                  ),
                  _detailField('Status', report['status'] ?? 'Not available'),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to reports'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        initialValue: value,
        readOnly: true,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
