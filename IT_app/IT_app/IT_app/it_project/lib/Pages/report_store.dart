import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_store.dart';

class ReportRequest {
  ReportRequest({
    required this.id,
    required this.senderName,
    this.senderUsername = '',
    required this.issueType,
    required this.issue,
    required this.area,
    this.imagePath = '',
    DateTime? createdAt,
    DateTime? queuedAt,
    this.submittedAt,
    this.syncStatus = 'Pending sync',
    this.description = '',
    this.status = 'Pending',
    this.assignedSupervisorUsername = '',
    this.scheduledAt,
    this.assignedWorkerUsername = '',
    this.invoiceNumber,
    this.invoiceSubmissionStatus = '',
    this.invoiceSubmittedAt,
    this.workerName = '',
    this.workerId = '',
    this.jobNumber = '',
    this.locationAddress = '',
    this.pinLocation = '',
    this.startTime = '',
    this.stopTime = '',
    this.totalTime = '',
    this.managerSignature = '',
    this.workerSignature = '',
    this.storageType = 'online',
    this.backendId,
    this.backendIssueCategory = '',
    this.backendIssueType = '',
    this.areaId,
    this.latitude,
    this.longitude,
  }) : createdAt = createdAt ?? DateTime.now(),
       queuedAt = queuedAt ?? createdAt ?? DateTime.now();

  final int id;
  final String senderName;
  final String senderUsername;
  String issueType;
  String issue;
  String area;
  String imagePath;
  final DateTime createdAt;
  final DateTime queuedAt;
  DateTime? submittedAt;
  String syncStatus;
  String description;
  String status;
  String assignedSupervisorUsername;
  DateTime? scheduledAt;
  String assignedWorkerUsername;
  String? invoiceNumber;
  String invoiceSubmissionStatus;
  DateTime? invoiceSubmittedAt;
  String workerName;
  String workerId;
  String jobNumber;
  String locationAddress;
  String pinLocation;
  String startTime;
  String stopTime;
  String totalTime;
  String managerSignature;
  String workerSignature;
  String storageType;
  int? backendId;
  String backendIssueCategory;
  String backendIssueType;
  int? areaId;
  double? latitude;
  double? longitude;

  bool get isOffline => storageType == 'offline';
  bool get isSubmitted => submittedAt != null;

  void markSubmitted() {
    submittedAt = DateTime.now();
    syncStatus = 'Synced';
    status = status.isEmpty ? 'Pending' : status;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderName': senderName,
    'senderUsername': senderUsername,
    'issueType': issueType,
    'issue': issue,
    'area': area,
    'imagePath': imagePath,
    'createdAt': createdAt.toIso8601String(),
    'queuedAt': queuedAt.toIso8601String(),
    'submittedAt': submittedAt?.toIso8601String(),
    'syncStatus': syncStatus,
    'storageType': storageType,
    'description': description,
    'status': status,
    'assignedSupervisorUsername': assignedSupervisorUsername,
    'scheduledAt': scheduledAt?.toIso8601String(),
    'assignedWorkerUsername': assignedWorkerUsername,
    'invoiceNumber': invoiceNumber,
    'invoiceSubmissionStatus': invoiceSubmissionStatus,
    'invoiceSubmittedAt': invoiceSubmittedAt?.toIso8601String(),
    'workerName': workerName,
    'workerId': workerId,
    'jobNumber': jobNumber,
    'locationAddress': locationAddress,
    'pinLocation': pinLocation,
    'startTime': startTime,
    'stopTime': stopTime,
    'totalTime': totalTime,
    'managerSignature': managerSignature,
    'workerSignature': workerSignature,
    'backendId': backendId,
    'backendIssueCategory': backendIssueCategory,
    'backendIssueType': backendIssueType,
    'areaId': areaId,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory ReportRequest.fromJson(Map<String, dynamic> json) => ReportRequest(
    id: json['id'] as int,
    senderName: json['senderName'] as String,
    senderUsername: json['senderUsername'] as String? ?? '',
    issueType: json['issueType'] as String,
    issue: json['issue'] as String,
    area: json['area'] as String,
    imagePath: json['imagePath'] as String? ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String),
    queuedAt:
        DateTime.tryParse(json['queuedAt'] as String? ?? '') ?? DateTime.now(),
    submittedAt: json['submittedAt'] == null
        ? null
        : DateTime.tryParse(json['submittedAt'] as String),
    syncStatus: json['syncStatus'] as String? ?? 'Pending sync',
    description: json['description'] as String? ?? '',
    status: json['status'] as String? ?? 'Pending',
    assignedSupervisorUsername:
        json['assignedSupervisorUsername'] as String? ?? '',
    scheduledAt: json['scheduledAt'] == null
        ? null
        : DateTime.tryParse(json['scheduledAt'] as String),
    assignedWorkerUsername: json['assignedWorkerUsername'] as String? ?? '',
    invoiceNumber: json['invoiceNumber'] as String?,
    invoiceSubmissionStatus: json['invoiceSubmissionStatus'] as String? ?? '',
    invoiceSubmittedAt: json['invoiceSubmittedAt'] == null
        ? null
        : DateTime.tryParse(json['invoiceSubmittedAt'] as String),
    workerName: json['workerName'] as String? ?? '',
    workerId: json['workerId'] as String? ?? '',
    jobNumber: json['jobNumber'] as String? ?? '',
    locationAddress: json['locationAddress'] as String? ?? '',
    pinLocation: json['pinLocation'] as String? ?? '',
    startTime: json['startTime'] as String? ?? '',
    stopTime: json['stopTime'] as String? ?? '',
    totalTime: json['totalTime'] as String? ?? '',
    managerSignature: json['managerSignature'] as String? ?? '',
    workerSignature: json['workerSignature'] as String? ?? '',
    storageType: json['storageType'] as String? ?? 'online',
    backendId: json['backendId'] as int?,
    backendIssueCategory:
    json['backendIssueCategory'] as String? ?? '',
    backendIssueType: json['backendIssueType'] as String? ?? '',
    areaId: json['areaId'] as int?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
  );
}

