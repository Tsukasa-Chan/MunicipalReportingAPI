class ApiPaths {
  // account and email verification endpoints.
  static const registerAccount = '/api/auth/register';
  static const verifyEmail = '/api/auth/email-verification/verify';
  static const resendEmailVerification = '/api/auth/email-verification/resend';

  // endpoints for viewing issues and dashboard stats.
  static const issues = '/api/Issues';
  static const issueStats = '/api/Issues/stats';

  // endpoints for the chatbot and reports.
  static const chat = '/api/Chat';
  static const reports = '/api/Reports';

  // endpoints for supervisor tasks and report details.
  static const assignReportToSupervisorTemplate =
      '/api/reports/{reportId}/assignment';
  static const supervisorReportsTemplate =
      '/api/supervisors/{supervisorUsername}/reports';
  static const supervisorScheduleTemplate =
      '/api/supervisors/{supervisorUsername}/schedule';
  static const reportStatusTemplate = '/api/reports/{reportId}/status';
  static const reportInvoiceTemplate = '/api/reports/{reportId}/invoice';

  // creates the assignment endpoint.
  static String assignReportToSupervisor(int reportId) {
    if (reportId <= 0) {
      throw ArgumentError.value(reportId, 'reportId', 'Must be positive.');
    }
    return '/api/reports/$reportId/assignment';
  }

  // gets a supervisors reports.
  static String reportsForSupervisor(String supervisorUsername) {
    final username = supervisorUsername.trim();
    if (username.isEmpty) {
      throw ArgumentError.value(
        supervisorUsername,
        'supervisorUsername',
        'Must not be empty.',
      );
    }
    return '/api/supervisors/${Uri.encodeComponent(username)}/reports';
  }

  // gets a supervisors schedule for a date.
  static String supervisorSchedule({
    required String supervisorUsername,
    required DateTime date,
  }) {
    final username = supervisorUsername.trim();
    if (username.isEmpty) {
      throw ArgumentError.value(
        supervisorUsername,
        'supervisorUsername',
        'Must not be empty.',
      );
    }
    final day =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    return '/api/supervisors/${Uri.encodeComponent(username)}'
        '/schedule?date=$day';
  }

  // updates a reports status.
  static String reportStatus(int reportId) {
    if (reportId <= 0) {
      throw ArgumentError.value(reportId, 'reportId', 'Must be positive.');
    }
    return '/api/reports/$reportId/status';
  }

  // gets a reports invoice.
  static String reportInvoice(int reportId) {
    if (reportId <= 0) {
      throw ArgumentError.value(reportId, 'reportId', 'Must be positive.');
    }
    return '/api/reports/$reportId/invoice';
  }
}