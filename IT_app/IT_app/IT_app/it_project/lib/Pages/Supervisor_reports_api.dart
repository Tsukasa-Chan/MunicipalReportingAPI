import 'package:flutter/material.dart';
import 'Supervisor_theme.dart';
import 'auth_api.dart';
import 'auth_store.dart';

class SupervisorReportsApiPage extends StatefulWidget {
  const SupervisorReportsApiPage({super.key});
  @override
  State<SupervisorReportsApiPage> createState() => _SupervisorReportsApiPageState();
}

class _SupervisorReportsApiPageState extends State<SupervisorReportsApiPage> {
  late Future<List<Map<String, dynamic>>> _issues;

  @override
  void initState() {
    super.initState();
    _issues = _load();
  }

  Future<List<Map<String, dynamic>>> _load() => AuthStore.withAccessToken(
    (api, token) => api.getMyAssignedIssues(accessToken: token),
  );

  Future<void> _refresh() async {
    setState(() => _issues = _load());
    await _issues;
  }

  Future<void> _changeStatus(Map<String, dynamic> issue, String status) async {
    try {
      await AuthStore.withAccessToken((api, token) => api.updateIssueStatus(
        accessToken: token,
        issueId: (issue['id'] as num).toInt(),
        status: status,
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report status updated.')),
      );
      await _refresh();
    } on AuthApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Assigned reports'),
      backgroundColor: pagePrimaryColor(isSupervisor: true),
      foregroundColor: Colors.white,
    ),
    body: Container(
      decoration: pageBackgroundDecoration(isSupervisor: true),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _issues,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Could not load assigned reports: ${snapshot.error}', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(onPressed: _refresh, child: const Text('Try again')),
              ]),
            ));
          }
          final issues = snapshot.data ?? const <Map<String, dynamic>>[];
          if (issues.isEmpty) return const Center(child: Text('No reports are assigned to you yet.'));
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: issues.length,
              itemBuilder: (context, index) {
                final issue = issues[index];
                final current = (issue['status'] ?? 'Reported').toString();
                final statuses = const ['Reported', 'InProgress', 'Resolved'];
                final id = issue['id'];
                return Card(
                  color: Colors.white.withValues(alpha: 0.94),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${issue['issueType'] ?? 'Issue'} • ${issue['issueCategory'] ?? ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('${issue['areaName'] ?? ''} • ${issue['wardName'] ?? ''}'),
                      Text('${issue['reportCount'] ?? 0} resident report(s)'),
                      if ((issue['originalDescription'] ?? '').toString().isNotEmpty)
                        Text(issue['originalDescription'].toString()),
                      const SizedBox(height: 8),
                      Text('Current status: ${_label(current)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: statuses.contains(current) ? current : null,
                        decoration: const InputDecoration(labelText: 'Change report status'),
                        items: statuses.map((value) => DropdownMenuItem(value: value, child: Text(_label(value)))).toList(),
                        onChanged: (value) {
                          if (value != null && value != current) _changeStatus(issue, value);
                        },
                      ),
                    ]),
                  ),
                );
              },
            ),
          );
        },
      ),
    ),
  );

  String _label(String value) => switch (value) {
    'Reported' => 'Reported',
    'InProgress' => 'In progress',
    'Resolved' => 'Resolved',
    _ => value,
  };
}