class ReportGroup {
  const ReportGroup({
    required this.firstReport,
    required this.reports,
    required this.reporterCount,
  });

  final ReportRequest firstReport;
  final List<ReportRequest> reports;
  final int reporterCount;

  List<String> get reporterNames {
    final namesByReporter = <String, String>{};
    for (final report in reports) {
      final username = report.senderUsername.trim().toLowerCase();
      final name = report.senderName.trim();
      final identity = username.isNotEmpty
          ? 'user:$username'
          : name.isNotEmpty
          ? 'name:${name.toLowerCase()}'
          : 'report:${report.id}';
      if (name.isNotEmpty) namesByReporter.putIfAbsent(identity, () => name);
    }
    return List.unmodifiable(namesByReporter.values);
  }

  factory ReportGroup.fromReports(List<ReportRequest> reports) {
    final orderedReports = List<ReportRequest>.of(reports)
      ..sort((first, second) {
        final dateOrder = first.createdAt.compareTo(second.createdAt);
        return dateOrder != 0 ? dateOrder : first.id.compareTo(second.id);
      });
    final reporters = <String>{};
    for (final report in reports) {
      final username = report.senderUsername.trim().toLowerCase();
      final sender = report.senderName.trim().toLowerCase();
      reporters.add(
        username.isNotEmpty
            ? 'user:$username'
            : sender.isNotEmpty
            ? 'name:$sender'
            : 'report:${report.id}',
      );
    }
    return ReportGroup(
      firstReport: orderedReports.first,
      reports: List.unmodifiable(orderedReports),
      reporterCount: reporters.length,
    );
  }
}

class ReportStore {
  static const reportsEndpointPath = '/reports';
  static const _storageKey = 'offline_reports';
  static final List<ReportRequest> _reports = [];
  static int _nextId = 1;
  static SharedPreferences? _preferences;
  static bool _isOnline = true;

  static bool get isOnline => _isOnline;

  static void setConnectionStatus(bool isOnline) {
    _isOnline = isOnline;
  }

  static Future<void> initialize() async {
    try {
      final connectivity = Connectivity();
      final initialStatus = await connectivity.checkConnectivity();
      _isOnline = initialStatus != ConnectivityResult.none;
      connectivity.onConnectivityChanged.listen((result) {
        _isOnline = result != ConnectivityResult.none;
      });
    } catch (_) {
      _isOnline = true;
    }

    _preferences = await SharedPreferences.getInstance();
    final storedReports = _preferences!.getStringList(_storageKey) ?? [];
    _reports
      ..clear()
      ..addAll(
        storedReports.map(
          (value) =>
              ReportRequest.fromJson(jsonDecode(value) as Map<String, dynamic>),
        ),
      );
    if (_reports.isNotEmpty) {
      _nextId =
          _reports
              .map((report) => report.id)
              .reduce((first, second) => first > second ? first : second) +
          1;
    }
  }

  static List<ReportRequest> get reports => List.unmodifiable(_reports);
  static List<ReportRequest> get offlineReports => List.unmodifiable(
    _reports.where((report) => report.storageType == 'offline').toList(),
  );
  static List<ReportRequest> get onlineReports => List.unmodifiable(
    _reports.where((report) => report.storageType == 'online').toList(),
  );

