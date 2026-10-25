import 'package:flutter/material.dart';

import 'auth_store.dart';
import 'report_store.dart';

class ReportSummaryTile extends StatelessWidget {
  const ReportSummaryTile({required this.group, super.key});

  final ReportGroup group;

  @override
  Widget build(BuildContext context) {
    final report = group.firstReport;
    final reporterNames = group.reporterNames;
    final reportedBy = reporterNames.isEmpty
        ? 'Unknown reporter'
        : 'Reported by ${reporterNames.join(', ')}';

    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(
          backgroundColor: Colors.red,
          child: Icon(Icons.assignment, color: Colors.white),
        ),
        title: Text('Report #${report.id}'),
        subtitle: Text(
          [
            '${report.issueType}: ${report.issue}',
            reportedBy,
            if (group.reporterCount > 1)
              '${group.reporterCount} people reported the same issue',
          ].join('\n'),
        ),
        onTap: () => _showReportDetails(context),
      ),
    );
  }

  void _showReportDetails(BuildContext context) {
    final user = AuthStore.currentUser;
    final username = user?.username.trim().toLowerCase() ?? '';
    final fullName = user?.fullName.trim().toLowerCase() ?? '';
    final ownReport = user == null
        ? null
        : group.reports.cast<ReportRequest?>().firstWhere((report) {
            if (report == null) return false;
            final reporterUsername = report.senderUsername.trim().toLowerCase();
            return reporterUsername.isNotEmpty
                ? reporterUsername == username
                : report.senderName.trim().toLowerCase() == fullName;
          }, orElse: () => null);
    final report = ownReport ?? group.firstReport;
    final canViewFullDetails = ownReport != null;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Report #${report.id}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detail('Type of issue', report.issueType),
              _detail('Issue', report.issue),
              _detail('Reported by', report.senderName),
              if (group.reporterCount > 1)
                _detail(
                  'Same issue reported by',
                  '${group.reporterCount} people',
                ),
              if (canViewFullDetails) ...[
                _detail(
                  'Submitted',
                  report.createdAt.toLocal().toString().split('.').first,
                ),
                _detail('Status', report.status),
                _detail('Ward', report.area),
                _detail(
                  'Location',
                  report.locationAddress.isNotEmpty
                      ? report.locationAddress
                      : 'Not provided',
                ),
                if (report.pinLocation.isNotEmpty)
                  _detail('Pin location', report.pinLocation),
                _detail(
                  'Additional information',
                  report.description.isNotEmpty
                      ? report.description
                      : 'No additional information',
                ),
              ],
            ],
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

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text('$label: $value'),
    );
  }
}
