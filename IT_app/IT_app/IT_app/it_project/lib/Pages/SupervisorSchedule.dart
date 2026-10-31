
import 'dart:async';

import 'package:flutter/material.dart';

import 'api_paths.dart';
import 'Suprevisor_view_reports.dart';
import 'Supervisor_theme.dart';
import 'auth_store.dart';
import 'report_store.dart';

class SupervisorSchedulePage extends StatefulWidget {
  final DateTime day;

  const SupervisorSchedulePage({
    super.key,
    required this.day,
  });

  @override
  State<SupervisorSchedulePage> createState() =>
      _SupervisorSchedulePageState();
}

class _SupervisorSchedulePageState
    extends State<SupervisorSchedulePage> {
  DateTime _now = DateTime.now();

  Timer? _timer;

  List<ReportRequest> _reports = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _fetchAssignedReports();

    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Checks whether a report has already been completed.
  bool _isResolved(ReportRequest report) {
    final status = report.status.trim().toLowerCase();

    return status == 'resolved' ||
        status == 'completed' ||
        status == 'finished';
  }

  // Loads all outstanding reports assigned to the supervisor.
  Future<void> _fetchAssignedReports() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final user = AuthStore.currentUser;

      if (user == null) {
        throw Exception('No supervisor is currently logged in.');
      }

      final response = await AuthStore.withAccessToken(
            (api, token) async {
          return await api.getRaw(
            ApiPaths.reportsForSupervisor(user.username),
            accessToken: token,
          );
        },
      );

      final List<ReportRequest> fetchedReports =
      (response as List).map((json) {
        return ReportRequest.fromJson(
          Map<String, dynamic>.from(json as Map),
        );
      }).where((report) {
        return !_isResolved(report);
      }).toList();

      // Sorts reports by their latest assignment date.
      fetchedReports.sort((a, b) {
        final dateA = a.scheduledAt ?? a.createdAt;
        final dateB = b.scheduledAt ?? b.createdAt;

        return dateB.compareTo(dateA);
      });

      if (!mounted) return;

      setState(() {
        _reports = fetchedReports;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Groups related reports and sorts the groups by their newest assignment.
  List<ReportGroup> _getGroups() {
    // Creates a modifiable list before sorting.
    final groups = ReportStore.groupReports(_reports).toList();

    groups.sort((first, second) {
      DateTime latestAssignment(ReportGroup group) {
        DateTime latest =
            group.firstReport.scheduledAt ??
                group.firstReport.createdAt;

        for (final report in group.reports) {
          final date = report.scheduledAt ?? report.createdAt;

          if (date.isAfter(latest)) {
            latest = date;
          }
        }

        return latest;
      }

      return latestAssignment(second).compareTo(
        latestAssignment(first),
      );
    });

    return groups;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final groups = _getGroups();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: pageBackgroundDecoration(isSupervisor: true),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Today\'s Schedule',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Outstanding Schedule',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(_now),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(_now),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${groups.length} outstanding jobs',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Expanded(
                child: _isLoading
                    ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                )
                    : _errorMessage != null
                    ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Could not load your schedule.\n$_errorMessage',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _fetchAssignedReports,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
                    : groups.isEmpty
                    ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'You have no outstanding assigned jobs.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
                    : RefreshIndicator(
                  onRefresh: _fetchAssignedReports,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      0,
                      20,
                      24,
                    ),
                    itemCount: groups.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      final report = group.firstReport;

                      final assignedDate =
                          report.scheduledAt ??
                              report.createdAt;

                      return _buildScheduleCard(
                        group,
                        assignedDate,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Displays an individual grouped job on the schedule.
  Widget _buildScheduleCard(
      ReportGroup group,
      DateTime assignedDate,
      ) {
    final report = group.firstReport;

    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return SupervisorScheduledJobPage(group: group);
              },
            ),
          );

          if (mounted) {
            _fetchAssignedReports();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      report.issueType,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                report.area,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 15,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Assigned: ${_formatDate(assignedDate)} '
                        '${_formatTime(assignedDate)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${group.reporterCount} reporter(s)',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      report.status,
                      style: const TextStyle(
                        color: Colors.deepOrange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Displays the details of a selected scheduled job.
class SupervisorScheduledJobPage extends StatefulWidget {
  final ReportGroup group;

  const SupervisorScheduledJobPage({
    super.key,
    required this.group,
  });

  @override
  State<SupervisorScheduledJobPage> createState() =>
      _SupervisorScheduledJobPageState();
}

class _SupervisorScheduledJobPageState
    extends State<SupervisorScheduledJobPage> {
  late ReportGroup _group;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
  }

  // Updates the status of all reports in the selected group.
  void _advanceStatus() {
    final currentStatus = _group.firstReport.status;

    String? nextStatus;

    if (currentStatus == 'Assigned') {
      nextStatus = 'In progress';
    } else if (currentStatus == 'In progress') {
      nextStatus = 'On-site';
    }

    if (nextStatus == null) return;

    for (final report in _group.reports) {
      ReportStore.updateStatus(report, nextStatus);
    }

    setState(() {});
  }

  // Opens the job completion and invoice page.
  void _openInvoice() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return JobCompletionPage(
            report: _group.firstReport,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = _group.firstReport;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Scheduled Job'),
        backgroundColor: pagePrimaryColor(isSupervisor: true),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: pageBackgroundDecoration(isSupervisor: true),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.issueType,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _detailRow('Area', report.area),
                        _detailRow('Issue', report.issue),
                        _detailRow(
                          'Description',
                          report.description,
                        ),
                        _detailRow(
                          'Reporters',
                          '${_group.reporterCount}',
                        ),
                        _detailRow(
                          'Status',
                          report.status,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Job Progress',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _progressStep(
                          'Assigned',
                          report.status == 'Assigned' ||
                              report.status == 'In progress' ||
                              report.status == 'On-site',
                        ),
                        _progressStep(
                          'In progress',
                          report.status == 'In progress' ||
                              report.status == 'On-site',
                        ),
                        _progressStep(
                          'On-site',
                          report.status == 'On-site',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: report.status == 'On-site'
                        ? null
                        : _advanceStatus,
                    child: const Text('Update Job Status'),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openInvoice,
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('View Invoice / Complete Job'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressStep(String title, bool completed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            completed
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: completed ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: completed ? Colors.green : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
