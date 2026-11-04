import 'package:flutter/material.dart';
import 'api_config.dart';
import 'issues_api.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:public_file_saver/public_file_saver.dart';

class AreaFeedController extends ChangeNotifier {

  AreaFeedController({
    // The backend id of the area (must be given).
    required this.areaId,
    // Whether to also load the dashboard statistics (default yes).
    this.loadStats = true,
    // Optional API client; tests pass a fake one here.
    IssuesApi? api,
    // Use the given API, or make a new one if none was given.
  }) : _api = api ?? IssuesApi(),
  // Remember whether we created the API ourselves (so we must close it).
        _ownsApi = api == null;

  // The area whose issues we load.
  final int areaId;
  // Whether statistics are loaded as well.
  final bool loadStats;
  // The client that talks to the server.
  final IssuesApi _api;
  // True when this controller made the API client itself.
  final bool _ownsApi;

  // Latest statistics.
  AreaStats? _stats;
  // Latest list of issues (empty until loaded).
  List<AreaIssue> _issues = const [];
  // True while a request is running.
  bool _isLoading = false;
  // Message of the last error (null when everything is fine).
  String? _error;
  // When the data was last loaded successfully.
  DateTime? _lastUpdated;
  // Counts requests so old slow answers can be ignored.
  int _generation = 0;
  // True once dispose() has been called.
  bool _disposed = false;

  // Read-only access to the statistics.
  AreaStats? get stats => _stats;
  // Read-only access to the issues.
  List<AreaIssue> get issues => _issues;
  // Read-only access to the loading flag.
  bool get isLoading => _isLoading;
  // Read-only access to the error message.
  String? get error => _error;
  // Read-only access to the last-updated time.
  DateTime? get lastUpdated => _lastUpdated;

  // True once at least one load has succeeded.
  bool get hasLoaded => _lastUpdated != null;

  // Loads (or reloads) the data from the server.
  Future<void> refresh() async {
    // Give this request a number; newer requests get bigger numbers.
    final generation = ++_generation;
    // Show the loading spinner.
    _isLoading = true;
    // Clear any old error.
    _error = null;
    // Tell listening widgets to rebuild.
    _notify();

    // Try the network calls; errors are handled below.
    try {
      // Run the requests at the same time and wait for all of them.
      final results = await Future.wait<Object?>([
        // Ask the server for this area's issues.
        _api.fetchIssues(areaId: areaId),
        // Only ask for stats when they are wanted.
        if (loadStats) _api.fetchStats(areaId: areaId),
      ]);

      // Stop if the screen is gone or a newer request has started.
      if (_disposed || generation != _generation) return;
      // The first result is the list of issues.
      _issues = results[0] as List<AreaIssue>;
      // The second result (if requested).
      if (loadStats) _stats = results[1] as AreaStats;
      // Remember when we got fresh data.
      _lastUpdated = DateTime.now();
      // Handle errors we expect from the API (no internet, server error...).
    } on IssuesApiException catch (error) {
      // Ignore the answer if it is out of date.
      if (_disposed || generation != _generation) return;
      // Keep the readable message to show the user.
      _error = error.message;
      // Handle any other unexpected error.
    } catch (_) {
      // Ignore the answer if it is out of date.
      if (_disposed || generation != _generation) return;
      // Show a general message.
      _error = 'Something went wrong while loading this area.';
    }

    // Hide the loading spinner.
    _isLoading = false;
    // Tell widgets to rebuild with the new state.
    _notify();
  }

  // Notifies listeners, but only if we haven't been disposed.
  void _notify() {
    // Avoid errors from notifying after the screen closed.
    if (!_disposed) notifyListeners();
  }

  // Runs when the screen using this controller is closed.
  @override
  void dispose() {
    // Remember we are finished.
    _disposed = true;
    // Close the API client only if we created it.
    if (_ownsApi) _api.close();
    // Let Flutter clean up its own part.
    super.dispose();
  }
}

class _CategoryStyle {
  // Constructor with the two values.
  const _CategoryStyle(this.icon, this.color);
  // The icon to draw.
  final IconData icon;
  // The colour to use.
  final Color color;
}

// Picks the icon and colour for a category key from the server.
_CategoryStyle _categoryStyle(String key) => switch (key) {
// Water category: blue water drop.
  'WaterAndSanitation' => const _CategoryStyle(Icons.water_drop_outlined, Colors.blue),
// Roads category: orange-brown road icon.
  'RoadsAndStormwater' => const _CategoryStyle(Icons.alt_route, Color(0xFFC94F1B)),
// Electricity category: lightning bolt.
  'Electricity' => const _CategoryStyle(Icons.bolt, Colors.blueGrey),
// Waste category: bin icon.
  'WasteManagement' => const _CategoryStyle(Icons.delete_outline, Colors.teal),
// Anything unknown gets a grey warning icon.
  _ => const _CategoryStyle(Icons.report_problem_outlined, Colors.grey),
};

// Picks the colour for an issue status.
Color statusColor(String status) => switch (status) {
// New issues are orange.
  'Reported' => Colors.orange,
// Issues being worked on are blue.
  'InProgress' => Colors.blue,
// Finished issues are green.
  'Resolved' => Colors.green,
// Unknown status is grey.
  _ => Colors.grey,
};