  static Map<String, dynamic> analyticsSummary() {
    final totalReports = _reports.length;
    final syncedReports = _reports
        .where((report) => report.syncStatus == 'Synced')
        .length;
    final offlineReports = _reports
        .where((report) => report.storageType == 'offline')
        .length;
    final onlineReports = _reports
        .where((report) => report.storageType == 'online')
        .length;
    final pendingReports = _reports
        .where((report) => report.syncStatus != 'Synced')
        .length;

    return {
      'totalReports': totalReports,
      'syncedReports': syncedReports,
      'offlineReports': offlineReports,
      'onlineReports': onlineReports,
      'pendingReports': pendingReports,
    };
  }

  static List<ReportRequest> reportsForArea(String area) {
    final normalizedArea = area.trim().toLowerCase();
    final areaReports =
        _reports
            .where(
              (report) => report.area.trim().toLowerCase() == normalizedArea,
            )
            .toList()
          ..sort((first, second) => second.id.compareTo(first.id));
    return List.unmodifiable(areaReports);
  }

  static List<ReportRequest> reportsForSupervisorOnDate({
    required String supervisorUsername,
    required DateTime date,
  }) {
    final normalizedUsername = supervisorUsername.trim().toLowerCase();
    if (normalizedUsername.isEmpty) {
      return const [];
    }
    final dayReports =
        _reports.where((report) {
          final scheduledAt = report.scheduledAt?.toLocal();
          return report.assignedSupervisorUsername.trim().toLowerCase() ==
                  normalizedUsername &&
              AuthStore.canSuperviseIssue(
                supervisorUsername: normalizedUsername,
                issueType: report.issueType,
              ) &&
              scheduledAt != null &&
              scheduledAt.year == date.year &&
              scheduledAt.month == date.month &&
              scheduledAt.day == date.day;
        }).toList()..sort((first, second) {
          final firstDate = first.scheduledAt!.compareTo(second.scheduledAt!);
          return firstDate != 0 ? firstDate : first.id.compareTo(second.id);
        });
    return List.unmodifiable(dayReports);
  }

  static bool assignSupervisor({
    required Iterable<ReportRequest> reports,
    required String supervisorUsername,
    required DateTime scheduledAt,
  }) {
    if (AuthStore.currentUser?.isAdmin != true) {
      return false;
    }
    final supervisor = AuthStore.findUser(supervisorUsername);
    final assignedReports = reports.toList();
    if (supervisor?.isSupervisor != true ||
        assignedReports.isEmpty ||
        assignedReports.any(
          (report) =>
              !_reports.contains(report) ||
              !AuthStore.canSuperviseIssue(
                supervisorUsername: supervisorUsername,
                issueType: report.issueType,
              ),
        )) {
      return false;
    }
    for (final report in assignedReports) {
      report.assignedSupervisorUsername = supervisor!.username;
      report.scheduledAt = scheduledAt;
      if (report.status == 'Pending') {
        report.status = 'Assigned';
      }
    }
    _save();
    return true;
  }

  static List<ReportGroup> groupReports(Iterable<ReportRequest> reports) {
    final groups = <String, List<ReportRequest>>{};
    for (final report in reports) {
      final key = [
        report.issueType.trim().toLowerCase(),
        report.issue.trim().toLowerCase(),
        report.area.trim().toLowerCase(),
      ].join('\u0000');
      groups.putIfAbsent(key, () => []).add(report);
    }

    final groupedReports = groups.values.map(ReportGroup.fromReports).toList()
      ..sort(
        (first, second) =>
            second.firstReport.id.compareTo(first.firstReport.id),
      );
    return List.unmodifiable(groupedReports);
  }

  static List<ReportRequest> reportsForCurrentUser() {
    final user = AuthStore.currentUser;
    if (user == null) {
      return const [];
    }

    final username = user.username.trim().toLowerCase();
    final senderName = user.fullName.toLowerCase();
    final userReports = _reports.where((report) {
      final reportUsername = report.senderUsername.trim().toLowerCase();
      return reportUsername.isNotEmpty
          ? reportUsername == username
          : report.senderName.trim().toLowerCase() == senderName;
    }).toList()..sort((first, second) => second.id.compareTo(first.id));
    return List.unmodifiable(userReports);
  }

  static List<ReportRequest> reportsForWorker(String username) {
    final normalizedUsername = username.trim().toLowerCase();
    if (normalizedUsername.isEmpty) {
      return const [];
    }

    final workerReports =
        _reports
            .where(
              (report) =>
                  report.assignedWorkerUsername.trim().toLowerCase() ==
                  normalizedUsername,
            )
            .toList()
          ..sort((first, second) => second.id.compareTo(first.id));
    return List.unmodifiable(workerReports);
  }

