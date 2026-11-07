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
// Our new dashboard/list widgets and the controller that loads data.
import 'area_widgets.dart';
import 'chat_page.dart';
// The client that talks to the server, plus the issue models.
import 'issues_api.dart';
// App colour scheme.
const Color appOrange = Color(0xFFC94F1B);
const Color appBackground = Color(0xFFFFF8F4);
const Color appGradientEnd = Color(0xFFFFE9DC);
const Color appDark = Color(0xFF292524);
const Color appMuted = Color(0xFF78716C);
const Color appBorder = Color(0xFFE8C7B8);
class HomePage extends StatefulWidget {
  // HomePage can optionally be given a fake server (issuesApi); normally it is null.
  const HomePage({super.key, this.issuesApi});
  // Lets tests supply a fake server. Normally null.
  // Holds the optional server client; tests pass a fake one here.
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
  late final String selectedArea;
  // Loads this user's area issues and stats; stays null if the user has no area.
  AreaFeedController? _feed;
  @override
  void initState() {
    super.initState();
    // Get the signed-in user (may be null).
    final user = AuthStore.currentUser;
    // Remember the area name to show on screen, or 'Not set'.
    selectedArea = user?.ward ?? 'Not set';
    // Issues and statistics come from the backend for the user's area.
    // Get the user's area id (the server needs the id, not the name).
    final areaId = user?.areaId;
    // Only load data if the user actually has an area.
    if (areaId != null) {
      // Create the loader for this area (using the fake server if one was given)...
      _feed = AreaFeedController(areaId: areaId, api: widget.issuesApi)
      // ...and start loading the issues and stats straight away.
        ..refresh();
    }
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
          // Opens the AI assistant (help, area questions, guided reporting).
          IconButton(
            tooltip: 'Assistant',
            icon: const Icon(Icons.smart_toy_outlined, color: Colors.white),
            onPressed: () {
              // Go to the chat screen.
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.help, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpPage()),
              );
            },
          ),
        ],
      ),
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
                    backgroundImage: AssetImage('lib/img/app logo.png'),
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
              leading: const Icon(Icons.settings, color: appOrange),
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
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: appOrange),
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
                  MaterialPageRoute(builder: (_) => const ContactPage()),
                );
              },
            ),
            ListTile(
              // Menu icon: a location pin.
              leading: const Icon(
                Icons.location_on_outlined,
                color: appOrange,
              ),
              // Menu label (renamed from 'My Ward' to 'My Area').
              title: const Text(
                'My Area',
                style: TextStyle(
                  color: appDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Show the user's area name under the label.
              subtitle: Text(
                selectedArea,
                style: const TextStyle(color: appMuted),
              ),
              // When tapped, open the area's issue list.
              onTap: _openMyWard,
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: appOrange),
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
                  MaterialPageRoute(builder: (_) => const StartupPage()),
                      (_) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [appBackground, appGradientEnd],
          ),
        ),
        // Wrap the page so the user can pull down to refresh.
        child: RefreshIndicator(
          color: appOrange,
          backgroundColor: Colors.white,
          // What happens when the user pulls down.
          onRefresh: () async {
            // Reload the issues and stats (does nothing if there is no area).
            await _feed?.refresh();
          },
          // The scrollable page content.
          child: SingleChildScrollView(
            // Allow pull-to-refresh even when the content is short.
            physics: const AlwaysScrollableScrollPhysics(),
            // Keep using the existing scroll controller.
            controller: _scrollController,
            // Space around the content.
            padding: const EdgeInsets.all(20),
            // Stack the cards vertically.
            child: Column(
              children: [
                // Show the dashboard and latest-issues cards (or the 'no area' message).
                ..._buildAreaSections(),
                // Empty space at the bottom.
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
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
              MaterialPageRoute(builder: (_) => const CommunityNoticesPage()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportingPage()),
              // After returning from the New Report page...
            ).then((_) {
              // ...only continue if this screen is still open.
              if (mounted) {
                // Redraw the screen.
                setState(() {});
                // Reload the area numbers so a new report would show up.
                _feed?.refresh();
              }
            });
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Community Notices',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'New Report'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
  void _openMyWard() {
    Navigator.pop(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          // Open the area page...
          builder: (_) => AreaDetailPage(
            // ...for this area's name,
            areaName: selectedArea,
            // ...this area's id,
            areaId: _feed?.areaId,
            // ...and the optional fake server.
            issuesApi: widget.issuesApi,
          ),
        ),
      );
    });
  }
  // Builds the cards for the Home page from the server data.
  List<Widget> _buildAreaSections() {
    // Get the loader (null if the user has no area).
    final feed = _feed;
    // No area: show the 'no area' message card instead of data.
    if (feed == null) return [_buildNoAreaCard()];
    // Count this user's reports that are still only saved on the phone.
    // Reports this user made that are still only stored on the device.
    // Start from all of this user's reports,
    final unsent = ReportStore.reportsForCurrentUser()
    // keep only the ones...
        .where(
      // ...that are each report...
          (report) =>
      // ...stored offline and not yet synced to the server.
      report.storageType == 'offline' && report.syncStatus != 'Synced',
    )
    // Count how many are left.
        .length;
    // Return the two cards for the Home page.
    return [
      // The dashboard card with the stats.
      AreaDashboardCard(
        // Give it the loader so it can show the data.
        controller: feed,
        // Show the area name.
        areaName: selectedArea,
        // Tell it how many reports are not on the server yet.
        unsentReports: unsent,
        // When a category is tapped, open the issue list.
        onOpenIssues: _openAreaIssues,
      ),
      // Space between the two cards.
      const SizedBox(height: 20),
      // The card with the latest issues.
      AreaLatestIssuesCard(
        // Give it the same loader (so the data is only fetched once).
        controller: feed,
        // Show the area name.
        areaName: selectedArea,
        // When 'View all' is pressed, open the list with no category filter.
        onViewAll: () => _openAreaIssues(null),
      ),
    ];
  }
  // The message card for users who have no area.
  Widget _buildNoAreaCard() {
    // A simple white box shown when the user has no area.
    return Container(
      // Make it as wide as the screen.
      width: double.infinity,
      // Space inside the box.
      padding: const EdgeInsets.all(20),
      // Give it a white background...
      decoration: BoxDecoration(
        // ...white colour,
        color: Colors.white,
        // ...and rounded corners.
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: appBorder),
        boxShadow: [
          BoxShadow(
            color: appOrange.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      // The message text.
      child: const Text(
        // Tell the user why there is no dashboard.
        'No area is set on your account yet, so there is no area dashboard to show.',
        // Text size.
        style: TextStyle(
          fontSize: 16,
          color: appDark,
          height: 1.5,
        ),
      ),
    );
  }
  // Opens the full issue list, optionally already filtered to one category.
  void _openAreaIssues(String? category) {
    // Go to the area issues page.
    Navigator.push(
      // Use the current screen's context.
      context,
      // Create the page route.
      MaterialPageRoute(
        // Build the area issues page...
        builder: (_) => AreaReportsPage(
          // ...for this area name,
          areaName: selectedArea,
          // ...this area id,
          areaId: _feed?.areaId,
          // ...starting on a category if one was tapped, otherwise 'All',
          initialFilter: category ?? 'All',
          // ...and the optional fake server.
          issuesApi: widget.issuesApi,
        ),
      ),
      // When the user comes back from that page...
    ).then((_) {
      // ...refresh the numbers if this screen is still open.
      if (mounted) _feed?.refresh();
    });
  }
  @override
  void dispose() {
    // Stop and free the loader when the screen closes.
    _feed?.dispose();
    _scrollController.dispose();
    locationController.dispose();
    addInfoController.dispose();
    super.dispose();
  }
}
// Opened from the drawer's 'My Area'; it just shows the same list as AreaReportsPage.
// Opened from the drawer's "My Area". Shows the same issue list as
// AreaReportsPage.
// A page with no changing state, since it only passes values on.
class AreaDetailPage extends StatelessWidget {
  // Constructor with named values.
  const AreaDetailPage({
    // Standard Flutter key.
    super.key,
    // The area name is required.
    required this.areaName,
    // The area id is optional.
    this.areaId,
    // The fake server is optional (for tests).
    this.issuesApi,
  });
  // The name of the area to show.
  final String areaName;
  // The area's id on the server (may be null).
  final int? areaId;
  // Optional fake server for tests.
  final IssuesApi? issuesApi;
  // Flutter calls build to draw the page.
  @override
  // This method draws the page.
  Widget build(BuildContext context) {
    // Show the area issues page...
    return AreaReportsPage(
      // ...with the same area name,
      areaName: areaName,
      // ...area id,
      areaId: areaId,
      // ...and fake server.
      issuesApi: issuesApi,
    );
  }
}
// Page that lists every issue in one area, loaded from the server, with filters.
// Every issue in one area, loaded from the backend, filterable by category
// and status.
// A page that has some changing state (the loader).
class AreaReportsPage extends StatefulWidget {
  // Constructor with named values.
  const AreaReportsPage({
    // Standard Flutter key.
    super.key,
    // The area name is required (shown in the title).
    required this.areaName,
    // The area id is optional.
    this.areaId,
    // Which category to show first; 'All' means no filter.
    this.initialFilter = 'All',
    // The fake server is optional (for tests).
    this.issuesApi,
  });
  // Name of the area, used in the title and messages.
  final String areaName;
  // Defaults to the signed-in user's area.
  // If null, the signed-in user's own area is used.
  final int? areaId;
  // 'All' or a category key such as 'Electricity'.
  // 'All' or a category key such as 'Electricity'.
  final String initialFilter;
  // Optional fake server for tests.
  final IssuesApi? issuesApi;
  // Create the state object that holds the loader.
  @override
  State<AreaReportsPage> createState() => _AreaReportsPageState();
}
class _AreaReportsPageState extends State<AreaReportsPage> {
  // Loads the issues for this page; null if there is no area.
  AreaFeedController? _feed;
  // Runs once when the page opens.
  @override
  // Do Flutter's own setup first.
  void initState() {
    super.initState();
    // Use the given area id, or fall back to the signed-in user's area id.
    final areaId = widget.areaId ?? AuthStore.currentUser?.areaId;
    // Only load if we have an area id.
    if (areaId != null) {
      // Create the loader...
      _feed = AreaFeedController(
        // ...for this area,
        areaId: areaId,
        // ...without the stats (this page only needs the issue list),
        loadStats: false,
        // ...using the fake server if one was given...
        api: widget.issuesApi,
        // ...and start loading right away.
      )..refresh();
    }
  }
  // Runs when the page closes.
  @override
  // Stop and free the loader.
  void dispose() {
    // Do Flutter's own cleanup.
    _feed?.dispose();
    super.dispose();
  }
  // Flutter calls build to draw the page.
  @override
  Widget build(BuildContext context) {
    // Copy the loader into a local variable so we can check it safely.
    final feed = _feed;
    // The page layout.
    return Scaffold(
      // The top bar.
      appBar: AppBar(
        // Title shows the area name.
        title: Text(
          'Issues in ${widget.areaName}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Orange bar to match the app.
        backgroundColor: appOrange,
        // White title text.
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // The page body.
      body: Container(
        // Light background.
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
        // If there is no loader (no area)...
        child: feed == null
        // ...show a centred message...
            ? const Center(
          // ...with some padding around it,
          child: Padding(
            // ...the padding amount,
            padding: EdgeInsets.all(24),
            // ...and the message itself.
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
        // Otherwise show the filterable list of issues.
            : AreaIssuesBody(
          // Give it the loader so it can show the data.
          controller: feed,
          // Pass the area name for its messages.
          areaName: widget.areaName,
          // Start on the chosen category, or no filter when it is 'All'.
          initialCategory:
          // (the value is chosen here)
          widget.initialFilter == 'All' ? null : widget.initialFilter,
        ),
      ),
    );
  }
}