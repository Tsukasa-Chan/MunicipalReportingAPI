import 'dart:async';
import 'package:flutter/material.dart';
import 'api_paths.dart';
import 'auth_api.dart';
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
  // Darker orange used throughout the supervisor screens.
  static const Color _orange = supervisorPrimaryColor;
  static const Color _darkText = Color(0xFF292524);
  static const Color _secondaryText = Color(0xFF78716C);
  static const Color _cream = Color(0xFFF5F5F5);
  static const Color _borderColor = Color(0xFFE7E5E4);
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
  // One job is one backend Issue, even when several residents reported it.
  // Legacy reports without issueId retain their existing grouping behaviour.
  List<ReportGroup> _getGroups() {
    final byIssueId = <int, List<ReportRequest>>{};
    final legacyReports = <ReportRequest>[];
    for (final report in _reports) {
      final issueId = report.issueId;
      if (issueId != null && issueId > 0) {
        byIssueId.putIfAbsent(issueId, () => []).add(report);
      } else {
        legacyReports.add(report);
      }
    }
    final groups = <ReportGroup>[
      ...byIssueId.values.map(ReportGroup.fromReports),
      ...ReportStore.groupReports(legacyReports),
    ];
    groups.sort((first, second) {
      DateTime latestAssignment(ReportGroup group) {
        DateTime latest = group.firstReport.scheduledAt ??
            group.firstReport.createdAt;
        for (final report in group.reports) {
          final date = report.scheduledAt ?? report.createdAt;
          if (date.isAfter(latest)) latest = date;
        }
        return latest;
      }
      return latestAssignment(second).compareTo(latestAssignment(first));
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
      backgroundColor: const Color(0xFFF5F5F5),
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
                        color: _darkText,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Today\'s Schedule',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _darkText,
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Outstanding Schedule',
                        style: TextStyle(
                          color: _darkText,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(_now),
                        style: const TextStyle(
                          color: _secondaryText,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: _orange,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(_now),
                            style: const TextStyle(
                              color: _darkText,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Flexible(
                            child: Text(
                              '${groups.length} outstanding jobs',
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                color: _orange,
                                fontWeight: FontWeight.bold,
                              ),
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
                    color: _orange,
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
                          color: _orange,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Could not load your schedule.\n$_errorMessage',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _darkText,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(12),
                            ),
                          ),
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
                        color: _darkText,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
                    : RefreshIndicator(
                  color: _orange,
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
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: _borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
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
          padding: const EdgeInsets.all(17),
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
                        color: _darkText,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: _orange,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                report.area,
                style: const TextStyle(
                  fontSize: 14,
                  color: _secondaryText,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 15,
                    color: _orange,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Assigned: ${_formatDate(assignedDate)} '
                          '${_formatTime(assignedDate)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 16,
                    color: _secondaryText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${group.reporterCount} reporter(s)',
                    style: const TextStyle(
                      fontSize: 13,
                      color: _secondaryText,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5EBE7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      report.status,
                      style: const TextStyle(
                        color: _orange,
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
  // Darker orange used throughout the supervisor screens.
  static const Color _orange = supervisorPrimaryColor;
  static const Color _darkText = Color(0xFF292524);
  static const Color _secondaryText = Color(0xFF78716C);
  static const Color _borderColor = Color(0xFFE7E5E4);
  static const Color _cream = Color(0xFFF5F5F5);
  late ReportGroup _group;
  @override
  void initState() {
    super.initState();
    _group = widget.group;
  }
  bool _isUpdatingStatus = false;
  String? _selectedStatus;

  // Save the shared municipal Issue status first; only update the visible
  // resident reports after the server confirms that the change succeeded.
  Future<void> _changeIssueStatus() async {
    if (_isUpdatingStatus || _selectedStatus == null) return;
    final nextStatus = _selectedStatus!;
    final current = _group.firstReport.status.trim();
    final normalizedCurrent = current == 'In progress' ? 'InProgress' : current;
    if (nextStatus == normalizedCurrent ||
        !const {'Reported', 'InProgress', 'Resolved'}.contains(nextStatus)) {
      return;
    }

    final issueIds = _group.reports.map((report) => report.issueId).toSet();
    if (issueIds.length != 1 || issueIds.single == null ||
        issueIds.single! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(
            'This job has no valid Issue ID. Ensure the backend returns issueId.'
        )),
      );
      return;
    }

    setState(() => _isUpdatingStatus = true);
    try {
      await AuthStore.withAccessToken(
            (api, token) => api.updateIssueStatus(
          accessToken: token,
          issueId: issueIds.single!,
          status: nextStatus,
        ),
      );
      if (!mounted) return;
      setState(() {
        for (final report in _group.reports) {
          report.status = nextStatus;
        }
        _selectedStatus = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
            'Issue status updated to ${nextStatus == 'InProgress' ? 'In progress' : nextStatus}.'
        )),
      );
    } on AuthApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update the issue status. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = _group.firstReport;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Scheduled Job',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: pagePrimaryColor(isSupervisor: true),
        foregroundColor: Colors.white,
        elevation: 0,
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
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: _borderColor),
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
                            color: _darkText,
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
                const SizedBox(height: 24),
                const Text(
                  'Job Progress',
                  style: TextStyle(
                    color: _darkText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  color: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: _borderColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _progressStep('Reported', 'Reported'),
                        _progressStep('In progress', 'InProgress'),
                        _progressStep('Resolved', 'Resolved'),
                        if (_isUpdatingStatus)
                          const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: LinearProgressIndicator(color: _orange),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Select a status above, then confirm your change.',
                  style: TextStyle(color: _secondaryText, fontSize: 13),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isUpdatingStatus ||
                        _selectedStatus == null ||
                        _selectedStatus == _currentStatus ||
                        !_hasValidIssueId
                        ? null
                        : _changeIssueStatus,
                    child: Text(
                      _isUpdatingStatus
                          ? 'Updating...'
                          : 'Confirm Status Change',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                if (report.issueId == null || report.issueId! <= 0)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Status updating requires issueId in the assigned-reports API response.',
                      style: TextStyle(color: Colors.redAccent, fontSize: 12),
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
                color: _darkText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _secondaryText,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
  String get _currentStatus {
    final status = _group.firstReport.status.trim();
    return status == 'In progress' ? 'InProgress' : status;
  }

  bool get _hasValidIssueId {
    final ids = _group.reports.map((report) => report.issueId).toSet();
    return ids.length == 1 && ids.single != null && ids.single! > 0;
  }

  Widget _progressStep(String title, String status) {
    final isCurrent = _currentStatus == status;
    final isPending = _selectedStatus == status && !isCurrent;
    final canSelect = !_isUpdatingStatus && _hasValidIssueId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: isPending || (isCurrent && _selectedStatus == null)
            ? const Color(0xFFFFF1E8)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: canSelect
              ? () => setState(() {
            _selectedStatus = isCurrent ? null : status;
          })
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  isCurrent
                      ? Icons.check_circle
                      : isPending
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isCurrent || isPending
                      ? _orange
                      : const Color(0xFFBDB8B4),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: isCurrent || isPending
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: isCurrent || isPending ? _orange : _darkText,
                    ),
                  ),
                ),
                if (isCurrent)
                  const Text(
                    'Current',
                    style: TextStyle(color: _orange, fontSize: 12),
                  )
                else if (isPending)
                  const Text(
                    'Selected',
                    style: TextStyle(color: _orange, fontSize: 12),
                  )
                else if (canSelect)
                    const Icon(
                      Icons.touch_app_outlined,
                      color: _orange,
                      size: 20,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
