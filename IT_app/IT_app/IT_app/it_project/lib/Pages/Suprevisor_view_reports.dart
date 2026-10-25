import 'package:flutter/material.dart';

import 'Supervisor_theme.dart';
import 'auth_store.dart';
import 'report_store.dart';
import 'StartUp.dart';

class AssignedJobsPage extends StatefulWidget {
  const AssignedJobsPage({super.key});

  @override
  State<AssignedJobsPage> createState() => _AssignedJobsPageState();
}

class _AssignedJobsPageState extends State<AssignedJobsPage> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthStore.currentUser;
    final reports = user?.isWorker == true
        ? ReportStore.reportsForWorker(user!.username)
        : const <ReportRequest>[];
    final isSupervisor = user?.isStaff == true;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assigned jobs'),
        backgroundColor: pagePrimaryColor(isSupervisor: isSupervisor),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () {
              AuthStore.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const StartupPage()),
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Container(
        decoration: pageBackgroundDecoration(isSupervisor: isSupervisor),
        child: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Job reports',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC94F1B),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Update the status of jobs assigned to you.'),
                const SizedBox(height: 18),
                if (reports.isEmpty)
                  const Text('No jobs have been assigned to you yet.')
                else
                  ...reports.map(
                    (report) => _AssignedJobCard(
                      report: report,
                      onChanged: () => setState(() {}),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: pagePrimaryColor(isSupervisor: isSupervisor),
        onPressed: () => _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        ),
        child: const Icon(Icons.arrow_upward, color: Colors.white),
      ),
    );
  }
}

class _AssignedJobCard extends StatelessWidget {
  const _AssignedJobCard({required this.report, required this.onChanged});

  final ReportRequest report;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final nextStatuses = switch (report.status) {
      'Assigned' => ['In progress'],
      'In progress' => ['On-site'],
      _ => <String>[],
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: Colors.white.withValues(alpha: 0.9),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${report.issueType}: ${report.issue}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC94F1B),
              ),
            ),
            const SizedBox(height: 6),
            Text('Customer: ${report.senderName}'),
            if (report.description.isNotEmpty)
              Text('Job details: ${report.description}'),
            const SizedBox(height: 8),
            Text(
              'Status: ${report.status}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (nextStatuses.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: nextStatuses.map((status) {
                  return OutlinedButton.icon(
                    onPressed: () {
                      ReportStore.updateStatus(report, status);
                      onChanged();
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(status),
                  );
                }).toList(),
              ),
            ],
            if (report.status == 'On-site' ||
                report.status == 'Completed' ||
                report.status == 'Finished') ...[
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () async {
                  final saved = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JobCompletionPage(report: report),
                    ),
                  );
                  if (saved == true) onChanged();
                },
                icon: const Icon(Icons.menu_book_outlined),
                label: Text(
                  report.status == 'Completed' || report.status == 'Finished'
                      ? 'View or edit invoice/logbook'
                      : 'Complete job logbook',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class JobCompletionPage extends StatefulWidget {
  const JobCompletionPage({
    required this.report,
    this.relatedReports = const [],
    super.key,
  });

  final ReportRequest report;
  final List<ReportRequest> relatedReports;

  @override
  State<JobCompletionPage> createState() => _JobCompletionPageState();
}

class _JobCompletionPageState extends State<JobCompletionPage> {
  late final Map<String, TextEditingController> _fields = {
    'Worker Name': TextEditingController(text: widget.report.workerName),
    'Worker ID': TextEditingController(text: widget.report.workerId),
    'Job number': TextEditingController(text: widget.report.jobNumber),
    'Location address': TextEditingController(
      text: widget.report.locationAddress,
    ),
    'Pin location': TextEditingController(text: widget.report.pinLocation),
    'Start time': TextEditingController(text: widget.report.startTime),
    'Stop time': TextEditingController(text: widget.report.stopTime),
    'Total time': TextEditingController(text: widget.report.totalTime),
    'Manager signature': TextEditingController(
      text: widget.report.managerSignature,
    ),
    'Worker signature': TextEditingController(
      text: widget.report.workerSignature,
    ),
  };

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (_fields.values.any((controller) => controller.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete every job completion field.')),
      );
      return;
    }
    ReportStore.saveJobCompletion(
      report: widget.report,
      relatedReports: widget.relatedReports,
      workerName: _fields['Worker Name']!.text,
      workerId: _fields['Worker ID']!.text,
      jobNumber: _fields['Job number']!.text,
      locationAddress: _fields['Location address']!.text,
      pinLocation: _fields['Pin location']!.text,
      startTime: _fields['Start time']!.text,
      stopTime: _fields['Stop time']!.text,
      totalTime: _fields['Total time']!.text,
      managerSignature: _fields['Manager signature']!.text,
      workerSignature: _fields['Worker signature']!.text,
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.now().toLocal().toString().split(' ').first;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice / job logbook'),
        backgroundColor: const Color(0xFFC94F1B),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: pageBackgroundDecoration(isSupervisor: true),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.business, size: 58, color: Color(0xFFC94F1B)),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'COMPANY LOGBOOK',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  widget.report.invoiceNumber ??
                      'LOG-${widget.report.id.toString().padLeft(4, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 28),
              _ReadOnlyField(
                label: 'Customer',
                value: widget.report.senderName,
              ),
              _ReadOnlyField(label: 'Date', value: date),
              _ReadOnlyField(
                label: 'Type of issue',
                value: widget.report.issueType,
              ),
              _ReadOnlyField(
                label: 'Type of problem',
                value: widget.report.issue,
              ),
              _ReadOnlyField(
                label: 'Job field description',
                value: widget.report.description.isEmpty
                    ? 'None provided'
                    : widget.report.description,
              ),
              const SizedBox(height: 18),
              const Text(
                'Worker completion details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...['Worker Name', 'Worker ID', 'Job number'].map(_input),
              _input(
                'Pin location',
                hint: 'Latitude, longitude, or map pin reference',
              ),
              _input(
                'Location address',
                hint: 'Use this when a pin cannot be added',
              ),
              ...['Start time', 'Stop time', 'Total time'].map(_input),
              const SizedBox(height: 12),
              const Text(
                'Sign-off',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              _input('Manager signature'),
              _input('Worker signature'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Save invoice and complete job'),
              ),
              if (widget.report.invoiceSubmissionStatus.isNotEmpty)
                Text(
                  'Admin submission status: '
                  '${widget.report.invoiceSubmissionStatus}. '
                  'The shared backend must be connected before this invoice '
                  'can be sent to the admin.',
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(String label, {String? hint}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: _fields[label],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    ),
  );
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        initialValue: value,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