  static ReportRequest? addReport({
    required String issueType,
    required String issue,
    required String area,
    String description = '',
    String pinLocation = '',
    String locationAddress = '',
    required String imagePath,
    int? backendId,
    String backendIssueCategory = '',
    String backendIssueType = '',
    int? areaId,
    double? latitude,
    double? longitude,
    bool isOfflineSubmission = false,
  }) {
    final user = AuthStore.currentUser;
    if (user == null) {
      return null;
    }

    final report = ReportRequest(
      id: _nextId++,
      senderName: user.fullName,
      senderUsername: user.username,
      issueType: issueType,
      issue: issue,
      area: area.trim(),
      description: description.trim(),
      pinLocation: pinLocation.trim(),
      locationAddress: locationAddress.trim(),
      storageType: isOfflineSubmission ? 'offline' : 'online',  // changed
      syncStatus: isOfflineSubmission ? 'Queued offline' : 'Pending submission', // changed
      queuedAt: DateTime.now(),
      createdAt: DateTime.now(),
      submittedAt: null,
      backendId: backendId,
      backendIssueCategory: backendIssueCategory,
      backendIssueType: backendIssueType,
      areaId: areaId,
      latitude: latitude,
      longitude: longitude,
    );
    _reports.insert(0, report);
    _save();
    return report;
  }

  static List<ReportRequest> get pendingSyncReports => List.unmodifiable(
    _reports
        .where(
          (report) =>
              report.storageType == 'offline' && report.syncStatus != 'Synced',
        )
        .toList(),
  );

  static Future<void> syncPendingReports(
    Future<bool> Function(ReportRequest report) sendReport,
  ) async {
    for (final report in pendingSyncReports.toList()) {
      if (await sendReport(report)) {
        report.storageType = 'online';
        report.markSubmitted();
      }
    }
    await _save();
  }

  static void updateStatus(ReportRequest report, String status) {
    report.status = status;
    _save();
  }

  static bool assignWorker({
    required ReportRequest report,
    required String workerUsername,
  }) {
    final currentUser = AuthStore.currentUser;
    final worker = AuthStore.findUser(workerUsername);
    if ((currentUser?.isSupervisor != true && currentUser?.isAdmin != true) ||
        worker == null ||
        !worker.isWorker ||
        !_reports.contains(report) ||
        (report.status != 'Pending' && report.status != 'Assigned')) {
      return false;
    }

    report.assignedWorkerUsername = worker.username;
    report.status = 'Assigned';
    _save();
    return true;
  }



  static Future<void> updateReport({
    required ReportRequest report,
    required String issueType,
    required String issue,
    required String area,
    required String description,
    required String pinLocation,
    required String locationAddress,
    required String imagePath,
    required String backendIssueCategory,
    required String backendIssueType,
    required int areaId,
    required double latitude,
    required double longitude,
  }) async {
    report.issueType = issueType;
    report.issue = issue;
    report.area = area.trim();
    report.description = description.trim();
    report.pinLocation = pinLocation.trim();
    report.locationAddress = locationAddress.trim();
    report.imagePath = imagePath;
    report.backendIssueCategory = backendIssueCategory;
    report.backendIssueType = backendIssueType;
    report.areaId = areaId;
    report.latitude = latitude;
    report.longitude = longitude;

    await _save();
  }



  static void saveJobCompletion({
    required ReportRequest report,
    Iterable<ReportRequest> relatedReports = const [],
    required String workerName,
    required String workerId,
    required String jobNumber,
    required String locationAddress,
    required String pinLocation,
    required String startTime,
    required String stopTime,
    required String totalTime,
    required String managerSignature,
    required String workerSignature,
  }) {
    report.invoiceNumber ??= 'LOG-${report.id.toString().padLeft(4, '0')}';
    report.workerName = workerName.trim();
    report.workerId = workerId.trim();
    report.jobNumber = jobNumber.trim();
    report.locationAddress = locationAddress.trim();
    report.pinLocation = pinLocation.trim();
    report.startTime = startTime.trim();
    report.stopTime = stopTime.trim();
    report.totalTime = totalTime.trim();
    report.managerSignature = managerSignature.trim();
    report.workerSignature = workerSignature.trim();
    for (final relatedReport in {report, ...relatedReports}) {
      relatedReport.invoiceSubmissionStatus = 'Pending admin submission';
      relatedReport.invoiceSubmittedAt = null;
      relatedReport.status = 'Completed';
    }
    _save();
  }

  static Future<void> removeReport(ReportRequest report) async {
    _reports.remove(report);
    await _save();
  }

  // Mark a report as submitted and save its updated status.
  static Future<void> markReportSubmitted(
      ReportRequest report,
      ) async {
    if (!_reports.contains(report)) return;

    report.storageType = 'online';
    report.markSubmitted();

    await _save();
  }


  static Future<void> _save() async {
    final preferences = _preferences;
    if (preferences == null) return;
    await preferences.setStringList(
      _storageKey,
      _reports.map((report) => jsonEncode(report.toJson())).toList(),
    );
  }
}