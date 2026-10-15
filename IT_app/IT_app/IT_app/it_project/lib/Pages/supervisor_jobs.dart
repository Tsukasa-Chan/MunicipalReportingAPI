import 'package:flutter/material.dart';

import 'auth_store.dart';
import 'report_store.dart';
import 'Supervisor_theme.dart';

class SupervisorJobsPage extends StatefulWidget {
  const SupervisorJobsPage({super.key});

  @override
  State<SupervisorJobsPage> createState() => _SupervisorJobsPageState();
}

class _SupervisorJobsPageState extends State<SupervisorJobsPage> {
  @override
  Widget build(BuildContext context) {
    final user = AuthStore.currentUser;
    final canManageJobs = user?.isSupervisor == true || user?.isAdmin == true;
    final reports = ReportStore.reports;
    final workers = AuthStore.workers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Allocate jobs'),
        backgroundColor: pagePrimaryColor(isSupervisor: canManageJobs),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Add field worker',
            onPressed: canManageJobs ? _addWorker : null,
            icon: const Icon(Icons.person_add_alt_1),
          ),
        ],
      ),
      body: Container(
        decoration: pageBackgroundDecoration(isSupervisor: canManageJobs),
        child: SafeArea(
          child: !canManageJobs
              ? const Center(child: Text('Supervisor access is required.'))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                      'Job assignments',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC94F1B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Assign incoming reports to field workers. Workers can '
                      'then update the job status as work progresses.',
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: _addWorker,
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Add field worker'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (workers.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Add a field worker before assigning a job.',
                          ),
                        ),
                      ),
                    if (reports.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text('There are no submitted jobs to assign.'),
                      )
                    else
                      ...reports.map(
                        (report) => _SupervisorJobCard(
                          report: report,
                          workers: workers,
                          onChanged: () => setState(() {}),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _addWorker() async {
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => const _AddWorkerDialog(),
    );
    if (!mounted || added == null) {
      return;
    }
    if (added) {
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Field worker added.')));
    }
  }
}

class _SupervisorJobCard extends StatefulWidget {
  const _SupervisorJobCard({
    required this.report,
    required this.workers,
    required this.onChanged,
  });

  final ReportRequest report;
  final List<UserAccount> workers;
  final VoidCallback onChanged;

  @override
  State<_SupervisorJobCard> createState() => _SupervisorJobCardState();
}

class _SupervisorJobCardState extends State<_SupervisorJobCard> {
  late String? _selectedWorkerUsername;

  @override
  void initState() {
    super.initState();
    _selectedWorkerUsername = widget.report.assignedWorkerUsername.isEmpty
        ? null
        : widget.report.assignedWorkerUsername;
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final isAssignable =
        report.status == 'Pending' || report.status == 'Assigned';
    final assignedWorker = AuthStore.findUser(report.assignedWorkerUsername);

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
            Text('Status: ${report.status}'),
            if (assignedWorker != null)
              Text(
                'Assigned to: ${assignedWorker.name} ${assignedWorker.surname}',
              ),
            if (isAssignable) ...[
              const SizedBox(height: 12),
              if (widget.workers.isEmpty)
                const Text('Add a field worker to assign this job.')
              else ...[
                DropdownButtonFormField<String>(
                  initialValue:
                      widget.workers.any(
                        (worker) => worker.username == _selectedWorkerUsername,
                      )
                      ? _selectedWorkerUsername
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Assign to field worker',
                  ),
                  items: widget.workers
                      .map(
                        (worker) => DropdownMenuItem(
                          value: worker.username,
                          child: Text(
                            '${worker.name} ${worker.surname} '
                            '(@${worker.username})',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (username) {
                    setState(() => _selectedWorkerUsername = username);
                  },
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _selectedWorkerUsername == null
                      ? null
                      : _assignSelectedWorker,
                  icon: const Icon(Icons.assignment_ind_outlined),
                  label: Text(
                    report.assignedWorkerUsername.isEmpty
                        ? 'Assign job'
                        : 'Update assignment',
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _assignSelectedWorker() {
    final workerUsername = _selectedWorkerUsername;
    if (workerUsername == null) {
      return;
    }

    if (!ReportStore.assignWorker(
      report: widget.report,
      workerUsername: workerUsername,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This job could not be assigned.')),
      );
      return;
    }
    widget.onChanged();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Job assigned.')));
  }
}

class _AddWorkerDialog extends StatefulWidget {
  const _AddWorkerDialog();

  @override
  State<_AddWorkerDialog> createState() => _AddWorkerDialogState();
}

class _AddWorkerDialogState extends State<_AddWorkerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add field worker'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_nameController, 'Name'),
              _field(_surnameController, 'Surname'),
              _field(_usernameController, 'Username'),
              _field(_emailController, 'Email'),
              _field(_passwordController, 'Temporary password'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _saveWorker, child: const Text('Add worker')),
      ],
    );
  }

  Widget _field(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        validator: (value) => (value ?? '').trim().isEmpty
            ? 'Enter ${label.toLowerCase()}'
            : null,
      ),
    );
  }

  void _saveWorker() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final added = AuthStore.addWorker(
      name: _nameController.text,
      surname: _surnameController.text,
      username: _usernameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!added) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username or email is already in use.')),
      );
      return;
    }
    Navigator.pop(context, true);
  }
}
