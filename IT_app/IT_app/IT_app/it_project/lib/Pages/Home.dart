
import 'dart:io';

import 'package:flutter/material.dart';

import 'ContactUs.dart';
import 'Help.dart';
import 'CommunityNotices.dart';
import 'Profile.dart';
import 'Reporting.dart';
import 'Settings.dart';
import 'StartUp.dart';
import 'auth_store.dart';
import 'report_store.dart';
import 'area_widgets.dart';
import 'chat_page.dart';
import 'issues_api.dart';

const Color appOrange = Color(0xFFC94F1B);
const Color appBackground = Color(0xFFFFF8F4);
const Color appGradientEnd = Color(0xFFFFE9DC);
const Color appDark = Color(0xFF292524);
const Color appMuted = Color(0xFF78716C);
const Color appBorder = Color(0xFFE8C7B8);

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.issuesApi});

  final IssuesApi? issuesApi;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final locationController = TextEditingController();
  final addInfoController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  File? imageIssue;

  final issue = [
    'Potholes',
    'Faulty traffic lights',
    'Broken street lights',
    'Burst water pipes',
    'Road closure',
    'Other',
  ];

  final formKey = GlobalKey<FormState>();

  String? choice;
  String location = '';
  String? additionalInfo;

  // Can now change when the user edits their profile.
  String selectedArea = 'Not set';

  // Holds the issue and statistics data for the current area.
  AreaFeedController? _feed;

  @override
  void initState() {
    super.initState();

    final user = AuthStore.currentUser;

    selectedArea = user?.ward ?? 'Not set';

    final areaId = user?.areaId;

    if (areaId != null) {
      _feed = AreaFeedController(
        areaId: areaId,
        api: widget.issuesApi,
      )..refresh();
    }
  }

  // ============================================================
  // REFRESH AREA AFTER PROFILE CHANGES
  // ============================================================

  Future<void> _refreshCurrentArea({
    bool reloadProfile = false,
  }) async {
    // Reload the latest account information from the backend.
    if (reloadProfile) {
      try {
        await AuthStore.reloadProfile();
      } catch (_) {
        // If the backend is temporarily unavailable,
        // keep using the existing cached user information.
      }
    }

    if (!mounted) return;

    final user = AuthStore.currentUser;

    final newAreaName = user?.ward ?? 'Not set';
    final newAreaId = user?.areaId;

    final oldFeed = _feed;

    // Check whether the user's area ID has changed.
    if (oldFeed?.areaId != newAreaId) {
      // Create a new controller for the new area.
      final newFeed = newAreaId == null
          ? null
          : AreaFeedController(
        areaId: newAreaId,
        api: widget.issuesApi,
      );

      // Update the dashboard with the new area.
      setState(() {
        selectedArea = newAreaName;
        _feed = newFeed;
      });

      // Dispose of the old area's controller.
      oldFeed?.dispose();

      // Fetch the new area's statistics and issues.
      await newFeed?.refresh();

      return;
    }

    // Update the displayed area name if it has changed.
    if (selectedArea != newAreaName) {
      setState(() {
        selectedArea = newAreaName;
      });
    }

    // The area ID is unchanged, so refresh its current data.
    await oldFeed?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,

      appBar: AppBar(
        title: const Text(
          'FIX MY AREA',
          style: TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: appOrange,
        actions: [
          IconButton(
            tooltip: 'Assistant',
            icon: const Icon(
              Icons.smart_toy_outlined,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChatPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.help,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HelpPage(),
                ),
              );
            },
          ),
        ],
      ),

      // ========================================================
      // DRAWER
      // ========================================================

      drawer: Drawer(
        backgroundColor: appBackground,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    appOrange,
                    Color(0xFFE87542),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    backgroundImage: AssetImage(
                      'lib/img/FixMyAreaLogo.jpeg',
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '${AuthStore.currentUser?.name ?? ''} '
                        '${AuthStore.currentUser?.surname ?? ''}'.trim(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    AuthStore.currentUser?.email ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            ListTile(
              leading: const Icon(
                Icons.settings,
                color: appOrange,
              ),
              title: const Text(
                'Settings',
                style: TextStyle(
                  color: appDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsPage(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(
                Icons.phone,
                color: appOrange,
              ),
              title: const Text(
                'Contact Us',
                style: TextStyle(
                  color: appDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ContactPage(),
                  ),
                );
              },
            ),

            // My Area now displays the updated area.
            ListTile(
              leading: const Icon(
                Icons.location_on_outlined,
                color: appOrange,
              ),
              title: const Text(
                'My Area',
                style: TextStyle(
                  color: appDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                selectedArea,
                style: const TextStyle(
                  color: appMuted,
                ),
              ),
              onTap: _openMyWard,
            ),

            ListTile(
              leading: const Icon(
                Icons.logout,
                color: appOrange,
              ),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: appDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                AuthStore.logout();

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StartupPage(),
                  ),
                      (_) => false,
                );
              },
            ),
          ],
        ),
      ),

      // ========================================================
      // HOME DASHBOARD BODY
      // ========================================================

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              appBackground,
              appGradientEnd,
            ],
          ),
        ),

        child: RefreshIndicator(
          color: appOrange,
          backgroundColor: Colors.white,

          // Pull-to-refresh checks the latest saved area first.
          onRefresh: () => _refreshCurrentArea(
            reloadProfile: true,
          ),

          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                ..._buildAreaSections(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),

      // ========================================================
      // BOTTOM NAVIGATION
      // ========================================================

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        backgroundColor: Colors.white,
        elevation: 12,
        selectedItemColor: appOrange,
        unselectedItemColor: appMuted,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CommunityNoticesPage(),
              ),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ReportingPage(),
              ),
            ).then((_) {
              // Refresh the area's issues after reporting.
              if (mounted) {
                _refreshCurrentArea();
              }
            });
          } else {
            // Open Profile.
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProfilePage(),
              ),
            ).then((_) {
              // When Profile closes, reload the user's saved area.
              if (mounted) {
                _refreshCurrentArea(
                  reloadProfile: true,
                );
              }
            });
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Community Notices',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'New Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OPEN MY AREA
  // ============================================================

  void _openMyWard() {
    Navigator.pop(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AreaDetailPage(
            areaName: selectedArea,
            areaId: _feed?.areaId,
            issuesApi: widget.issuesApi,
          ),
        ),
      );
    });
  }

  // ============================================================
  // DASHBOARD SECTIONS
  // ============================================================

  List<Widget> _buildAreaSections() {
    final feed = _feed;

    if (feed == null) {
      return [_buildNoAreaCard()];
    }

    final unsent = ReportStore.reportsForCurrentUser()
        .where(
          (report) =>
      report.storageType == 'offline' &&
          report.syncStatus != 'Synced',
    )
        .length;

    return [
      AreaDashboardCard(
        controller: feed,
        areaName: selectedArea,
        unsentReports: unsent,
        onOpenIssues: _openAreaIssues,
      ),

      const SizedBox(height: 20),

      AreaLatestIssuesCard(
        controller: feed,
        areaName: selectedArea,
        onViewAll: () => _openAreaIssues(null),
      ),
    ];
  }

  // ============================================================
  // NO AREA MESSAGE
  // ============================================================

  Widget _buildNoAreaCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: appBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: appOrange.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Text(
        'No area is set on your account yet, '
            'so there is no area dashboard to show.',
        style: TextStyle(
          fontSize: 16,
          color: appDark,
          height: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // OPEN AREA ISSUES
  // ============================================================

  void _openAreaIssues(String? category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AreaReportsPage(
          areaName: selectedArea,
          areaId: _feed?.areaId,
          initialFilter: category ?? 'All',
          issuesApi: widget.issuesApi,
        ),
      ),
    ).then((_) {
      if (mounted) {
        _feed?.refresh();
      }
    });
  }

  @override
  void dispose() {
    _feed?.dispose();
    _scrollController.dispose();
    locationController.dispose();
    addInfoController.dispose();
    super.dispose();
  }
}

