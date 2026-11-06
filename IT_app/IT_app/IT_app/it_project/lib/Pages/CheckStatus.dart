import 'package:flutter/material.dart';

import 'Help.dart';
import 'StartUp.dart';
import 'auth_api.dart';
import 'auth_store.dart';
import 'report_store.dart';
import 'Supervisor_theme.dart';

class StatusPage extends StatefulWidget {
  const StatusPage({super.key});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  static const _orange = Color(0xFFC94F1B);
  static const _darkText = Color(0xFF292524);
  static const _secondaryText = Color(0xFF78716C);
  static const _borderColor = Color(0xFFE8C7B8);

  List<ReportRequest> _serverReports = [];
  bool _reportsLoading = true;
  String? _reportsError;

  @override
  void initState() {
    super.initState();
    _refreshReports(showMessage: false);
  }

  // Only unsent reports are read from the device. Submitted reports come
  // from the authenticated user's database records instead.
  List<ReportRequest> get _pendingLocalReports =>
      ReportStore.reportsForCurrentUser()
          .where((report) => !report.isSubmitted && report.backendId == null)
          .toList();

  List<Map<String, String>> get reports {
    final combined = <ReportRequest>[
      ..._serverReports,
      ..._pendingLocalReports,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return combined
        .map((report) => {
      'id': (report.backendId ?? report.id).toString().padLeft(3, '0'),
      'issue': report.issue,
      'addInfo': report.description,
      'location': report.locationAddress,
      'createdAt': report.createdAt.toLocal().toString(),
      'submittedAt': report.submittedAt?.toLocal().toString() ??
          'Not submitted yet',
      'date': report.createdAt.toLocal().toString(),
      'status': report.status,
      'syncStatus': report.syncStatus,
      'storageType': report.storageType,
    })
        .toList();
  }

  Future<void> _refreshReports({bool showMessage = true}) async {
    if (_reportsLoading && showMessage) return;
    if (mounted) {
      setState(() {
        _reportsLoading = true;
        _reportsError = null;
      });
    }

    try {
      final response = await AuthStore.withAccessToken(
            (api, token) => api.getMyReports(accessToken: token),
      );
      final loaded = response.map(ReportRequest.fromApiJson).toList();
      if (!mounted) return;
      setState(() {
        _serverReports = loaded;
        _reportsLoading = false;
      });
      if (showMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reports refreshed.')),
        );
      }
    } on AuthApiException catch (error) {
      if (!mounted) return;
      if (error.isSessionExpired) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const StartupPage()),
              (_) => false,
        );
        return;
      }
      setState(() {
        _reportsError = error.message;
        _reportsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _reportsError =
        'Could not load reports from the server. Check your connection and try again.';
        _reportsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSupervisor = AuthStore.currentUser?.isStaff == true;
    final visibleReports = reports;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: pagePrimaryColor(isSupervisor: isSupervisor),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Check Status',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh reports',
            icon: const Icon(Icons.refresh),
            onPressed: _reportsLoading ? null : _refreshReports,
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
        width: double.infinity,
        height: double.infinity,
        decoration: isSupervisor
            ? pageBackgroundDecoration(isSupervisor: true)
            : const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF8F4), Color(0xFFFFE9DC)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (_reportsLoading)
                const LinearProgressIndicator(color: _orange),
              if (_reportsError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _borderColor),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _reportsError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _darkText),
                        ),
                        TextButton.icon(
                          onPressed: _reportsLoading ? null : _refreshReports,
                          icon: const Icon(Icons.refresh, color: _orange),
                          label: const Text('Try again',
                              style: TextStyle(color: _orange)),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: visibleReports.isEmpty
                    ? _reportsLoading
                    ? const Center(
                  child: CircularProgressIndicator(color: _orange),
                )
                    : _reportsError != null
                    ? const SizedBox.shrink()
                    : Center(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 36,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _borderColor.withValues(alpha: 0.6),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _orange.withValues(alpha: 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.assignment_outlined,
                            color: _orange, size: 55),
                        SizedBox(height: 16),
                        Text(
                          'No reports available.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _darkText,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  itemCount: visibleReports.length,
                  itemBuilder: (context, index) =>
                      _reportEntry(context, visibleReports[index]),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: pagePrimaryColor(isSupervisor: isSupervisor),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor.withValues(alpha: 0.65)),
        boxShadow: [
          BoxShadow(
            color: _orange.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: ListTile(
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE9DC),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: _orange,
              size: 26,
            ),
          ),
          title: Text(
            'Report #${report['id']}',
            style: const TextStyle(
              color: _darkText,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Created: ${report['createdAt']}\n'
                  'Submitted: ${report['submittedAt']}\n'
                  '${report['syncStatus'] ?? 'Pending sync'}',
              style: const TextStyle(
                color: _secondaryText,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: _orange,
            size: 26,
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReportDetailsPage(report: report),
            ),
          ),
        ),
      ),
    );
  }
}

class ReportDetailsPage extends StatelessWidget {
  const ReportDetailsPage({super.key, required this.report});

  final Map<String, String> report;

  static const _orange = Color(0xFFC94F1B);
  static const _darkText = Color(0xFF292524);
  static const _secondaryText = Color(0xFF78716C);
  static const _borderColor = Color(0xFFE8C7B8);

  @override
  Widget build(BuildContext context) {
    final isSupervisor = AuthStore.currentUser?.isStaff == true;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: pagePrimaryColor(isSupervisor: isSupervisor),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Report #${report['id']}',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
        width: double.infinity,
        height: double.infinity,
        decoration: isSupervisor
            ? pageBackgroundDecoration(isSupervisor: true)
            : const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF8F4), Color(0xFFFFE9DC)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _borderColor.withValues(alpha: 0.65)),
                boxShadow: [
                  BoxShadow(
                    color: _orange.withValues(alpha: 0.09),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE9DC),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: _orange,
                        size: 38,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Report #${report['id']} details',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _darkText,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _detailField('Creation time', report['createdAt'] ?? 'Not available'),
                  _detailField(
                    'Submitted time',
                    report['submittedAt'] ?? 'Not submitted yet',
                  ),
                  _detailField('Type of issue', report['issue'] ?? 'Not available'),
                  _detailField('Location', report['location'] ?? 'Not available'),
                  _detailField(
                    'Additional information',
                    report['addInfo']?.isEmpty == true
                        ? 'No additional information'
                        : report['addInfo'] ?? 'No additional information',
                  ),
                  _detailField('Status', report['status'] ?? 'Not available'),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _orange,
                      side: const BorderSide(color: _orange, width: 1.5),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Back to reports',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
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
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: value,
        readOnly: true,
        style: const TextStyle(
          color: _darkText,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _secondaryText, fontSize: 14),
          floatingLabelStyle: const TextStyle(
            color: _orange,
            fontWeight: FontWeight.w600,
          ),
          filled: true,
          fillColor: const Color(0xFFFFF8F4),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _orange, width: 1.5),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
