import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:permission_handler/permission_handler.dart';

import 'CheckStatus.dart';
import 'Help.dart';
import 'auth_store.dart';
import 'Supervisor_theme.dart';
import 'report_store.dart';
import 'auth_api.dart';

class ReportingPage extends StatefulWidget {
  const ReportingPage({super.key, this.reportToEdit});

  // Null means create a new report; non-null means edit an existing report.
  final ReportRequest? reportToEdit;

  @override
  State<ReportingPage> createState() => _ReportingPageState();
}

class _ReportingPageState extends State<ReportingPage> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final locationController = TextEditingController();
  final pinLocationController = TextEditingController();
  final additionalInfoController = TextEditingController();

  bool _locationPermissionGranted = false;
  bool _isSaving = false;

  final issueTypes = [
    'Roads and Stormwater',
    'Electricity',
    'Water and Sanitation',
    'Waste Management',
  ];
  final roadIssues = [
    'Pothole', 'Sinkhole', 'Blocked Storm Drain', 'Flooded Road',
    'Traffic Light Not Working', 'Missing or Damaged Road Sign',
    'Faded Road Markings',
  ];
  final electricityIssues = [
    'Street Light Not Working', 'Street Light On During Day', 'Power Outage',
    'Exposed Or Damaged Cable', 'Damaged Electrical Box',
  ];
  final waterIssues = [
    'Burst Pipe', 'Leaking Pipe', 'No Water Supply', 'Low Water Pressure',
    'Blocked Sewer or Manhole', 'Sewage Spill', 'Discolored or Dirty Water',
  ];
  final wasteIssues = [
    'Missed Bin Collection', 'Illegal Dumping', 'Overflowing Public Bin',
  ];

  String? selectedIssueType;
  String? selectedIssue;
  int? selectedWard;
  String? selectedCommunityArea;
  XFile? selectedImage;

  List<String> get availableIssues {
    switch (selectedIssueType) {
      case 'Roads and Stormwater': return roadIssues;
      case 'Electricity': return electricityIssues;
      case 'Water and Sanitation': return waterIssues;
      case 'Waste Management': return wasteIssues;
      default: return const [];
    }
  }

  @override
  void initState() {
    super.initState();
    final report = widget.reportToEdit;
    if (report != null) {
      selectedIssueType = issueTypes.contains(report.issueType) ? report.issueType : null;
      selectedIssue = report.issue;
      locationController.text = report.locationAddress;
      pinLocationController.text = report.pinLocation;
      if (pinLocationController.text.trim().isEmpty &&
          report.latitude != null && report.longitude != null) {
        pinLocationController.text = '${report.latitude}, ${report.longitude}';
      }
      additionalInfoController.text = report.description;
      for (final entry in AuthStore.wardAreas.entries) {
        for (final area in entry.value) {
          if (report.area == 'Ward ${entry.key} - $area' || report.area == area) {
            selectedWard = entry.key;
            selectedCommunityArea = area;
            break;
          }
        }
        if (selectedWard != null) break;
      }
      // The backend AreaId is authoritative, but retaining the existing
      // dropdown selection keeps the reporting form familiar to users.
    }
    _refreshLocationPermissionState();
  }

  Future<void> _refreshLocationPermissionState() async {
    final status = await Permission.locationWhenInUse.status;
    if (!mounted) return;
    setState(() => _locationPermissionGranted = status.isGranted || status.isLimited);
  }

  @override
  Widget build(BuildContext context) {
    final isSupervisor = AuthStore.currentUser?.isStaff == true;
    final isEditing = widget.reportToEdit != null;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: pagePrimaryColor(isSupervisor: isSupervisor),
        title: const Text('Reporting'),
        actions: [
          IconButton(
            tooltip: 'Help',
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HelpPage())),
          ),
        ],
      ),
      body: Container(
        decoration: pageBackgroundDecoration(isSupervisor: isSupervisor),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.84),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(isEditing ? 'Edit Report' : 'Submit a Report',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    key: ValueKey('category-$selectedIssueType'),
                    initialValue: selectedIssueType,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Type of issue'),
                    items: issueTypes.map((item) => DropdownMenuItem(
                      value: item, child: Text(item, overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (value) => setState(() {
                      selectedIssueType = value;
                      selectedIssue = null;
                    }),
                    validator: (value) => value == null ? 'Please select the type of issue' : null,
                  ),
                  const SizedBox(height: 14),
                  if (selectedIssueType != null) ...[
                    DropdownButtonFormField<String>(
                      key: ValueKey('issue-$selectedIssueType'),
                      initialValue: availableIssues.contains(selectedIssue) ? selectedIssue : null,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Specific issue'),
                      items: availableIssues.map((item) => DropdownMenuItem(
                        value: item, child: Text(item, overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (value) => setState(() => selectedIssue = value),
                      validator: (value) => value == null ? 'Please select the specific issue' : null,
                    ),
                    const SizedBox(height: 14),
                  ],
                  DropdownButtonFormField<int>(
                    key: ValueKey('ward-$selectedWard'),
                    initialValue: selectedWard,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Ward'),
                    items: AuthStore.wardAreas.keys.map((ward) => DropdownMenuItem(
                      value: ward, child: Text('Ward $ward'),
                    )).toList(),
                    validator: (value) => value == null ? 'Please select your ward' : null,
                    onChanged: (ward) => setState(() {
                      selectedWard = ward;
                      selectedCommunityArea = null;
                    }),
                  ),
                  if (selectedWard != null) ...[
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      key: ValueKey('area-$selectedWard'),
                      initialValue: (AuthStore.wardAreas[selectedWard] ?? const <String>[])
                          .contains(selectedCommunityArea) ? selectedCommunityArea : null,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Area'),
                      items: (AuthStore.wardAreas[selectedWard] ?? const <String>[])
                          .map((area) => DropdownMenuItem(
                        value: area, child: Text(area, overflow: TextOverflow.ellipsis),
                      )).toList(),
                      validator: (value) => value == null ? 'Please select your area' : null,
                      onChanged: (value) => setState(() => selectedCommunityArea = value),
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (_locationPermissionGranted)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: const Row(children: [
                        Icon(Icons.my_location, color: Colors.green),
                        SizedBox(width: 8),
                        Expanded(child: Text(
                          'Location permission is enabled. You can use precise location or choose a point on the map.',
                          style: TextStyle(color: Colors.green, fontSize: 12),
                        )),
                      ]),
                    ),
                  Row(children: [
                    Expanded(child: _field(
                      controller: locationController,
                      label: 'Location', readOnly: true, onTap: _openLocationPicker,
                      hint: 'Tap to search for a road or choose a point on the map',
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Please choose a location on the map' : null,
                    )),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Choose location on map',
                      onPressed: _openLocationPicker,
                      icon: const Icon(Icons.map_outlined, color: Colors.red),
                      style: IconButton.styleFrom(backgroundColor: Colors.red.shade50),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  _field(
                    controller: additionalInfoController,
                    label: 'Additional Information',
                    hint: 'Add any additional details to your report',
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: _chooseImage,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(selectedImage == null
                        ? (isEditing ? 'Replace Image (optional)' : 'Add Image')
                        : 'Image selected: ${selectedImage!.name}'),
                  ),
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                      child: const Text('Cancel'),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                      child: _isSaving
                          ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(isEditing ? 'Save Changes' : 'Submit'),
                    )),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
      // Keep the original bottom navigation on the report submission screen.
      bottomNavigationBar: isEditing ? null : BottomNavigationBar(
        backgroundColor: pagePrimaryColor(isSupervisor: isSupervisor),
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const StatusPage()));
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpPage()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.help), label: 'Help'),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    String? hint,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller, validator: validator,
      readOnly: readOnly, onTap: onTap,
      decoration: InputDecoration(
        labelText: label, hintText: hint, filled: true,
        fillColor: Colors.white, border: const OutlineInputBorder(),
      ),
    );
  }

  Future<void> _openLocationPicker() async {
    final permissionStatus = await Permission.locationWhenInUse.request();
    if (!mounted) return;
    await _refreshLocationPermissionState();
    if (!mounted) return;
    final selection = await showDialog<_LocationSelection>(
      context: context,
      builder: (_) => _LocationPickerDialog(
        initialAddress: locationController.text,
        initialLocation: _parseCoordinates(pinLocationController.text),
        locationPermissionGranted: permissionStatus.isGranted || permissionStatus.isLimited,
      ),
    );
    if (!mounted || selection == null) return;
    locationController.text = selection.address.isNotEmpty
        ? selection.address : _formatCoordinates(selection.location);
    if (selection.location != null) {
      pinLocationController.text = _formatCoordinates(selection.location);
    }
  }

  Future<void> _chooseImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(child: Wrap(children: [
        ListTile(
          leading: const Icon(Icons.photo_library_outlined),
          title: const Text('Choose from gallery'),
          onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
        ),
        ListTile(
          leading: const Icon(Icons.camera_alt_outlined),
          title: const Text('Take a photo'),
          onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
        ),
      ])),
    );
    if (source == null) return;
    final image = await ImagePicker().pickImage(source: source);
    if (image != null && mounted) setState(() => selectedImage = image);
  }

  int? _getSelectedAreaId() {
    if (selectedWard == null || selectedCommunityArea == null) return null;
    const areaIds = <String, int>{
      // Ward 58
      'Brake Village': 1, 'Canelands': 2, 'Casuarina': 3,
      'Desainagar': 4, 'Ghandinagar': 5, 'Hammonds Farm': 6,
      'King Shaka International Airport zone': 7, 'La Mercy': 8,
      'Lungelani': 9, 'Pholani': 10, 'Sastri Circle / Belgate': 11,
      'Thuthukani': 12, 'Tongaat Beach / Westbrook': 13,
      // Ward 61
      'Belvedere (including Belvedere North)': 14, 'Buffelsdale': 15,
      'Chelmsford Heights': 16, 'Emona Sunhill': 17, 'Gwalas Farm': 18,
      'Mithangar': 19, 'Plain Street': 20, 'Sandfields': 21,
      'Umbhayi': 22, 'Watsonia': 23,
      // Ward 62
      'Burbreeze': 24, 'Fairbreeze': 25, 'Flamingo Heights': 26,
      'Gandhi’s Hill': 27, 'Hambanathi': 28, 'Lauriston': 29,
      'Magwaveni': 30, 'Maidstone Village': 31,
      'OThongathi CBD / Tongaat Central': 32, 'Riverside AH': 33,
      'Tongaat Industrial / Trurolands': 34, 'Vanrova': 35,
    };
    return areaIds[selectedCommunityArea];
  }

  String _getBackendIssueCategory() {
    switch (selectedIssueType) {
      case 'Water and Sanitation': return 'WaterAndSanitation';
      case 'Roads and Stormwater': return 'RoadsAndStormwater';
      case 'Electricity': return 'Electricity';
      case 'Waste Management': return 'WasteManagement';
      default: throw StateError('No valid issue category selected.');
    }
  }

  String _getBackendIssueType() {
    const names = <String, String>{
      'Burst Pipe': 'BurstPipe', 'Leaking Pipe': 'LeakingPipe',
      'No Water Supply': 'NoWaterSupply', 'Low Water Pressure': 'LowWaterPressure',
      'Blocked Sewer or Manhole': 'BlockedSewerOrManhole',
      'Sewage Spill': 'SewageSpill', 'Discolored or Dirty Water': 'DiscoloredOrDirtyWater',
      'Pothole': 'Pothole', 'Sinkhole': 'Sinkhole',
      'Blocked Storm Drain': 'BlockedStormDrain', 'Flooded Road': 'FloodedRoad',
      'Traffic Light Not Working': 'TrafficLightNotWorking',
      'Missing or Damaged Road Sign': 'MissingOrDamagedRoadSign',
      'Faded Road Markings': 'FadedRoadMarkings',
      'Street Light Not Working': 'StreetLightNotWorking',
      'Street Light On During Day': 'StreetLightOnDuringDay',
      'Power Outage': 'PowerOutage', 'Exposed Or Damaged Cable': 'ExposedOrDamagedCable',
      'Damaged Electrical Box': 'DamagedElectricalBox',
      'Missed Bin Collection': 'MissedBinCollection',
      'Illegal Dumping': 'IllegalDumping',
      'Overflowing Public Bin': 'OverflowingPublicBin',
    };
    final result = names[selectedIssue];
    if (result == null) throw StateError('No valid issue type selected.');
    return result;
  }

  LatLng? _getSelectedCoordinates() => _parseCoordinates(pinLocationController.text);

  Future<void> _submit() async {
    if (_isSaving || !(formKey.currentState?.validate() ?? false)) return;
    final areaId = _getSelectedAreaId();
    if (areaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a valid community area.'),
      ));
      return;
    }
    final coordinates = _getSelectedCoordinates();
    if (coordinates == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a point on the map or use your current location.'),
      ));
      return;
    }
    final location = locationController.text.trim();
    final existing = widget.reportToEdit;
    setState(() => _isSaving = true);
    try {
      if (existing != null) {
        final serverId = existing.backendId;
        if (serverId == null) {
          throw const AuthApiException('This report has no verified server ID.');
        }
        await AuthStore.withAccessToken((api, accessToken) => api.updateReport(
          reportId: serverId,
          accessToken: accessToken,
          issueCategory: _getBackendIssueCategory(),
          issueType: _getBackendIssueType(),
          areaId: areaId,
          location: location,
          latitude: coordinates.latitude,
          longitude: coordinates.longitude,
          description: additionalInfoController.text.trim(),
          imagePath: selectedImage?.path,
        ));
        ReportStore.updateReport(
          report: existing,
          issueType: selectedIssueType!,
          issue: selectedIssue!,
          description: additionalInfoController.text,
          area: 'Ward $selectedWard - $selectedCommunityArea',
          areaId: areaId,
          locationAddress: location,
          pinLocation: pinLocationController.text,
          latitude: coordinates.latitude,
          longitude: coordinates.longitude,
          imagePath: selectedImage?.path,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report updated successfully.')),
        );
        Navigator.pop(context, true);
        return;
      }

      final response = await AuthStore.withAccessToken((api, accessToken) => api.createReport(
        accessToken: accessToken,
        issueCategory: _getBackendIssueCategory(),
        issueType: _getBackendIssueType(),
        areaId: areaId,
        location: location,
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
        description: additionalInfoController.text.trim(),
        imagePath: selectedImage?.path,
      ));

      // Local cache IDs are NOT SQL Server report IDs.
      final rawServerId = response['id'] ?? response['reportId'] ??
          (response['report'] is Map ? response['report']['id'] : null);
      final serverId = rawServerId is num
          ? rawServerId.toInt() : int.tryParse(rawServerId?.toString() ?? '');
      final rawIssueId = response['issueId'];
      final issueId = rawIssueId is num
          ? rawIssueId.toInt()
          : int.tryParse(rawIssueId?.toString() ?? '');
      final report = ReportStore.addReport(
        backendId: serverId,
        issueId: issueId,
        status: response['status']?.toString() ?? 'Reported',
        areaId: areaId,
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
        issueType: selectedIssueType!,
        issue: selectedIssue!,
        area: 'Ward $selectedWard - $selectedCommunityArea',
        description: additionalInfoController.text,
        pinLocation: pinLocationController.text,
        locationAddress: location,
        imagePath: selectedImage?.path ?? '',
        isOfflineSubmission: false,
      );
      if (report == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('The report was sent, but could not be saved locally.'),
        ));
        return;
      }
      await ReportStore.markReportSubmitted(report);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Report submitted successfully.'),
      ));
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const StatusPage()));
    } on AuthApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not save the report. Please check your connection and try again.'),
      ));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    locationController.dispose();
    pinLocationController.dispose();
    additionalInfoController.dispose();
    super.dispose();
  }
}