// ============================================================
// AREA DETAIL PAGE
// ============================================================

class AreaDetailPage extends StatelessWidget {
  const AreaDetailPage({
    super.key,
    required this.areaName,
    this.areaId,
    this.issuesApi,
  });

  final String areaName;
  final int? areaId;
  final IssuesApi? issuesApi;

  @override
  Widget build(BuildContext context) {
    return AreaReportsPage(
      areaName: areaName,
      areaId: areaId,
      issuesApi: issuesApi,
    );
  }
}

// ============================================================
// AREA REPORTS PAGE
// ============================================================

class AreaReportsPage extends StatefulWidget {
  const AreaReportsPage({
    super.key,
    required this.areaName,
    this.areaId,
    this.initialFilter = 'All',
    this.issuesApi,
  });

  final String areaName;
  final int? areaId;
  final String initialFilter;
  final IssuesApi? issuesApi;

  @override
  State<AreaReportsPage> createState() =>
      _AreaReportsPageState();
}

class _AreaReportsPageState
    extends State<AreaReportsPage> {
  AreaFeedController? _feed;

  @override
  void initState() {
    super.initState();

    final areaId =
        widget.areaId ?? AuthStore.currentUser?.areaId;

    if (areaId != null) {
      _feed = AreaFeedController(
        areaId: areaId,
        loadStats: false,
        api: widget.issuesApi,
      )..refresh();
    }
  }

  @override
  void dispose() {
    _feed?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feed = _feed;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Issues in ${widget.areaName}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: appOrange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              appBackground,
              appGradientEnd,
            ],
          ),
        ),
        child: feed == null
            ? const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No area is set on your account yet.',
              style: TextStyle(
                color: appDark,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        )
            : AreaIssuesBody(
          controller: feed,
          areaName: widget.areaName,
          initialCategory:
          widget.initialFilter == 'All'
              ? null
              : widget.initialFilter,
        ),
      ),
    );
  }
}
