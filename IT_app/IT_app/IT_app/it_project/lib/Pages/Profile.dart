import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:public_file_saver/public_file_saver.dart';
import 'dart:typed_data';

import 'ContactUs.dart';
import 'EditProfile.dart';
import 'Help.dart';
import 'OtherReports.dart';
import 'Reporting.dart';
import 'StartUp.dart';
import 'auth_api.dart';
import 'auth_store.dart';
import 'report_store.dart';
import 'Supervisor_theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final scrollController = ScrollController();
  final Set<int> _refreshingReportStatus = {};
  final Map<int, String> _reportStatusErrors = {};
  bool _deleting = false;

  static const _orange = Color(0xFFC94F1B);
  static const _darkText = Color(0xFF292524);
  static const _secondaryText = Color(0xFF78716C);
  static const _borderColor = Color(0xFFE8C7B8);

  @override
  void initState() {
    super.initState();
    _reloadProfile();
  }

  Future<void> _reloadProfile() async {
    try {
      await AuthStore.reloadProfile();
      if (mounted) setState(() {});
    } on AuthApiException catch (error) {
      if (error.isSessionExpired && mounted) _goToStart();
    } catch (_) {
      // Continue displaying cached profile data when offline.
    }
  }

  void _goToStart() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const StartupPage()),
      (_) => false,
    );
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> _refreshReportStatus(ReportRequest report) async {
    final issueId = report.issueId;
    if (issueId == null ||
        !report.isSubmitted ||
        _refreshingReportStatus.contains(report.id)) {
      return;
    }

    setState(() {
      _refreshingReportStatus.add(report.id);
      _reportStatusErrors.remove(report.id);
    });

    try {
      final issue = await AuthStore.withAccessToken(
        (api, token) => api.getIssueDetails(
          issueId: issueId,
          accessToken: token,
        ),
      );
      final status = issue['status']?.toString().trim() ?? '';
      if (status.isEmpty) {
        throw const AuthApiException(
          'The server did not return a status for this issue.',
        );
      }

      await ReportStore.updateIssueDetails(
        report: report,
        status: status,
        scheduledAt: DateTime.tryParse(
          issue['scheduledAt']?.toString() ?? '',
        )?.toLocal(),
        updatedAt: DateTime.tryParse(
          issue['updatedAt']?.toString() ?? '',
        )?.toLocal(),
      );
    } on AuthApiException catch (error) {
      if (error.isSessionExpired && mounted) {
        _goToStart();
      } else if (mounted) {
        setState(() => _reportStatusErrors[report.id] = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _reportStatusErrors[report.id] =
              'Could not refresh this report status. Check your connection and try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _refreshingReportStatus.remove(report.id));
      }
    }
  }

  String _statusLabel(String status) => switch (status) {
    'Reported' => 'Reported',
    'InProgress' => 'In progress',
    'Resolved' => 'Resolved',
    'Pending' => 'Pending',
    _ => status.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match[1]} ${match[2]}',
    ),
  };

  String _timelineDate(DateTime? date) {
    if (date == null) return 'Date unavailable';
    final local = date.toLocal();
    final localizations = MaterialLocalizations.of(context);
    return '${localizations.formatMediumDate(local)} · '
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
  }

  Widget _reportTimeline(ReportRequest report) {
    final entries = <(String, String, IconData)>[
      (
        report.isSubmitted ? 'Report submitted' : 'Saved on this device',
        report.isSubmitted
            ? _timelineDate(report.submittedAt)
            : '${_timelineDate(report.createdAt)} · Waiting to sync',
        report.isSubmitted ? Icons.outgoing_mail : Icons.save_outlined,
      ),
    ];

    if (report.scheduledAt != null) {
      entries.add((
        'Assigned to municipal team',
        _timelineDate(report.scheduledAt),
        Icons.assignment_ind_outlined,
      ));
    }

    entries.add((
      'Current status: ${_statusLabel(report.status)}',
      report.updatedAt == null
          ? 'Latest status'
          : 'Last updated ${_timelineDate(report.updatedAt)}',
      report.status == 'Resolved' ? Icons.check_circle_outline : Icons.update,
    ));

    final canRefresh = report.issueId != null && report.isSubmitted;
    final isRefreshing = _refreshingReportStatus.contains(report.id);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Report timeline',
                  style: TextStyle(
                    color: _darkText,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (canRefresh)
                IconButton(
                  tooltip: 'Refresh status',
                  onPressed: isRefreshing
                      ? null
                      : () => _refreshReportStatus(report),
                  icon: isRefreshing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, color: _orange),
                ),
            ],
          ),
          const SizedBox(height: 8),
          for (var index = 0; index < entries.length; index++)
            _timelineStep(
              title: entries[index].$1,
              subtitle: entries[index].$2,
              icon: entries[index].$3,
              isLast: index == entries.length - 1,
            ),
          if (!canRefresh)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Live status is unavailable for this saved report.',
                style: TextStyle(fontSize: 12, color: _secondaryText),
              ),
            ),
          if (_reportStatusErrors[report.id] case final error?)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                error,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'This shows the latest status; past status changes are not available.',
              style: TextStyle(fontSize: 12, color: _secondaryText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineStep({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Icon(icon, size: 20, color: _orange),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: _borderColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _darkText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editReport(ReportRequest report) async {
    if (report.backendId == null ||
        report.areaId == null ||
        report.latitude == null ||
        report.longitude == null) {
      _message(
        'This older saved report does not have enough verified server information to edit safely.',
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReportingPage(reportToEdit: report)),
    );
    if (mounted) setState(() {});
  }

  Future<void> _deleteReport(ReportRequest report) async {
    final backendId = report.backendId;
    if (backendId == null) {
      _message(
        'This saved report has no verified server ID and cannot be deleted safely.',
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete report?'),
        content: Text(
          'Are you sure you want to permanently delete report #$backendId?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _deleting) return;
    setState(() => _deleting = true);
    try {
      await AuthStore.withAccessToken(
        (api, token) =>
            api.deleteReport(reportId: backendId, accessToken: token),
      );
      await ReportStore.removeReport(report);
      if (mounted) {
        setState(() {});
        _message('Report deleted successfully.');
      }
    } on AuthApiException catch (error) {
      if (error.isSessionExpired && mounted) {
        _goToStart();
      } else {
        _message(error.message);
      }
    } catch (_) {
      _message('Could not delete the report. Please check your connection.');
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _downloadReportPdf(ReportRequest report) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            build: (context) => [
            pw.Padding(
            padding: const pw.EdgeInsets.all(30),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Municipal Reporting App',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Report #${report.backendId ?? report.id}',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text('Status: ${report.status}'),
                pw.SizedBox(height: 10),
                pw.Text('Date Submitted: ${report.createdAt.toLocal()}'),
                pw.SizedBox(height: 10),
                pw.Text('Category: ${report.issueType}'),
                pw.SizedBox(height: 10),
                pw.Text('Specific Issue: ${report.issue}'),
                pw.SizedBox(height: 10),
                pw.Text('Location: ${report.locationAddress}'),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Additional Information: '
                      '${report.description.isEmpty ? 'None' : report.description}',
                ),
              ],
            ),
            ),
          ],
        ),
      );

      final pdfBytes = await pdf.save();

      final result = await PublicFileSaver().save(
        bytes: pdfBytes,
        fileName: 'Municipal_Report_${report.backendId ?? report.id}.pdf',
        mimeType: 'application/pdf',
      );

      if (result?.isSuccess == true) {
        _message('Report PDF saved to Downloads successfully.');
      } else {
        _message('Could not save the PDF.');
      }
    } catch (error) {
      _message('Error generating PDF: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthStore.currentUser;
    final reports = ReportStore.reportsForCurrentUser();
    final isSupervisor = user?.isStaff == true;
    final primary = pagePrimaryColor(isSupervisor: isSupervisor);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F4),
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
        decoration: isSupervisor
            ? pageBackgroundDecoration(isSupervisor: isSupervisor)
            : const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFF8F4), Color(0xFFFFE9DC)],
                ),
              ),
        child: SafeArea(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: _orange.withOpacity(0.12),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1E8),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.person, size: 65, color: _orange),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        user?.fullName ?? 'User',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: _darkText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _borderColor),
                      ),
                      child: IconButton(
                        tooltip: 'Edit profile',
                        icon: const Icon(Icons.edit, color: _orange),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditProfilePage(),
                            ),
                          );
                          if (mounted) setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your account information',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: _secondaryText,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                const _SectionHeading(title: 'Personal Information'),
                const SizedBox(height: 14),
                _InfoCard(
                  icon: Icons.person_outline,
                  label: 'Full Name',
                  value: user?.fullName ?? 'Not set',
                ),
                _InfoCard(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: user?.email ?? 'Not set',
                ),
                _InfoCard(
                  icon: Icons.location_on_outlined,
                  label: 'Area',
                  value: user?.ward ?? 'Not set',
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _quickLink(
                      label: 'View Reports',
                      icon: Icons.assignment,
                      page: const OtherReportsPage(),
                    ),
                    _quickLink(
                      label: 'Contact Us',
                      icon: Icons.contact_mail,
                      page: const ContactPage(),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const _SectionHeading(title: 'Your Recent Reports'),
                const SizedBox(height: 14),
                if (reports.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 28,
                    ),
                    decoration: _cardDecoration(),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 42,
                          color: _orange,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'You have not submitted any reports yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: _secondaryText,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...reports.map(_reportCard),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Back to top',
        backgroundColor: primary,
        foregroundColor: Colors.white,
        onPressed: () => scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        ),
        child: const Icon(Icons.arrow_upward),
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: _borderColor, width: 1.2),
    boxShadow: [
      BoxShadow(
        color: _orange.withOpacity(0.08),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
    ],
  );

  Widget _quickLink({
    required String label,
    required IconData icon,
    required Widget page,
  }) {
    return ElevatedButton.icon(
      onPressed: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        elevation: 3,
        shadowColor: _orange.withOpacity(0.25),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _reportCard(ReportRequest report) {
    final canEdit =
        report.backendId != null &&
        report.areaId != null &&
        report.latitude != null &&
        report.longitude != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _cardDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            onExpansionChanged: (expanded) {
              if (expanded) _refreshReportStatus(report);
            },
            iconColor: _orange,
            collapsedIconColor: _orange,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 6,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            title: Text(
              'Report #${report.backendId ?? report.id} - ${report.issueType}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _darkText,
              ),
            ),
            children: [
              _reportTimeline(report),
              _reportDetail('Specific Issue', report.issue),
              _reportDetail('Location', report.locationAddress),
              _reportDetail(
                'Additional Information',
                report.description.isEmpty ? 'None' : report.description,
              ),
              _reportDetail('Sync', report.syncStatus),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _deleting || !canEdit
                          ? null
                          : () => _editReport(report),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _deleting || report.backendId == null
                          ? null
                          : () => _deleteReport(report),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade700),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _deleting ? null : () => _downloadReportPdf(report),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Download PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              if (report.backendId == null)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'This older cached report has no verified backend ID, so editing and deletion are disabled for safety.',
                    style: TextStyle(fontSize: 12, color: _secondaryText),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reportDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: _darkText, height: 1.5),
            children: [
              TextSpan(
                text: '$label: ',
                style: const TextStyle(
                  color: _orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: value,
                style: const TextStyle(color: _darkText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Color(0xFF292524),
      letterSpacing: 0.2,
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE8C7B8), width: 1.2),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFC94F1B).withOpacity(0.08),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1E8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFFC94F1B), size: 26),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFC94F1B),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF292524),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
