import 'package:flutter/material.dart';

import 'CheckStatus.dart';
import 'Help.dart';
import 'auth_store.dart';
import 'report_summary_tile.dart';
import 'report_store.dart';
import 'Supervisor_theme.dart';

class OtherReportsPage extends StatefulWidget {
  const OtherReportsPage({super.key, this.initialFilter = 'All'});

  final String initialFilter;

  @override
  State<OtherReportsPage> createState() => _OtherReportsPageState();
}

class _OtherReportsPageState extends State<OtherReportsPage> {
  late String selectedFilter;

  @override
  void initState() {
    super.initState();
    selectedFilter = widget.initialFilter;
  }

  List<ReportRequest> get reports => ReportStore.reports;

  @override
  Widget build(BuildContext context) {
    final isSupervisor = AuthStore.currentUser?.isStaff == true;
    final filteredReports = selectedFilter == 'All'
        ? reports
        : reports
              .where((report) => report.issueType == selectedFilter)
              .toList();
    final groupedReports = ReportStore.groupReports(filteredReports);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: pagePrimaryColor(isSupervisor: isSupervisor),
        title: const Text('View Other Reports'),
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Community reports',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _showFilterDialog,
                      icon: const Icon(Icons.filter_list),
                      label: Text(
                        selectedFilter == 'All' ? 'Filter' : selectedFilter,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: groupedReports.isEmpty
                    ? const Center(
                        child: Text(
                          'No reports found for this filter.',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        itemCount: groupedReports.length,
                        itemBuilder: (context, index) =>
                            _reportCard(groupedReports[index]),
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: pagePrimaryColor(isSupervisor: isSupervisor),
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StatusPage()),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpPage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Status',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.help), label: 'Help'),
        ],
      ),
    );
  }

  Widget _reportCard(ReportGroup group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ReportSummaryTile(group: group),
      ),
    );
  }

  void _showFilterDialog() {
    String temporaryFilter = selectedFilter;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter reports'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...[
                'All',
                ...reports.map((report) => report.issueType).toSet(),
              ].map(
                (filter) => RadioListTile<String>(
                  title: Text(filter == 'All' ? 'All reports' : filter),
                  value: filter,
                  groupValue: temporaryFilter,
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => temporaryFilter = value);
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => selectedFilter = temporaryFilter);
                Navigator.pop(dialogContext);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}