// The white rounded card look shared by the dashboard cards.
BoxDecoration _cardDecoration() => BoxDecoration(
  // White background.
  color: Colors.white,
  // Rounded corners.
  borderRadius: BorderRadius.circular(24),
  // A soft shadow under the card.
  boxShadow: [
    // One light shadow.
    BoxShadow(
      // Shadow colour: black at low opacity.
      color: Colors.black.withValues(alpha: 0.06),
      // How blurry the shadow is.
      blurRadius: 10,
    ),
  ],
);

// Turns a time into text like "Updated 09:05".
String _updatedText(DateTime? time) {
  // No time means no text.
  if (time == null) return '';
  // Hour with two digits.
  final hour = time.hour.toString().padLeft(2, '0');
  // Minute with two digits.
  final minute = time.minute.toString().padLeft(2, '0');
  // Combine into the final text.
  return 'Updated $hour:$minute';
}


class StatusChip extends StatelessWidget {

  // Constructor taking the status to show.
  const StatusChip({super.key, required this.status});

  // The status key, e.g. "InProgress".
  final String status;

  // Builds what appears on screen.
  @override
  Widget build(BuildContext context) {
    // Get the colour for this status.
    final color = statusColor(status);
    // A box that holds the text.
    return Container(
      // Space inside the pill.
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      // Look of the pill.
      decoration: BoxDecoration(
        // Light version of the status colour.
        color: color.withValues(alpha: 0.14),
        // Fully rounded ends.
        borderRadius: BorderRadius.circular(20),
      ),
      // The words inside the pill.
      child: Text(
        // Readable status name, e.g. "In progress".
        IssueStatuses.label(status),
        // Text styling.
        style: TextStyle(
          // Darker shade of the colour so the text is easy to read.
          color: Color.alphaBlend(Colors.black.withValues(alpha: 0.35), color),
          // Small text.
          fontSize: 12,
          // Slightly bold.
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// A small box with an icon, a big number and a label (used on the dashboard).
class _MetricTile extends StatelessWidget {
  // Constructor with all four values required.
  const _MetricTile({
    // The words under the number.
    required this.label,
    // The number to show.
    required this.value,
    // The icon at the top.
    required this.icon,
    // The colour theme of the tile.
    required this.color,
  });

  // Text label.
  final String label;
  // Number value.
  final int value;
  // Icon to display.
  final IconData icon;
  // Tile colour.
  final Color color;

  // Builds what appears on screen.
  @override
  Widget build(BuildContext context) {
    // The outer box of the tile.
    return Container(
      // Space inside the tile.
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 12),
      // Look of the tile.
      decoration: BoxDecoration(
        // Very light background of the tile colour.
        color: color.withValues(alpha: 0.09),
        // Rounded corners.
        borderRadius: BorderRadius.circular(14),
      ),
      // Stack the items vertically.
      child: Column(
        // Align items to the left.
        crossAxisAlignment: CrossAxisAlignment.start,
        // The items.
        children: [
          // The icon.
          Icon(icon, color: color, size: 22),
          // A small gap.
          const SizedBox(height: 7),
          // The big number.
          Text(
            // Convert the number to text.
            '$value',
            // Number styling.
            style: TextStyle(
              // Large text.
              fontSize: 22,
              // Bold text.
              fontWeight: FontWeight.bold,
              // Same colour as the tile theme.
              color: color,
            ),
          ),
          // The small label under the number.
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black87)),
        ],
      ),
    );
  }
}

// An orange warning bar shown when loading fails, with a Retry button.
class _ErrorBanner extends StatelessWidget {
  // Constructor with all three values required.
  const _ErrorBanner({
    // The error text.
    required this.message,
    // Whether old data is still being shown below.
    required this.showingOldData,
    // What to do when Retry is pressed.
    required this.onRetry,
  });

  // The error message to display.
  final String message;
  // True when older data is still on screen.
  final bool showingOldData;
  // Function to call on Retry.
  final VoidCallback onRetry;

  // Builds what appears on screen.
  @override
  Widget build(BuildContext context) {
    // The outer box of the banner.
    return Container(
      // Space below the banner.
      margin: const EdgeInsets.only(bottom: 12),
      // Space inside the banner (less on the right for the button).
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      // Look of the banner.
      decoration: BoxDecoration(
        // Light orange background.
        color: Colors.orange.withValues(alpha: 0.12),
        // Rounded corners.
        borderRadius: BorderRadius.circular(12),
      ),
      // Put the items side by side.
      child: Row(
        // The items in the banner.
        children: [
          // A "no cloud" icon.
          const Icon(Icons.cloud_off_outlined, color: Colors.deepOrange),
          // A small gap.
          const SizedBox(width: 10),
          // Let the text take the remaining width.
          Expanded(
            // The message text.
            child: Text(
              // Add a note when old data is still shown.
              showingOldData
                  ? "$message Showing the last data we loaded."
                  : message,
              // Small text.
              style: const TextStyle(fontSize: 13),
            ),
          ),
          // The Retry button.
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// A thin bar showing how issues split between reported / in progress / resolved.
class _StatusBar extends StatelessWidget {
  // Constructor taking the statistics.
  const _StatusBar({required this.stats});

  // The numbers to draw.
  final AreaStats stats;

  // Builds what appears on screen.
  @override
  Widget build(BuildContext context) {
    // Add up all issues in the three statuses.
    final total = stats.reported + stats.inProgress + stats.resolved;
    // If there are none, show a message instead of a bar.
    if (total == 0) {
      // The "nothing yet" message.
      return const Text(
        // Message text.
        'No issues have been reported in this area yet.',
        // Grey text.
        style: TextStyle(color: Colors.black54),
      );
    }

    // Helper that makes one coloured piece of the bar, sized by its count.
    Widget segment(int count, Color color) =>
        // Wider pieces for bigger counts (flex = share of the width).
    Expanded(flex: count, child: Container(color: color));

    // Stack the bar and its caption vertically.
    return Column(
      // Align to the left.
      crossAxisAlignment: CrossAxisAlignment.start,
      // The items.
      children: [
        // Describe the bar for screen readers.
        Semantics(
          // Spoken description.
          label: '${stats.resolvedPercent} percent of issues resolved',
          // Round the ends of the bar.
          child: ClipRRect(
            // Corner size.
            borderRadius: BorderRadius.circular(6),
            // Fix the bar's height.
            child: SizedBox(
              // Bar thickness.
              height: 10,
              // Pieces side by side.
              child: Row(
                // The coloured pieces (skipped when the count is zero).
                children: [
                  // Orange piece for reported issues.
                  if (stats.reported > 0) segment(stats.reported, Colors.orange),
                  // Blue piece for in-progress issues.
                  if (stats.inProgress > 0) segment(stats.inProgress, Colors.blue),
                  // Green piece for resolved issues.
                  if (stats.resolved > 0) segment(stats.resolved, Colors.green),
                ],
              ),
            ),
          ),
        ),
        // A small gap.
        const SizedBox(height: 6),
        // The caption under the bar.
        Text(
          // Percentage resolved.
          '${stats.resolvedPercent}% of issues resolved',
          // Small grey text.
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }
}


// A tappable card summarising one issue.
class IssueCard extends StatelessWidget {
  // Constructor: the issue is required, tap action is optional.
  const IssueCard({super.key, required this.issue, this.onTap});

  // The issue to show.
  final AreaIssue issue;
  // Optional custom tap action.
  final VoidCallback? onTap;

  // Builds what appears on screen.
  @override
  Widget build(BuildContext context) {
    // Icon and colour for this issue's category.
    final style = _categoryStyle(issue.category);
    // Text saying how many residents reported it (handles 1 vs many).
    final residents = issue.reportCount == 1
        ? '1 resident reported this'
        : '${issue.reportCount} residents reported this';

    // Space above each card.
    return Padding(
      // Gap above the card.
      padding: const EdgeInsets.only(top: 8),
      // Material gives the ripple effect when tapped.
      child: Material(
        // White background.
        color: Colors.white,
        // Rounded corners.
        borderRadius: BorderRadius.circular(14),
        // Makes the card tappable.
        child: InkWell(
          // Ripple follows the rounded corners.
          borderRadius: BorderRadius.circular(14),
          // On tap: use the custom action or open the details sheet.
          onTap: onTap ?? () => showIssueDetails(context, issue),
          // The visible box with a border.
          child: Container(
            // Space inside the card.
            padding: const EdgeInsets.all(12),
            // Border and corners.
            decoration: BoxDecoration(
              // Thin light-grey border.
              border: Border.all(color: Colors.black12),
              // Rounded corners.
              borderRadius: BorderRadius.circular(14),
            ),
            // Icon on the left, text on the right.
            child: Row(
              // Align items to the top.
              crossAxisAlignment: CrossAxisAlignment.start,
              // The items.
              children: [
                // Round icon badge.
                CircleAvatar(
                  // Light background of the category colour.
                  backgroundColor: style.color.withValues(alpha: 0.12),
                  // The category icon.
                  child: Icon(style.icon, color: style.color),
                ),
                // Gap between icon and text.
                const SizedBox(width: 12),
                // The text takes the remaining width.
                Expanded(
                  // Text lines stacked vertically.
                  child: Column(
                    // Align to the left.
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // The lines.
                    children: [
                      // Title and status side by side.
                      Row(
                        // The two items.
                        children: [
                          // Title takes the free space.
                          Expanded(
                            // The issue type name.
                            child: Text(
                              // e.g. "Burst pipe".
                              issue.issueTypeLabel,
                              // Title styling.
                              style: const TextStyle(
                                // Slightly larger text.
                                fontSize: 15.5,
                                // Bold text.
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          // Gap before the status pill.
                          const SizedBox(width: 8),
                          // The status pill.
                          StatusChip(status: issue.status),
                        ],
                      ),
                      // Small gap.
                      const SizedBox(height: 4),
                      // The location text.
                      Text(
                        // Show a fallback when there is no location.
                        issue.location.isEmpty
                            ? 'Location not provided'
                            : issue.location,
                        // Allow at most two lines.
                        maxLines: 2,
                        // Add "..." when it is too long.
                        overflow: TextOverflow.ellipsis,
                        // Dark text.
                        style: const TextStyle(color: Colors.black87),
                      ),
                      // Small gap.
                      const SizedBox(height: 6),
                      // Small info items that wrap onto a new line if needed.
                      Wrap(
                        // Horizontal gap between items.
                        spacing: 14,
                        // Vertical gap between rows.
                        runSpacing: 4,
                        // The info items.
                        children: [
                          // How many residents reported it.
                          _Meta(icon: Icons.groups_outlined, text: residents),
                          // Only show the time if we know it.
                          if (issue.createdAt != null)
                          // How long ago it was reported.
                            _Meta(
                              // Clock icon.
                              icon: Icons.schedule,
                              // e.g. "2 days ago".
                              text: timeAgo(issue.createdAt),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// A tiny icon + text pair (used for the card's extra info).
class _Meta extends StatelessWidget {
  // Constructor with both values required.
  const _Meta({required this.icon, required this.text});

  // The small icon.
  final IconData icon;
  // The text.
  final String text;

  // Builds what appears on screen.
  @override
  Widget build(BuildContext context) {
    // Icon and text side by side.
    return Row(
      // Only as wide as the content.
      mainAxisSize: MainAxisSize.min,
      // The items.
      children: [
        // The icon.
        Icon(icon, size: 15, color: Colors.black54),
        // Tiny gap.
        const SizedBox(width: 4),
        // The text.
        Text(text, style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
      ],
    );
  }
}

// Opens a bottom sheet with all the details of one issue.
void showIssueDetails(BuildContext context, AreaIssue issue) {
  // Turn the stored photo path into a full web address (or null).
  final photoUrl = ApiConfig.resolveUrl(issue.imageUrl);

  // Helper that builds one "small label + value" block.
  Widget row(String label, String value) => Padding(
    // Space under each block.
    padding: const EdgeInsets.only(bottom: 10),
    // Label above value.
    child: Column(
      // Align to the left.
      crossAxisAlignment: CrossAxisAlignment.start,
      // The two lines.
      children: [
        // The small grey label.
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        // Tiny gap.
        const SizedBox(height: 2),
        // The value itself.
        Text(value, style: const TextStyle(fontSize: 15)),
      ],
    ),
  );

  // Show the sheet that slides up from the bottom.
  showModalBottomSheet<void>(
    // Which screen to show it on.
    context: context,
    // Allow the sheet to be taller than half the screen.
    isScrollControlled: true,
    // Show the little drag handle at the top.
    showDragHandle: true,
    // Builds the sheet's content.
    builder: (sheetContext) => SafeArea(
      // Let the content scroll if it is long.
      child: SingleChildScrollView(
        // Space around the content.
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        // Everything stacked vertically.
        child: Column(
          // Align to the left.
          crossAxisAlignment: CrossAxisAlignment.start,
          // The content.
          children: [
            // Title and status side by side.
            Row(
              // The items.
              children: [
                // Title takes the free space.
                Expanded(
                  // The issue type name.
                  child: Text(
                    // e.g. "Burst pipe".
                    issue.issueTypeLabel,
                    // Big bold title.
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                // The status pill.
                StatusChip(status: issue.status),
              ],
            ),
            // Gap below the title.
            const SizedBox(height: 14),
            // Show the category.
            row('Category', issue.categoryLabel),
            // Show the area.
            row(
              // Label text.
              'Area',
              // Join area and ward names, skipping empty ones.
              [issue.areaName, issue.wardName]
                  .where((part) => part.isNotEmpty)
                  .join(', '),
            ),
            // Show the location.
            row(
              // Label text.
              'Location',
              // Fallback if there is no location.
              issue.location.isEmpty ? 'Not provided' : issue.location,
            ),
            // Show how many residents reported it.
            row(
              // Label text.
              'Residents who reported this',
              // The count as text.
              '${issue.reportCount}',
            ),
            // Only show when it was first reported if known.
            if (issue.createdAt != null)
            // The formatted date and time.
              row('First reported', formatDateTime(issue.createdAt)),
            // Only show last update if known.
            if (issue.updatedAt != null)
            // The formatted date and time.
              row('Last updated', formatDateTime(issue.updatedAt)),
            // Only show the supervisor if one is assigned.
            if (issue.supervisorName != null)
            // The supervisor's name.
              row('Assigned to', issue.supervisorName!),
            // Only show the description if there is one.
            if (issue.description != null)
            // The description text.
              row('Description', issue.description!),
            // Only show a photo if the issue has one.
            if (photoUrl != null)
            // Round the photo's corners.
              ClipRRect(
                // Corner size.
                borderRadius: BorderRadius.circular(12),
                // Load the picture from the internet.
                child: Image.network(
                  // The photo's web address.
                  photoUrl,
                  // Photo height.
                  height: 200,
                  // Photo fills the full width.
                  width: double.infinity,
                  // Crop the photo to fill the box.
                  fit: BoxFit.cover,
                  // If the photo fails to load, show nothing.
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class AreaDashboardCard extends StatelessWidget {
  // Constructor with the values the card needs.
  const AreaDashboardCard({
    // Standard Flutter widget key.
    super.key,
    // Where the data comes from.
    required this.controller,
    // The area's name for the subtitle.
    required this.areaName,
    // What to do when the user taps to see issues.
    required this.onOpenIssues,
    // Number of reports only saved on this phone (default 0).
    this.unsentReports = 0,
  });

  // Loads and holds the area's data.
  final AreaFeedController controller;
  // The area's display name.
  final String areaName;

  // Called with a category key, or null for "all categories".
  final void Function(String? category) onOpenIssues;

  // Reports saved on this device that have not reached the server yet.
  final int unsentReports;

  Future<void> _downloadDashboardPdf(
      BuildContext context,
      AreaStats stats,
      ) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Padding(
              padding: const pw.EdgeInsets.all(30),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Municipal Reporting App',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Dashboard Statistics',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text('Area: $areaName'),
                  pw.Text('Date Generated: ${DateTime.now()}'),
                  pw.Divider(),
                  pw.SizedBox(height: 10),

                  pw.Text(
                    'Overall Statistics',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text('Total Issues: ${stats.totalIssues}'),
                  pw.Text('Total Reports: ${stats.totalReports}'),
                  pw.Text('Reported: ${stats.reported}'),
                  pw.Text('In Progress: ${stats.inProgress}'),
                  pw.Text('Resolved: ${stats.resolved}'),

                  pw.SizedBox(height: 20),
                  pw.Text(
                    'Statistics by Category',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),

                  ...IssueCategories.all.map((category) {
                    final categoryStats = stats.forCategory(category);

                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 10),
                      child: pw.Text(
                        '${IssueCategories.label(category)}: '
                            '${categoryStats.total} issues',
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      );

      final pdfBytes = await pdf.save();

      final result = await PublicFileSaver().save(
        bytes: pdfBytes,
        fileName: 'Dashboard_Statistics.pdf',
        mimeType: 'application/pdf',
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result?.isSuccess == true
                ? 'Dashboard PDF saved successfully.'
                : 'Could not save the dashboard PDF.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $error')),
      );
    }
  }

  // Builds what appears on screen.
  @override
  Widget build(BuildContext context) {
    // Rebuild whenever the controller's data changes.
    return ListenableBuilder(
      // The thing to listen to.
      listenable: controller,
      // Builds the card each time the data changes.
      builder: (context, _) {
        // The latest statistics (may be null while loading).
        final stats = controller.stats;

        // The white card.
        return Container(
          // Use the full width.
          width: double.infinity,
          // Space inside the card.
          padding: const EdgeInsets.all(20),
          // White rounded look with shadow.
          decoration: _cardDecoration(),
          // Stack everything vertically.
          child: Column(
            // Align to the left.
            crossAxisAlignment: CrossAxisAlignment.start,
            // The card's content.
            children: [
              // Title and refresh button side by side.
              Row(
                // The items.
                children: [
                  // Title takes the free space.
                  const Expanded(
                    // The title text.
                    child: Text(
                      // Title words.
                      'Area dashboard',
                      // Big bold title.
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  // While loading, show a spinner instead of the button.
                  if (controller.isLoading)
                  // Space around the spinner.
                    const Padding(
                      // Same padding as an icon button.
                      padding: EdgeInsets.all(12),
                      // Fixes the spinner's size.
                      child: SizedBox(
                        // Spinner width.
                        width: 20,
                        // Spinner height.
                        height: 20,
                        // The spinning circle.
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  // Otherwise show the refresh button.
                  else
                  // The refresh button.
                    IconButton(
                      // Text shown on long-press.
                      tooltip: 'Refresh area data',
                      // Reload the data when pressed.
                      onPressed: controller.refresh,
                      // The refresh icon.
                      icon: const Icon(Icons.refresh, color: Colors.red),
                    ),
                ],
              ),
              // The subtitle under the title.
              Text(
                // Area name, plus "Updated hh:mm" once loaded.
                [
                  // The area name.
                  areaName,
                  // Add the update time after the first successful load.
                  if (controller.hasLoaded) _updatedText(controller.lastUpdated),
                ].join(' • '),
                // Small grey text.
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
              // Gap below the subtitle.
              const SizedBox(height: 14),
              // Show the error banner when something went wrong.
              if (controller.error != null)
              // The banner.
                _ErrorBanner(
                  // The error text.
                  message: controller.error!,
                  // Tell it whether old numbers are still displayed.
                  showingOldData: stats != null,
                  // Retry reloads the data.
                  onRetry: controller.refresh,
                ),
              // First load with nothing to show yet: show a big spinner.
              if (stats == null && controller.isLoading)
              // Space around the spinner.
                const Padding(
                  // Vertical space.
                  padding: EdgeInsets.symmetric(vertical: 24),
                  // Centre the spinner.
                  child: Center(child: CircularProgressIndicator()),
                ),
              // Once we have stats, show the dashboard content.
              if (stats != null) ..._content(context, stats),
              // Note about reports that only exist on this phone.
              if (unsentReports > 0)
              // Space above the note.
                Padding(
                  // Gap above.
                  padding: const EdgeInsets.only(top: 14),
                  // The note text.
                  child: Text(
                    // Singular or plural wording.
                    unsentReports == 1
                        ? '1 report you made is still saved only on this device, so it is not in these numbers yet.'
                        : '$unsentReports reports you made are still saved only on this device, so they are not in these numbers yet.',
                    // Small grey text.
                    style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Builds the dashboard widgets that need the statistics.
  List<Widget> _content(BuildContext context, AreaStats stats) {
    // Return the list of widgets.
    return [
      // First row of three number tiles.
      Row(
        // The tiles.
        children: [
          // Each tile shares the width equally.
          Expanded(
            // Total issues tile.
            child: _MetricTile(
              // Tile label.
              label: 'Total issues',
              // Number from the server.
              value: stats.totalIssues,
              // Tile icon.
              icon: Icons.assignment,
              // Tile colour.
              color: Colors.red,
            ),
          ),
          // Gap between tiles.
          const SizedBox(width: 8),
          // Equal width.
          Expanded(
            // Reported issues tile.
            child: _MetricTile(
              // Tile label.
              label: 'Reported',
              // Number from the server.
              value: stats.reported,
              // Tile icon.
              icon: Icons.hourglass_empty,
              // Tile colour.
              color: Colors.orange,
            ),
          ),
          // Gap between tiles.
          const SizedBox(width: 8),
          // Equal width.
          Expanded(
            // In-progress issues tile.
            child: _MetricTile(
              // Tile label.
              label: 'In progress',
              // Number from the server.
              value: stats.inProgress,
              // Tile icon.
              icon: Icons.construction,
              // Tile colour.
              color: Colors.blue,
            ),
          ),
        ],
      ),
      // Gap between the two rows.
      const SizedBox(height: 8),
      // Second row of two number tiles.
      Row(
        // The tiles.
        children: [
          // Equal width.
          Expanded(
            // Resolved issues tile.
            child: _MetricTile(
              // Tile label.
              label: 'Resolved',
              // Number from the server.
              value: stats.resolved,
              // Tile icon.
              icon: Icons.check_circle_outline,
              // Tile colour.
              color: Colors.green,
            ),
          ),
          // Gap between tiles.
          const SizedBox(width: 8),
          // Equal width.
          Expanded(
            // Resident reports tile.
            child: _MetricTile(
              // Tile label.
              label: 'Resident reports',
              // Number from the server.
              value: stats.totalReports,
              // Tile icon.
              icon: Icons.groups_outlined,
              // Tile colour.
              color: Colors.blueGrey,
            ),
          ),
        ],
      ),
      // Gap before the status bar.
      const SizedBox(height: 16),
      // The coloured status bar.
      _StatusBar(stats: stats),
      // Gap before the category section.
      const SizedBox(height: 18),
      // Heading for the category list.
      const Text(
        // Heading words.
        'Issues by category',
        // Bold heading.
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      // Small gap.
      const SizedBox(height: 4),
      // One row per category, in the usual order.
      ...IssueCategories.all.map(
        // Build the row using that category's numbers.
            (key) => _categoryRow(context, key, stats.forCategory(key)),
      ),
      // Gap before the button.
      const SizedBox(height: 8),
      // Button that opens the full list.
      TextButton.icon(
        // null means "all categories".
        onPressed: () => onOpenIssues(null),
        // Map icon.
        icon: const Icon(Icons.map_outlined),
        // Button text.
        label: const Text('Browse all issues in my area'),
      ),
      const SizedBox(height: 12),

      OutlinedButton.icon(
        onPressed: () => _downloadDashboardPdf(context, stats),
        icon: const Icon(Icons.download),
        label: const Text('Download Dashboard PDF'),
      ),
    ];
  }

  // Builds one tappable row for a category.
  Widget _categoryRow(BuildContext context, String key, CategoryStats stats) {
    // Icon and colour for this category.
    final style = _categoryStyle(key);
    // Space above each row.
    return Padding(
      // Gap above.
      padding: const EdgeInsets.only(top: 8),
      // Material gives the ripple effect.
      child: Material(
        // Light background of the category colour.
        color: style.color.withValues(alpha: 0.08),
        // Rounded corners.
        borderRadius: BorderRadius.circular(14),
        // Makes the row tappable.
        child: InkWell(
          // Ripple follows the rounded corners.
          borderRadius: BorderRadius.circular(14),
          // Open the list filtered to this category.
          onTap: () => onOpenIssues(key),
          // Space inside the row.
          child: Padding(
            // Padding values.
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            // Items side by side.
            child: Row(
              // The items.
              children: [
                // The category icon.
                Icon(style.icon, color: style.color),
                // Gap after the icon.
                const SizedBox(width: 12),
                // Text takes the free space.
                Expanded(
                  // Two lines of text.
                  child: Column(
                    // Align to the left.
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // The lines.
                    children: [
                      // Category name.
                      Text(
                        // e.g. "Water and sanitation".
                        IssueCategories.label(key),
                        // Semi-bold text.
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      // Small summary line.
                      Text(
                        // e.g. "2 active • 1 resolved".
                        '${stats.active} active • ${stats.resolved} resolved',
                        // Small grey text.
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                // The total number of issues in this category.
                Text(
                  // Number as text.
                  '${stats.total}',
                  // Styling.
                  style: TextStyle(
                    // Category colour.
                    color: style.color,
                    // Bold.
                    fontWeight: FontWeight.bold,
                    // Slightly large.
                    fontSize: 17,
                  ),
                ),
                // Small gap.
                const SizedBox(width: 6),
                // Arrow showing the row is tappable.
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home: "Issues in my area" card (latest three)
// ---------------------------------------------------------------------------

// Card showing the three newest issues plus a "view all" button.
class AreaLatestIssuesCard extends StatelessWidget {
  // Constructor with the values the card needs.
  const AreaLatestIssuesCard({
    // Standard Flutter widget key.
    super.key,
    // Where the data comes from.
    required this.controller,
    // The area's display name.
    required this.areaName,
    // What to do when "view all" is pressed.
    required this.onViewAll,
  });

  // Loads and holds the area's data.
  final AreaFeedController controller;
  // The area's display name.
  final String areaName;
  // Called when the user wants the full list.
  final VoidCallback onViewAll;

  // Builds what appears on screen.
  @override
  Widget build(BuildContext context) {
    // Rebuild whenever the controller's data changes.
    return ListenableBuilder(
      // The thing to listen to.
      listenable: controller,
      // Builds the card each time the data changes.
      builder: (context, _) {
        // The latest list of issues.
        final issues = controller.issues;

        // The white card.
        return Container(
          // Use the full width.
          width: double.infinity,
          // Space inside the card.
          padding: const EdgeInsets.all(20),
          // White rounded look with shadow.
          decoration: _cardDecoration(),
          // Stack everything vertically.
          child: Column(
            // Align to the left.
            crossAxisAlignment: CrossAxisAlignment.start,
            // The card's content.
            children: [
              // The card title.
              const Text(
                // Title words.
                'Issues in my area',
                // Big bold title.
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              // The area name under the title.
              Text(
                // Area name.
                areaName,
                // Grey text.
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              // Gap below the subtitle.
              const SizedBox(height: 12),
              // Make the button full width.
              SizedBox(
                // Full width.
                width: double.infinity,
                // The "view all" button with an icon.
                child: ElevatedButton.icon(
                  // Orange button styling to match the app theme.
                  style: ElevatedButton.styleFrom(
                    // App brand orange background.
                    backgroundColor: const Color(0xFFC94F1B),
                    // White text and icon.
                    foregroundColor: Colors.white,
                    // Make the button a bit taller.
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    // Rounded corners to match the app design.
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    // Remove the default elevation.
                    elevation: 0,
                  ),
                  // Open the full list when pressed.
                  onPressed: onViewAll,
                  // Location icon.
                  icon: const Icon(Icons.location_on_outlined),
                  // Button text.
                  label: Text(
                    // Show the count once the data has loaded.
                    controller.hasLoaded
                        ? 'View all ${issues.length} issues in my area'
                        : 'View all issues in my area',
                  ),
                ),
              ),
              // Gap below the button.
              const SizedBox(height: 12),
              // Sub-heading for the list.
              const Text(
                // Heading words.
                'Latest issues',
                // Bold heading.
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              // First load still running: say so.
              if (!controller.hasLoaded && controller.isLoading)
              // Space around the message.
                const Padding(
                  // Vertical space.
                  padding: EdgeInsets.symmetric(vertical: 12),
                  // The message.
                  child: Text('Loading issues...'),
                )
              // Never loaded and not loading: it must have failed.
              else if (!controller.hasLoaded)
              // Space around the message.
                const Padding(
                  // Vertical space.
                  padding: EdgeInsets.symmetric(vertical: 12),
                  // The message.
                  child: Text('Issues could not be loaded yet.'),
                )
              // Loaded but the area has no issues.
              else if (issues.isEmpty)
                // Space around the message.
                  const Padding(
                    // Vertical space.
                    padding: EdgeInsets.symmetric(vertical: 12),
                    // The message.
                    child: Text('No issues have been reported in this area yet.'),
                  )
                // Otherwise show the three newest issues.
                else
                // Take the first three and make a card for each.
                  ...issues.take(3).map((issue) => IssueCard(issue: issue)),
            ],
          ),
        );
      },
    );
  }
}

// The filter chips plus the scrolling list of issues.
class AreaIssuesBody extends StatefulWidget {
  // Constructor with the values the list needs.
  const AreaIssuesBody({
    // Standard Flutter widget key.
    super.key,
    // Where the data comes from.
    required this.controller,
    // The area's display name (used in messages).
    required this.areaName,
    // Optional category to start filtered on.
    this.initialCategory,
  });

  // Loads and holds the area's data.
  final AreaFeedController controller;
  // The area's display name.
  final String areaName;

  // A category key such as "Electricity", or null for all categories.
  final String? initialCategory;

  // Creates the object that holds this widget's changing state.
  @override
  State<AreaIssuesBody> createState() => _AreaIssuesBodyState();
}

// Holds the currently selected filters.
class _AreaIssuesBodyState extends State<AreaIssuesBody> {
  // The chosen category (null = all).
  String? _category;
  // The chosen status (null = any).
  String? _status;

  // Runs once when the widget is first created.
  @override
  void initState() {
    // Let Flutter do its own setup first.
    super.initState();
    // Start with the category passed in (if any).
    _category = widget.initialCategory;
  }

  // Builds what appears on screen.
  @override
  Widget build(BuildContext context) {
    // Shortcut to the controller.
    final controller = widget.controller;

    // Rebuild whenever the controller's data changes.
    return ListenableBuilder(
      // The thing to listen to.
      listenable: controller,
      // Builds the list each time the data changes.
      builder: (context, _) {
        // Every issue we have loaded.
        final all = controller.issues;
        // Only the issues that match the chosen filters.
        final shown = all
        // Keep issues in the chosen category (or all if none chosen).
            .where((issue) => _category == null || issue.category == _category)
        // Keep issues with the chosen status (or all if none chosen).
            .where((issue) => _status == null || issue.status == _status)
        // Turn the result into a list.
            .toList();

        // Stack filters, summary and list vertically.
        return Column(
          // Align to the left.
          crossAxisAlignment: CrossAxisAlignment.start,
          // The parts of the screen.
          children: [
            // Row of category filter chips.
            _chipRow<String?>(
              // Which chip is currently selected.
              selected: _category,
              // The chips to show: "All" plus the four categories.
              options: [
                // The "All categories" chip (value null).
                (null, 'All categories'),
                // One chip for each category.
                for (final key in IssueCategories.all)
                // Pair of key and readable name.
                  (key, IssueCategories.label(key)),
              ],
              // When a chip is tapped, remember it and redraw.
              onSelected: (value) => setState(() => _category = value),
            ),
            // Row of status filter chips.
            _chipRow<String?>(
              // Which chip is currently selected.
              selected: _status,
              // The chips to show: "Any status" plus the three statuses.
              options: [
                // The "Any status" chip (value null).
                (null, 'Any status'),
                // One chip for each status.
                for (final key in IssueStatuses.all)
                // Pair of key and readable name.
                  (key, IssueStatuses.label(key)),
              ],
              // When a chip is tapped, remember it and redraw.
              onSelected: (value) => setState(() => _status = value),
            ),
            // Only show the summary once data has loaded.
            if (controller.hasLoaded)
            // Space around the summary.
              Padding(
                // Padding values.
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                // The summary text.
                child: Text(
                  // e.g. "Showing 3 of 12 issues".
                  'Showing ${shown.length} of ${all.length} issues',
                  // Small grey text.
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ),
            // The list fills the rest of the screen.
            Expanded(child: _results(controller, shown, all.isEmpty)),
          ],
        );
      },
    );
  }

  // Builds a sideways-scrolling row of choice chips.
  Widget _chipRow<T>({
    // The currently selected value.
    required T selected,
    // List of (value, label) pairs to show as chips.
    required List<(T, String)> options,
    // Called with the value of the tapped chip.
    required void Function(T value) onSelected,
  }) {
    // Give the row a fixed height.
    return SizedBox(
      // Row height.
      height: 48,
      // A list that scrolls sideways.
      child: ListView(
        // Scroll left and right.
        scrollDirection: Axis.horizontal,
        // Space around the chips.
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        // The chips.
        children: [
          // Go through every (value, label) pair.
          for (final (value, label) in options)
          // Small gap on each side of a chip.
            Padding(
              // Gap values.
              padding: const EdgeInsets.symmetric(horizontal: 4),
              // The chip itself.
              child: ChoiceChip(
                // The chip's text.
                label: Text(label),
                // Highlight it if it is the selected one.
                selected: selected == value,
                // Tell the caller which chip was tapped.
                onSelected: (_) => onSelected(value),
              ),
            ),
        ],
      ),
    );
  }

  // Builds the main area: spinner, error, empty message or the list.
  Widget _results(
      // Where the data comes from.
      AreaFeedController controller,
      // The issues that passed the filters.
      List<AreaIssue> shown,
      // True when the area has no issues at all.
      bool noIssuesAtAll,
      ) {
    // Nothing has loaded successfully yet.
    if (!controller.hasLoaded) {
      // Still loading: show a spinner.
      if (controller.isLoading) {
        // Centre the spinner.
        return const Center(child: CircularProgressIndicator());
      }
      // Not loading and nothing loaded: show the error screen.
      return Center(
        // Space around the content.
        child: Padding(
          // Padding value.
          padding: const EdgeInsets.all(24),
          // Stack the items vertically.
          child: Column(
            // Only as tall as the content.
            mainAxisSize: MainAxisSize.min,
            // The items.
            children: [
              // A "no cloud" icon.
              const Icon(Icons.cloud_off_outlined, size: 40, color: Colors.black45),
              // Gap below the icon.
              const SizedBox(height: 12),
              // The error message.
              Text(
                // Use the real error, or a general message.
                controller.error ?? 'Issues could not be loaded.',
                // Centre the text.
                textAlign: TextAlign.center,
              ),
              // Gap below the message.
              const SizedBox(height: 12),
              // The button to try loading again.
              ElevatedButton(
                // Reload when pressed.
                onPressed: controller.refresh,
                // Button text.
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    // Text to show when the list is empty (depends on why it is empty).
    final emptyText = noIssuesAtAll
        ? 'No issues have been reported in ${widget.areaName} yet.'
        : 'No issues match these filters.';

    // Pull down to refresh the list.
    return RefreshIndicator(
      // Reload when the user pulls down.
      onRefresh: controller.refresh,
      // The scrolling list.
      child: ListView(
        // Allow pulling even when the list is short.
        physics: const AlwaysScrollableScrollPhysics(),
        // Space around the list.
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        // The list items.
        children: [
          // Show a banner if the last refresh failed.
          if (controller.error != null)
          // Space above the banner.
            Padding(
              // Gap above.
              padding: const EdgeInsets.only(top: 8),
              // The banner.
              child: _ErrorBanner(
                // The error text.
                message: controller.error!,
                // Old data is still displayed below.
                showingOldData: true,
                // Retry reloads the data.
                onRetry: controller.refresh,
              ),
            ),
          // If nothing matches, show the empty message.
          if (shown.isEmpty)
          // Space above the message.
            Padding(
              // Gap above.
              padding: const EdgeInsets.only(top: 48),
              // The message.
              child: Text(
                // The wording chosen above.
                emptyText,
                // Centre the text.
                textAlign: TextAlign.center,
                // Slightly larger text.
                style: const TextStyle(fontSize: 16),
              ),
            )
          // Otherwise list every matching issue.
          else
          // Make a card for each issue.
            ...shown.map((issue) => IssueCard(issue: issue)),
        ],
      ),
    );
  }
}