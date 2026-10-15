class ApiPaths {
  static const registerAccount = '/api/auth/register';
  static const verifyEmail = '/api/auth/email-verification/verify';
  static const resendEmailVerification = '/api/auth/email-verification/resend';

  static const assignReportToSupervisorTemplate =
      '/api/reports/{reportId}/assignment';
  static const supervisorReportsTemplate =
      '/api/supervisors/{supervisorUsername}/reports';
  static const supervisorScheduleTemplate =
      '/api/supervisors/{supervisorUsername}/schedule';
  static const reportStatusTemplate = '/api/reports/{reportId}/status';
  static const reportInvoiceTemplate = '/api/reports/{reportId}/invoice';

  static String assignReportToSupervisor(int reportId) {
    if (reportId <= 0) {
      throw ArgumentError.value(reportId, 'reportId', 'Must be positive.');
    }
    return '/api/reports/$reportId/assignment';
  }

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

  static String reportStatus(int reportId) {
    if (reportId <= 0) {
      throw ArgumentError.value(reportId, 'reportId', 'Must be positive.');
    }
    return '/api/reports/$reportId/status';
  }

  static String reportInvoice(int reportId) {
    if (reportId <= 0) {
      throw ArgumentError.value(reportId, 'reportId', 'Must be positive.');
    }
    return '/api/reports/$reportId/invoice';
  }
}