class _LocationSelection {
  const _LocationSelection({required this.address, required this.location});
  final String address;
  final LatLng? location;
}

class _LocationPickerDialog extends StatefulWidget {
  const _LocationPickerDialog({
    required this.initialAddress,
    required this.initialLocation,
    required this.locationPermissionGranted,
  });
  final String initialAddress;
  final LatLng? initialLocation;
  final bool locationPermissionGranted;

  @override
  State<_LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<_LocationPickerDialog> {
  static const _mapStyle = 'https://tiles.openfreemap.org/styles/liberty';
  static const _southAfricaCenter = LatLng(-28.5, 24.7);
  late final TextEditingController _addressController;
  MapLibreMapController? _mapController;
  LatLng? _selectedLocation;
  bool _styleLoaded = false;
  late bool _locationPermissionGranted;
  bool _isSearching = false;
  bool _isLocating = false;
  bool _locationServicesDisabled = false;
  String? _searchError;
  DateTime? _lastNominatimRequestAt;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.initialAddress);
    _selectedLocation = widget.initialLocation;
    _locationPermissionGranted = widget.locationPermissionGranted;
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final dialogHeight = (screenSize.height - 48).clamp(320.0, 720.0).toDouble();
    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: SizedBox(
        width: screenSize.width - 48,
        height: dialogHeight,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              const Expanded(child: Text('Choose a location',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              IconButton(tooltip: 'Close map',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close)),
            ]),
            const SizedBox(height: 8),
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: MapLibreMap(
                styleString: _mapStyle,
                myLocationEnabled: _locationPermissionGranted,
                initialCameraPosition: CameraPosition(
                  target: widget.initialLocation ?? _southAfricaCenter,
                  zoom: widget.initialLocation == null ? 5 : 15,
                ),
                onMapCreated: (controller) => _mapController = controller,
                onStyleLoadedCallback: _onStyleLoaded,
                onMapClick: (_, coordinates) {
                  setState(() {
                    _selectedLocation = coordinates;
                    _searchError = null;
                  });
                  unawaited(_updateMapMarker());
                },
              ),
            )),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _isLocating || _isSearching ? null : _moveToCurrentLocation,
                icon: const Icon(Icons.my_location),
                label: Text(_isLocating ? 'Finding location...'
                    : _locationPermissionGranted ? 'Use current location'
                    : 'Enable precise location'),
              ),
            ),
            if (_locationServicesDisabled)
              Align(alignment: Alignment.centerRight,
                  child: TextButton(onPressed: _openDeviceLocationSettings,
                      child: const Text('Open device location settings'))),
            const Text('Search and address lookup use OpenStreetMap. '
                'Your search or coordinates are sent to its services. '
                '© OpenStreetMap contributors.',
                style: TextStyle(fontSize: 11, color: Colors.black54)),
            const SizedBox(height: 8),
            Text(_selectedLocation == null
                ? 'Search for a road, or tap the map to drop a pin.'
                : 'Selected: ${_formatCoordinates(_selectedLocation)}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            TextField(
              controller: _addressController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) {
                if (!_isSearching && !_isLocating) _searchRoad();
              },
              decoration: InputDecoration(
                labelText: 'Road name, address, or landmark',
                hintText: 'For example, a road and suburb',
                border: const OutlineInputBorder(),
                errorText: _searchError,
                suffixIcon: IconButton(
                  tooltip: 'Search map',
                  onPressed: _isSearching || _isLocating ? null : _searchRoad,
                  icon: _isSearching
                      ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _selectedLocation == null ? null : () => Navigator.pop(
                  context, _LocationSelection(
                address: _addressController.text.trim(),
                location: _selectedLocation,
              )),
              child: const Text('Use this location'),
            ),
          ]),
        ),
      ),
    );
  }

  void _onStyleLoaded() {
    _styleLoaded = true;
    if (_selectedLocation != null) {
      unawaited(_updateMapMarker());
    } else if (_addressController.text.trim().isNotEmpty) {
      unawaited(_searchRoad());
    }
  }

  Future<void> _updateMapMarker() async {
    final controller = _mapController;
    final location = _selectedLocation;
    if (!_styleLoaded || controller == null || location == null) return;
    await controller.clearCircles();
    await controller.addCircle(CircleOptions(
      geometry: location, circleRadius: 9,
      circleColor: '#E53935', circleStrokeColor: '#FFFFFF',
      circleStrokeWidth: 2,
    ));
  }

  Future<void> _moveToCurrentLocation() async {
    if (_isLocating || _isSearching) return;
    setState(() {
      _isLocating = true;
      _locationServicesDisabled = false;
    });
    try {
      var status = await Permission.locationWhenInUse.status;
      if (!status.isGranted && !status.isLimited) {
        status = await Permission.locationWhenInUse.request();
      }
      if (!status.isGranted && !status.isLimited) {
        if (status.isPermanentlyDenied || status.isRestricted) {
          await openAppSettings();
          status = await Permission.locationWhenInUse.status;
        }
        if (!mounted) return;
        setState(() {
          _locationPermissionGranted = status.isGranted || status.isLimited;
          _searchError = 'Allow location access in app settings to use your precise location.';
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _locationPermissionGranted = true;
        _searchError = null;
      });
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return;
      final location = LatLng(position.latitude, position.longitude);
      setState(() => _selectedLocation = location);
      if (_mapController != null) {
        await _mapController!.animateCamera(CameraUpdate.newLatLngZoom(location, 17));
        await _updateMapMarker();
      }
      await _reverseGeocode(location);
    } on LocationServiceDisabledException {
      if (mounted) setState(() {
        _locationServicesDisabled = true;
        _searchError = 'Turn on device location services to find your precise location.';
      });
    } on PermissionDeniedException {
      if (mounted) setState(() => _searchError =
      'Allow location access in app settings to use your precise location.');
    } on TimeoutException {
      if (mounted) setState(() => _searchError =
      'Could not get your location in time. Try again or choose a point on the map.');
    } catch (_) {
      if (mounted) setState(() => _searchError =
      'Could not find your location. Try again or choose a point on the map.');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _openDeviceLocationSettings() async {
    final opened = await Geolocator.openLocationSettings();
    if (!mounted) return;
    if (opened) {
      await _moveToCurrentLocation();
    } else {
      setState(() => _searchError = 'Could not open device location settings.');
    }
  }

  Future<void> _reverseGeocode(LatLng location) async {
    try {
      await _waitForNominatimRateLimit();
      if (!mounted) return;
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'jsonv2',
        'lat': location.latitude.toString(),
        'lon': location.longitude.toString(),
        'zoom': '18',
        'addressdetails': '1',
      });
      final response = await http.get(uri, headers: {
        'User-Agent': 'ITAppLocationPicker/1.0',
      }).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (response.statusCode != 200) {
        setState(() => _searchError =
        'Your coordinates were found, but the address lookup failed (HTTP ${response.statusCode}).');
        return;
      }
      final result = jsonDecode(response.body);
      if (result is Map && result['display_name'] is String) {
        setState(() {
          _addressController.text = result['display_name'] as String;
          _searchError = null;
        });
      } else {
        setState(() => _searchError =
        'Your coordinates were found, but no street address was available.');
      }
    } on http.ClientException {
      if (mounted) setState(() => _searchError =
      'Your coordinates were found, but the address lookup could not connect.');
    } on TimeoutException {
      if (mounted) setState(() => _searchError =
      'Your coordinates were found, but the address lookup timed out.');
    } on FormatException {
      if (mounted) setState(() => _searchError =
      'Your coordinates were found, but the address response was unreadable.');
    } catch (_) {
      if (mounted) setState(() => _searchError =
      'Your coordinates were found, but the address lookup could not complete.');
    }
  }

  Future<void> _searchRoad() async {
    if (_isSearching || _isLocating) return;
    final query = _addressController.text.trim();
    if (query.isEmpty) {
      setState(() => _searchError = 'Enter a road name or address to search.');
      return;
    }
    setState(() {
      _isSearching = true;
      _searchError = null;
    });
    try {
      await _waitForNominatimRateLimit();
      if (!mounted) return;
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'format': 'jsonv2', 'q': query, 'countrycodes': 'za', 'limit': '1',
      });
      final response = await http.get(uri, headers: {
        'User-Agent': 'ITAppLocationPicker/1.0',
      }).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (response.statusCode != 200) {
        setState(() => _searchError =
        'Location search failed (HTTP ${response.statusCode}). Try again.');
        return;
      }
      final results = jsonDecode(response.body);
      if (results is! List || results.isEmpty || results.first is! Map) {
        setState(() => _searchError =
        'No matching location found. Try adding the suburb or city.');
        return;
      }
      final result = results.first as Map;
      final latitude = double.tryParse(result['lat']?.toString() ?? '');
      final longitude = double.tryParse(result['lon']?.toString() ?? '');
      if (latitude == null || longitude == null ||
          !latitude.isFinite || !longitude.isFinite ||
          latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
        setState(() => _searchError =
        'The location search returned invalid coordinates. Try again.');
        return;
      }
      final location = LatLng(latitude, longitude);
      setState(() {
        _selectedLocation = location;
        _searchError = null;
      });
      if (_mapController != null) {
        await _mapController!.animateCamera(CameraUpdate.newLatLngZoom(location, 16));
        await _updateMapMarker();
      }
    } on http.ClientException {
      if (mounted) setState(() => _searchError =
      'Could not connect to location search. Check your internet connection.');
    } on TimeoutException {
      if (mounted) setState(() => _searchError = 'Location search timed out. Try again.');
    } on FormatException {
      if (mounted) setState(() => _searchError =
      'Location search returned an unreadable response. Try again.');
    } catch (_) {
      if (mounted) setState(() => _searchError =
      'Location search failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _waitForNominatimRateLimit() async {
    final lastRequest = _lastNominatimRequestAt;
    if (lastRequest != null) {
      final remaining = const Duration(seconds: 1) - DateTime.now().difference(lastRequest);
      if (remaining > Duration.zero) await Future.delayed(remaining);
    }
    _lastNominatimRequestAt = DateTime.now();
  }
}

LatLng? _parseCoordinates(String value) {
  final parts = value.split(',');
  if (parts.length != 2) return null;
  final latitude = double.tryParse(parts[0].trim());
  final longitude = double.tryParse(parts[1].trim());
  if (latitude == null || longitude == null || !latitude.isFinite ||
      !longitude.isFinite || latitude < -90 || latitude > 90 ||
      longitude < -180 || longitude > 180) return null;
  return LatLng(latitude, longitude);
}

String _formatCoordinates(LatLng? location) => location == null
    ? '' : '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
