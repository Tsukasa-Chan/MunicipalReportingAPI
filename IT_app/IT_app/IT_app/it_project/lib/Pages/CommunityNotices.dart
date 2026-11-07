import 'package:flutter/material.dart';

import 'auth_api.dart';
import 'auth_store.dart';
import 'Supervisor_theme.dart';

// Information returned by GET /api/CommunityNotices.
class CommunityNotice {
  const CommunityNotice({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.audience,
    required this.createdAt,
    this.areaName,
    this.wardName,
    this.createdByName,
    this.expiresAt,
  });

  final int id;
  final String title;
  final String description;
  final String category;
  final String audience;
  final DateTime createdAt;
  final String? areaName;
  final String? wardName;
  final String? createdByName;
  final DateTime? expiresAt;

  static String _enumLabel(Object? value, List<String> values) {
    if (value is num) {
      final index = value.toInt();
      if (index >= 0 && index < values.length) return values[index];
    }
    final text = value?.toString() ?? '';
    return values.firstWhere(
          (item) => item.toLowerCase() == text.toLowerCase(),
      orElse: () => text.isEmpty ? values.first : text,
    );
  }

  static DateTime? _date(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  factory CommunityNotice.fromJson(Map<String, dynamic> data) {
    final rawId = data['id'];
    final id = rawId is num ? rawId.toInt() : int.tryParse('$rawId');
    final date = _date(data['createdAt']);
    if (id == null || date == null) {
      throw const FormatException('Notice has an invalid ID or date.');
    }
    return CommunityNotice(
      id: id,
      title: (data['title'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      category: _enumLabel(
        data['category'],
        const ['General', 'Maintenance', 'Emergency'],
      ),
      audience: _enumLabel(
        data['audience'],
        const ['All', 'Ward', 'Area'],
      ),
      createdAt: date,
      areaName: data['areaName']?.toString(),
      wardName: data['wardName']?.toString(),
      createdByName: data['createdByName']?.toString(),
      expiresAt: _date(data['expiresAt']),
    );
  }

  String get targetLabel {
    switch (audience.toLowerCase()) {
      case 'area':
        return areaName?.isNotEmpty == true ? areaName! : 'Your area';
      case 'ward':
        return wardName?.isNotEmpty == true ? wardName! : 'Your ward';
      default:
        return 'All communities';
    }
  }
}

class CommunityNoticesPage extends StatefulWidget {
  const CommunityNoticesPage({super.key});

  @override
  State<CommunityNoticesPage> createState() => _CommunityNoticesPageState();
}

class _CommunityNoticesPageState extends State<CommunityNoticesPage> {
  static const Color _orange = Color(0xFFC94F1B);
  static const Color _darkText = Color(0xFF292524);
  static const Color _muted = Color(0xFF78716C);
  static const Color _border = Color(0xFFE8C7B8);

  List<CommunityNotice> _notices = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await AuthStore.withAccessToken(
            (api, token) => api.getCommunityNotices(accessToken: token),
      );
      final notices = result.map(CommunityNotice.fromJson).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!mounted) return;
      setState(() {
        _notices = notices;
        _loading = false;
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load community notices. Check your connection and try again.';
        _loading = false;
      });
    }
  }

  String _formatDate(BuildContext context, DateTime date) {
    final local = date.toLocal();
    final material = MaterialLocalizations.of(context);
    return '${material.formatMediumDate(local)} · '
        '${material.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'emergency': return Icons.warning_amber_rounded;
      case 'maintenance': return Icons.build_outlined;
      default: return Icons.campaign_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSupervisor = AuthStore.currentUser?.isStaff == true;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Notices'),
        backgroundColor: pagePrimaryColor(isSupervisor: isSupervisor),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh notices',
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh),
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
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    Icon(Icons.campaign_outlined, color: _orange, size: 29),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Updates for your community',
                            style: TextStyle(
                              color: _darkText,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Notices published by municipal administrators',
                            style: TextStyle(color: _muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _orange));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_outlined, color: _orange, size: 46),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center,
                  style: const TextStyle(color: _darkText)),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    if (_notices.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 100),
            Icon(Icons.notifications_none_outlined, color: _orange, size: 52),
            SizedBox(height: 12),
            Center(
              child: Text('No community notices at the moment.',
                  style: TextStyle(color: _darkText, fontSize: 16)),
            ),
            SizedBox(height: 6),
            Center(
              child: Text('Pull down to check for new announcements.',
                  style: TextStyle(color: _muted)),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        itemCount: _notices.length,
        itemBuilder: (context, index) => _noticeCard(_notices[index]),
      ),
    );
  }

  Widget _noticeCard(CommunityNotice notice) {
    return Card(
      elevation: 0,
      color: Colors.white.withValues(alpha: 0.94),
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: _border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CommunityNoticeDetailsPage(notice: notice),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE9DC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_categoryIcon(notice.category), color: _orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notice.title,
                        style: const TextStyle(fontWeight: FontWeight.bold,
                            fontSize: 16, color: _darkText)),
                    const SizedBox(height: 6),
                    Text(notice.description,
                        maxLines: 3, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _muted, height: 1.4)),
                    const SizedBox(height: 10),
                    Text('${notice.category} · ${notice.targetLabel}',
                        style: const TextStyle(color: _orange,
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(_formatDate(context, notice.createdAt),
                        style: const TextStyle(color: _muted, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _orange),
            ],
          ),
        ),
      ),
    );
  }
}

class CommunityNoticeDetailsPage extends StatelessWidget {
  const CommunityNoticeDetailsPage({super.key, required this.notice});

  final CommunityNotice notice;
  static const _orange = Color(0xFFC94F1B);
  static const _darkText = Color(0xFF292524);
  static const _muted = Color(0xFF78716C);

  @override
  Widget build(BuildContext context) {
    final isSupervisor = AuthStore.currentUser?.isStaff == true;
    final material = MaterialLocalizations.of(context);
    final date = notice.createdAt.toLocal();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notice Details'),
        backgroundColor: pagePrimaryColor(isSupervisor: isSupervisor),
        foregroundColor: Colors.white,
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
            padding: const EdgeInsets.all(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE8C7B8)),
                boxShadow: [BoxShadow(
                  color: _orange.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.campaign_outlined, color: _orange, size: 42),
                  const SizedBox(height: 14),
                  Text(notice.title,
                      style: const TextStyle(color: _darkText,
                          fontWeight: FontWeight.bold, fontSize: 24)),
                  const SizedBox(height: 12),
                  Text('${notice.category} · ${notice.targetLabel}',
                      style: const TextStyle(color: _orange,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                    'Published ${material.formatMediumDate(date)} at '
                        '${material.formatTimeOfDay(TimeOfDay.fromDateTime(date))}',
                    style: const TextStyle(color: _muted, fontSize: 13),
                  ),
                  if (notice.createdByName?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 5),
                    Text('Published by ${notice.createdByName}',
                        style: const TextStyle(color: _muted, fontSize: 13)),
                  ],
                  const Divider(height: 36),
                  Text(notice.description,
                      style: const TextStyle(color: _darkText,
                          fontSize: 16, height: 1.5)),
                  if (notice.expiresAt != null) ...[
                    const SizedBox(height: 18),
                    Text(
                      'Visible until ${material.formatMediumDate(notice.expiresAt!.toLocal())}',
                      style: const TextStyle(color: _muted, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _orange,
                      side: const BorderSide(color: _orange),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Back to notices'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
