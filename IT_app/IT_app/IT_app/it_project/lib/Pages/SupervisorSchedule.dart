import 'dart:async';

import 'package:flutter/material.dart';

import 'Suprevisor_view_reports.dart';
import 'Supervisor_theme.dart';
import 'auth_store.dart';
import 'report_store.dart';

class SupervisorSchedulePage extends StatefulWidget {
  const SupervisorSchedulePage({super.key, required this.day});

  final DateTime day;

  @override
  State<SupervisorSchedulePage> createState() => _SupervisorSchedulePageState();
}

class _SupervisorSchedulePageState extends State<SupervisorSchedulePage> {
  late DateTime _now;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
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
    final username = AuthStore.currentUser?.username ?? '';
    final reports = ReportStore.reportsForSupervisorOnDate(
      supervisorUsername: username,
      date: widget.day,
    );
    final groups = ReportStore.groupReports(reports);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today’s schedule'),
        backgroundColor: pagePrimaryColor(isSupervisor: true),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: pageBackgroundDecoration(isSupervisor: true),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                color: Colors.white.withValues(alpha: 0.92),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(widget.day),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC94F1B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('Current time: ${_formatTime(_now)}'),
                      Text('${groups.length} job(s) allocated for this day'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (groups.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('No jobs have been allocated for this day.'),
                  ),
                )
              else
                ...groups.map(
                  (group) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: Colors.white.withValues(alpha: 0.92),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFC94F1B),
                        foregroundColor: Colors.white,
                        child: Icon(Icons.assignment_outlined),
                      ),
                      title: Text(
                        'Report #${group.firstReport.id}: '
                        '${group.firstReport.issueType}',
                      ),
                      subtitle: Text(
                        '${group.firstReport.issue} • ${group.firstReport.area}\n'
                        '${_formatTime(group.firstReport.scheduledAt ?? widget.day)}'
                        ' • ${group.reporterCount} '
                        '${group.reporterCount == 1 ? 'reporter' : 'reporters'}'
                        '\nStatus: ${group.firstReport.status}',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              SupervisorScheduledJobPage(group: group),
                        ),
                      ).then((_) {
                        if (mounted) setState(() {});
                      }),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _formatTime(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}

class SupervisorScheduledJobPage extends StatefulWidget {
  const SupervisorScheduledJobPage({super.key, required this.group});

  final ReportGroup group;

  @override
  State<SupervisorScheduledJobPage> createState() =>
      _SupervisorScheduledJobPageState();
}

class _SupervisorScheduledJobPageState
    extends State<SupervisorScheduledJobPage> {
  ReportRequest get report => widget.group.firstReport;

  Future<void> _openInvoice() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => JobCompletionPage(
          report: report,
          relatedReports: widget.group.reports,
        ),
      ),
    );
    if (saved == true && mounted) {
      setState(() {});
    }
  }

  void _advanceStatus() {
    final nextStatus = switch (report.status) {
      'Assigned' => 'In progress',
      'In progress' => 'On-site',
      _ => null,
    };
    if (nextStatus == null) return;

    for (final relatedReport in widget.group.reports) {
      ReportStore.updateStatus(relatedReport, nextStatus);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final nextStatus = switch (report.status) {
      'Assigned' => 'In progress',
      'In progress' => 'On-site',
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text('Report #${report.id}'),
        backgroundColor: pagePrimaryColor(isSupervisor: true),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: pageBackgroundDecoration(isSupervisor: true),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              color: Colors.white.withValues(alpha: 0.92),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${report.issueType}: ${report.issue}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('Area: ${report.area}'),
                    Text('Customer: ${report.senderName}'),
                    Text(
                      'Scheduled: '
                      '${report.scheduledAt?.toLocal().toString() ?? 'Not scheduled'}',
                    ),
                    Text(
                      'Reported by ${widget.group.reporterCount} '
                      '${widget.group.reporterCount == 1 ? 'person' : 'people'}',
                    ),
                    if (report.description.isNotEmpty)
                      Text('Details: ${report.description}'),
                    const SizedBox(height: 12),
                    Text(
                      'Status: ${report.status}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _progressChip('In progress'),
                        _progressChip('On-site'),
                        _progressChip('Completed'),
                      ],
                    ),
                    if (nextStatus != null) ...[
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _advanceStatus,
                        icon: const Icon(Icons.arrow_forward),
                        label: Text('Mark $nextStatus'),
                      ),
                    ],
                    if (report.status == 'On-site' ||
                        report.status == 'Completed') ...[
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: _openInvoice,
                        icon: const Icon(Icons.receipt_long_outlined),
                        label: Text(
                          report.status == 'Completed'
                              ? 'View invoice'
                              : 'Complete job and submit invoice',
                        ),
                      ),
                      if (report.invoiceSubmissionStatus.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Invoice: ${report.invoiceSubmissionStatus}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressChip(String status) {
    const progressOrder = ['In progress', 'On-site', 'Completed'];
    final currentIndex = switch (report.status) {
      'In progress' => 0,
      'On-site' => 1,
      'Completed' || 'Finished' => 2,
      _ => -1,
    };
    final statusIndex = progressOrder.indexOf(status);
    final isReached = currentIndex >= statusIndex;
    return Chip(
      avatar: Icon(
        isReached ? Icons.check_circle : Icons.radio_button_unchecked,
        size: 18,
      ),
      label: Text(status),
      backgroundColor: isReached
          ? const Color(0xFFB9E4F5)
          : Colors.white.withValues(alpha: 0.8),
    );
  }
}
