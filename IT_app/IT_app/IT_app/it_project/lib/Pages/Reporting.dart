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

const Color _orange = Color(0xFFC94F1B);
const Color _cream = Color(0xFFFFF8F4);
const Color _darkText = Color(0xFF292524);
const Color _secondaryText = Color(0xFF78716C);
const Color _borderColor = Color(0xFFE8C7B8);
const Color _lightOrange = Color(0xFFFFE9DC);

class ReportingPage extends StatefulWidget {
  const ReportingPage({super.key});

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

  final issueTypes = [
    'Roads and Stormwater',
    'Electricity',
    'Water and Sanitation',
    'Waste Management',
  ];

  final roadIssues = [
    'Pothole',
    'Sinkhole',
    'Blocked Storm Drain',
    'Flooded Road',
    'Traffic Light Not Working',
  ];

  final electricityIssues = [
    'Street Light Not Working',
    'Street Light On During Day',
    'Power Outage',
    'Exposed Or Damaged Cable',
    'Damaged Electrical Box',
  ];

  final waterIssues = [
    'Burst Pipe',
    'Leaking Pipe',
    'No Water Supply',
    'Low Water Pressure',
    'Blocked Sewer or Manhole',
    'Sewage Spill',
    'Discolored or Dirty Water',
  ];

  final wasteIssues = [
    'Missed Bin Collection',
    'Illegal Dumping',
    'Overflowing Public Bin',
  ];

  String? selectedIssueType;
  String? selectedIssue;
  int? selectedWard;
  String? selectedCommunityArea;
  XFile? selectedImage;

  List<String> get availableIssues {
    switch (selectedIssueType) {
      case 'Roads and Stormwater':
        return roadIssues;
      case 'Electricity':
        return electricityIssues;
      case 'Water and Sanitation':
        return waterIssues;
      case 'Waste Management':
        return wasteIssues;
      default:
        return const [];
    }
  }

  @override
  void initState() {
    super.initState();
    _refreshLocationPermissionState();
  }

  Future<void> _refreshLocationPermissionState() async {
    final status = await Permission.locationWhenInUse.status;

    if (!mounted) return;

    setState(() {
      _locationPermissionGranted =
          status.isGranted || status.isLimited;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSupervisor = AuthStore.currentUser?.isStaff == true;

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: _orange,
          secondary: _orange,
          surface: Colors.white,
          onSurface: _darkText,
        ),
        scaffoldBackgroundColor: _cream,
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: _orange,
          selectionColor: _lightOrange,
          selectionHandleColor: _orange,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: pagePrimaryColor(isSupervisor: isSupervisor),
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Reporting',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Help',
              icon: const Icon(
                Icons.help_outline,
                color: Colors.white,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HelpPage(),
                ),
              ),
            ),
          ],
        ),
        body: Container(
          decoration: pageBackgroundDecoration(
            isSupervisor: isSupervisor,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _borderColor.withValues(alpha: 0.65),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _darkText.withValues(alpha: 0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Submit a Report',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: _darkText,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Type of issue dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedIssueType,
                      isExpanded: true,
                      style: const TextStyle(
                        color: _darkText,
                        fontSize: 14,
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _orange,
                      ),
                      decoration: _inputDecoration(
                        label: 'Type of issue',
                      ),
                      items: issueTypes
                          .map(
                            (issue) => DropdownMenuItem(
                          value: issue,
                          child: Text(issue),
                        ),
                      )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedIssueType = value;
                          selectedIssue = null;
                        });
                      },
                      validator: (value) => value == null
                          ? 'Please select the type of issue'
                          : null,
                    ),

                    const SizedBox(height: 14),

                    // Specific issue dropdown
                    if (selectedIssueType != null)
                      DropdownButtonFormField<String>(
                        initialValue: selectedIssue,
                        isExpanded: true,
                        style: const TextStyle(
                          color: _darkText,
                          fontSize: 14,
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: _orange,
                        ),
                        decoration: _inputDecoration(
                          label: 'Specific issue',
                        ),
                        items: availableIssues
                            .map(
                              (issue) => DropdownMenuItem(
                            value: issue,
                            child: Text(issue),
                          ),
                        )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedIssue = value;
                          });
                        },
                        validator: (value) => value == null
                            ? 'Please select the specific issue'
                            : null,
                      ),

                    if (selectedIssueType != null)
                      const SizedBox(height: 14),

                    // Ward dropdown
                    DropdownButtonFormField<int>(
                      initialValue: selectedWard,
                      isExpanded: true,
                      style: const TextStyle(
                        color: _darkText,
                        fontSize: 14,
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _orange,
                      ),
                      decoration: _inputDecoration(
                        label: 'Ward',
                      ),
                      items: AuthStore.wardAreas.keys
                          .map(
                            (ward) => DropdownMenuItem(
                          value: ward,
                          child: Text(
                            'Ward $ward',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                          .toList(),
                      validator: (value) => value == null
                          ? 'Please select your ward'
                          : null,
                      onChanged: (ward) {
                        setState(() {
                          selectedWard = ward;

                          // Reset the area when the ward changes.
                          selectedCommunityArea = null;
                        });
                      },
                    ),

                    // Area dropdown appears after selecting a ward.
                    if (selectedWard != null) ...[
                      const SizedBox(height: 14),

                      DropdownButtonFormField<String>(
                        initialValue: selectedCommunityArea,
                        isExpanded: true,
                        style: const TextStyle(
                          color: _darkText,
                          fontSize: 14,
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: _orange,
                        ),
                        decoration: _inputDecoration(
                          label: 'Area',
                        ),
                        items: (
                            AuthStore.wardAreas[selectedWard] ?? const []
                        )
                            .map(
                              (area) => DropdownMenuItem(
                            value: area,
                            child: Text(
                              area,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                            .toList(),
                        validator: (value) => value == null
                            ? 'Please select your area'
                            : null,
                        onChanged: (area) {
                          setState(() {
                            selectedCommunityArea = area;
                          });
                        },
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Location permission information
                    if (_locationPermissionGranted)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9F1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFC6E5CB),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.my_location,
                              color: Color(0xFF38834A),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Location permission is enabled. '
                                    'You can use precise location or choose '
                                    'a point on the map.',
                                style: TextStyle(
                                  color: Color(0xFF38834A),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Location field and map button
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            controller: locationController,
                            label: 'Location',
                            readOnly: true,
                            onTap: _openLocationPicker,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'Please choose a location on the map';
                              }

                              return null;
                            },
                            hint:
                            'Tap to search for a road or choose a point on the map',
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Choose location on map',
                          onPressed: _openLocationPicker,
                          icon: const Icon(
                            Icons.map_outlined,
                            color: _orange,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: _lightOrange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(
                                color: _borderColor,
                              ),
                            ),
                            padding: const EdgeInsets.all(14),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Additional information
                    _field(
                      controller: additionalInfoController,
                      label: 'Additional Information',
                      hint: 'Add any additional details to your report',
                    ),

                    const SizedBox(height: 14),

                    // Image upload
                    OutlinedButton.icon(
                      onPressed: _chooseImage,
                      icon: const Icon(
                        Icons.add_a_photo_outlined,
                        color: _orange,
                      ),
                      label: Text(
                        selectedImage == null
                            ? 'Add Image'
                            : 'Image selected: ${selectedImage!.name}',
                        style: const TextStyle(
                          color: _orange,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        foregroundColor: _orange,
                        backgroundColor: _lightOrange.withValues(
                          alpha: 0.35,
                        ),
                        side: const BorderSide(
                          color: _borderColor,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Cancel and submit buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              foregroundColor: _orange,
                              side: const BorderSide(
                                color: _orange,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              backgroundColor: _orange,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Submit',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Bottom navigation
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: pagePrimaryColor(
            isSupervisor: isSupervisor,
          ),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          currentIndex: 1,
          onTap: (index) {
            if (index == 0) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StatusPage(),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HelpPage(),
                ),
              );
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.help),
              label: 'Help',
            ),
          ],
        ),
      ),
    );
  }

  // Reusable text field
  Widget _field({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    String? hint,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(
        color: _darkText,
        fontSize: 14,
      ),
      decoration: _inputDecoration(
        label: label,
        hint: hint,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
      labelStyle: const TextStyle(
        color: _secondaryText,
        fontSize: 14,
      ),
      floatingLabelStyle: const TextStyle(
        color: _orange,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: const TextStyle(
        color: _secondaryText,
        fontSize: 12,
      ),
      filled: true,
      fillColor: _cream,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 16,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: _borderColor,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: _orange,
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.6,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: _borderColor,
        ),
      ),
    );
  }

  // Open the map location picker
  Future<void> _openLocationPicker() async {
    final permissionStatus =
    await Permission.locationWhenInUse.request();

    if (!mounted) return;

    await _refreshLocationPermissionState();

    if (!mounted) return;

    final selection = await showDialog<_LocationSelection>(
      context: context,
      builder: (_) => _LocationPickerDialog(
        initialAddress: locationController.text,
        initialLocation: _parseCoordinates(
          pinLocationController.text,
        ),
        locationPermissionGranted:
        permissionStatus.isGranted ||
            permissionStatus.isLimited,
      ),
    );

    if (!mounted || selection == null) return;

    locationController.text = selection.address.isNotEmpty
        ? selection.address
        : _formatCoordinates(selection.location);

    if (selection.location != null) {
      pinLocationController.text =
          _formatCoordinates(selection.location);
    }
  }

  // Choose an image from the gallery or camera
  Future<void> _chooseImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: _orange,
              ),
              title: const Text(
                'Choose from gallery',
                style: TextStyle(color: _darkText),
              ),
              onTap: () => Navigator.pop(
                sheetContext,
                ImageSource.gallery,
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: _orange,
              ),
              title: const Text(
                'Take a photo',
                style: TextStyle(color: _darkText),
              ),
              onTap: () => Navigator.pop(
                sheetContext,
                ImageSource.camera,
              ),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final image = await ImagePicker().pickImage(
      source: source,
    );

    if (image != null && mounted) {
      setState(() {
        selectedImage = image;
      });
    }
  }

  // Submit the report
  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) return;

    final report = ReportStore.addReport(
      issueType: selectedIssueType!,
      issue: selectedIssue!,
      area: 'Ward $selectedWard - $selectedCommunityArea',
      description: additionalInfoController.text,
      pinLocation: pinLocationController.text,
      locationAddress: locationController.text,
      imagePath: selectedImage?.path ?? '',
      isOfflineSubmission: !ReportStore.isOnline,
    );

    if (report == null) return;
    if (!mounted) return;

    final message = report.storageType == 'offline'
        ? 'Report saved offline. It will sync when the internet is available.'
        : 'Report logged and sent successfully.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const StatusPage(),
      ),
    );
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

// Stores the selected address and coordinates.
class _LocationSelection {
  const _LocationSelection({
    required this.address,
    required this.location,
  });

  final String address;
  final LatLng? location;
}

// Map location picker dialog
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
  State<_LocationPickerDialog> createState() =>
      _LocationPickerDialogState();
}

class _LocationPickerDialogState
    extends State<_LocationPickerDialog> {
  static const _mapStyle =
      'https://tiles.openfreemap.org/styles/liberty';

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

    _addressController = TextEditingController(
      text: widget.initialAddress,
    );

    _selectedLocation = widget.initialLocation;
    _locationPermissionGranted =
        widget.locationPermissionGranted;
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    final dialogHeight = (screenSize.height - 48)
        .clamp(320.0, 720.0)
        .toDouble();

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: _orange,
          secondary: _orange,
          surface: Colors.white,
          onSurface: _darkText,
        ),
      ),
      child: Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(
            color: _borderColor,
          ),
        ),
        child: SizedBox(
          width: screenSize.width - 48,
          height: dialogHeight,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Choose a location',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _darkText,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close map',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: _secondaryText,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Map
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: MapLibreMap(
                      styleString: _mapStyle,
                      myLocationEnabled:
                      _locationPermissionGranted,
                      initialCameraPosition: CameraPosition(
                        target: widget.initialLocation ??
                            _southAfricaCenter,
                        zoom: widget.initialLocation == null
                            ? 5
                            : 15,
                      ),
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                      onStyleLoadedCallback: _onStyleLoaded,
                      onMapClick: (_, coordinates) {
                        setState(() {
                          _selectedLocation = coordinates;
                          _searchError = null;
                        });

                        unawaited(_updateMapMarker());
                      },
                    ),
                  ),
                ),

                // Current location button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _isLocating || _isSearching
                        ? null
                        : _moveToCurrentLocation,
                    icon: const Icon(
                      Icons.my_location,
                      color: _orange,
                    ),
                    label: Text(
                      _isLocating
                          ? 'Finding location...'
                          : _locationPermissionGranted
                          ? 'Use current location'
                          : 'Enable precise location',
                      style: const TextStyle(
                        color: _orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                if (_locationServicesDisabled)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _openDeviceLocationSettings,
                      child: const Text(
                        'Open device location settings',
                        style: TextStyle(
                          color: _orange,
                        ),
                      ),
                    ),
                  ),

                const Text(
                  'Search and address lookup use OpenStreetMap. '
                      'Your search or coordinates are sent to its services. '
                      '©️ OpenStreetMap contributors.',
                  style: TextStyle(
                    fontSize: 11,
                    color: _secondaryText,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  _selectedLocation == null
                      ? 'Search for a road, or tap the map to drop a pin.'
                      : 'Selected: ${_formatCoordinates(_selectedLocation)}',
                  style: const TextStyle(
                    color: _darkText,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 8),

                // Search for an address or road
                TextField(
                  controller: _addressController,
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(
                    color: _darkText,
                    fontSize: 14,
                  ),
                  onSubmitted: (_) {
                    if (!_isSearching && !_isLocating) {
                      _searchRoad();
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Road name, address, or landmark',
                    hintText: 'For example, a road and suburb',
                    labelStyle: const TextStyle(
                      color: _secondaryText,
                    ),
                    floatingLabelStyle: const TextStyle(
                      color: _orange,
                    ),
                    hintStyle: const TextStyle(
                      color: _secondaryText,
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: _cream,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: _borderColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: _orange,
                        width: 1.6,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.redAccent,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.redAccent,
                        width: 1.6,
                      ),
                    ),
                    errorText: _searchError,
                    suffixIcon: IconButton(
                      tooltip: 'Search map',
                      onPressed:
                      _isSearching || _isLocating
                          ? null
                          : _searchRoad,
                      icon: _isSearching
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _orange,
                        ),
                      )
                          : const Icon(
                        Icons.search,
                        color: _orange,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                FilledButton(
                  onPressed: _selectedLocation == null &&
                      _addressController.text.trim().isEmpty
                      ? null
                      : () => Navigator.pop(
                    context,
                    _LocationSelection(
                      address:
                      _addressController.text.trim(),
                      location: _selectedLocation,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _borderColor,
                    disabledForegroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Use this location',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
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

  // Display the selected point on the map
  Future<void> _updateMapMarker() async {
    final controller = _mapController;
    final location = _selectedLocation;

    if (!_styleLoaded ||
        controller == null ||
        location == null) {
      return;
    }

    await controller.clearCircles();

    await controller.addCircle(
      CircleOptions(
        geometry: location,
        circleRadius: 9,
        circleColor: '#C94F1B',
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 2,
      ),
    );
  }

  // Find the device's current location
  Future<void> _moveToCurrentLocation() async {
    if (_isLocating || _isSearching) return;

    setState(() {
      _isLocating = true;
      _locationServicesDisabled = false;
    });

    try {
      var permissionStatus =
      await Permission.locationWhenInUse.status;

      if (!permissionStatus.isGranted &&
          !permissionStatus.isLimited) {
        permissionStatus =
        await Permission.locationWhenInUse.request();
      }

      if (!permissionStatus.isGranted &&
          !permissionStatus.isLimited) {
        if (permissionStatus.isPermanentlyDenied ||
            permissionStatus.isRestricted) {
          await openAppSettings();

          permissionStatus =
          await Permission.locationWhenInUse.status;
        }

        if (!mounted) return;

        setState(() {
          _locationPermissionGranted =
              permissionStatus.isGranted ||
                  permissionStatus.isLimited;

          _searchError =
          'Allow location access in app settings to use your precise location.';
        });

        return;
      }

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

      final location = LatLng(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _selectedLocation = location;
      });

      final controller = _mapController;

      if (controller != null) {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(location, 17),
        );

        await _updateMapMarker();
      }

      await _reverseGeocode(location);
    } on LocationServiceDisabledException {
      if (mounted) {
        setState(() {
          _locationServicesDisabled = true;

          _searchError =
          'Turn on device location services to find your precise location.';
        });
      }
    } on PermissionDeniedException {
      if (mounted) {
        setState(() {
          _searchError =
          'Allow location access in app settings to use your precise location.';
        });
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _searchError =
          'Could not get your location in time. Try again or choose a point on the map.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  // Open device location settings
  Future<void> _openDeviceLocationSettings() async {
    final opened = await Geolocator.openLocationSettings();

    if (!mounted) return;

    if (opened) {
      await _moveToCurrentLocation();
    } else {
      setState(() {
        _searchError =
        'Could not open device location settings.';
      });
    }
  }

  // Convert coordinates into a readable address
  Future<void> _reverseGeocode(LatLng location) async {
    try {
      await _waitForNominatimRateLimit();

      if (!mounted) return;

      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/reverse',
        {
          'format': 'jsonv2',
          'lat': location.latitude.toString(),
          'lon': location.longitude.toString(),
          'zoom': '18',
          'addressdetails': '1',
        },
      );

      final response = await http
          .get(
        uri,
        headers: {
          'User-Agent': 'ITAppLocationPicker/1.0',
        },
      )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode != 200) {
        setState(() {
          _searchError =
          'Your coordinates were found, but the address lookup failed (HTTP ${response.statusCode}).';
        });

        return;
      }

      final result = jsonDecode(response.body);

      if (result is Map &&
          result['display_name'] is String) {
        setState(() {
          _addressController.text =
          result['display_name'] as String;
          _searchError = null;
        });
      } else {
        setState(() {
          _searchError =
          'Your coordinates were found, but no street address was available.';
        });
      }
    } on http.ClientException {
      if (mounted) {
        setState(() {
          _searchError =
          'Your coordinates were found, but the address lookup could not connect.';
        });
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _searchError =
          'Your coordinates were found, but the address lookup timed out.';
        });
      }
    } on FormatException {
      if (mounted) {
        setState(() {
          _searchError =
          'Your coordinates were found, but the address response was unreadable.';
        });
      }
    }
  }

  // Search for a road or address
  Future<void> _searchRoad() async {
    if (_isSearching || _isLocating) return;

    final query = _addressController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _searchError =
        'Enter a road name or address to search.';
      });

      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      await _waitForNominatimRateLimit();

      if (!mounted) return;

      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/search',
        {
          'format': 'jsonv2',
          'q': query,
          'countrycodes': 'za',
          'limit': '1',
        },
      );

      final response = await http
          .get(
        uri,
        headers: {
          'User-Agent': 'ITAppLocationPicker/1.0',
        },
      )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode != 200) {
        setState(() {
          _searchError =
          'Location search failed (HTTP ${response.statusCode}). Try again.';
        });

        return;
      }

      final results = jsonDecode(response.body);

      if (results is! List ||
          results.isEmpty ||
          results.first is! Map) {
        setState(() {
          _searchError =
          'No matching location found. Try adding the suburb or city.';
        });

        return;
      }

      final result = results.first as Map;

      final latitude = double.tryParse(
        result['lat']?.toString() ?? '',
      );

      final longitude = double.tryParse(
        result['lon']?.toString() ?? '',
      );

      if (latitude == null ||
          longitude == null ||
          !latitude.isFinite ||
          !longitude.isFinite ||
          latitude < -90 ||
          latitude > 90 ||
          longitude < -180 ||
          longitude > 180) {
        setState(() {
          _searchError =
          'The location search returned invalid coordinates. Try again.';
        });

        return;
      }

      final location = LatLng(latitude, longitude);

      setState(() {
        _selectedLocation = location;
        _searchError = null;
      });

      final controller = _mapController;

      if (controller != null) {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(location, 16),
        );

        await _updateMapMarker();
      }
    } on http.ClientException {
      if (mounted) {
        setState(() {
          _searchError =
          'Could not connect to location search. Check your internet connection.';
        });
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _searchError =
          'Location search timed out. Try again.';
        });
      }
    } on FormatException {
      if (mounted) {
        setState(() {
          _searchError =
          'Location search returned an unreadable response. Try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  // Respect the OpenStreetMap search rate limit
  Future<void> _waitForNominatimRateLimit() async {
    final lastRequest = _lastNominatimRequestAt;

    if (lastRequest != null) {
      final remaining = const Duration(seconds: 1) -
          DateTime.now().difference(lastRequest);

      if (remaining > Duration.zero) {
        await Future.delayed(remaining);
      }
    }

    _lastNominatimRequestAt = DateTime.now();
  }
}

// Parse saved coordinates
LatLng? _parseCoordinates(String value) {
  final parts = value.split(',');

  if (parts.length != 2) return null;

  final latitude = double.tryParse(parts[0].trim());
  final longitude = double.tryParse(parts[1].trim());

  if (latitude == null ||
      longitude == null ||
      !latitude.isFinite ||
      !longitude.isFinite ||
      latitude < -90 ||
      latitude > 90 ||
      longitude < -180 ||
      longitude > 180) {
    return null;
  }

  return LatLng(latitude, longitude);
}

// Format coordinates for storage
String _formatCoordinates(LatLng? location) {
  if (location == null) return '';

  return '${location.latitude.toStringAsFixed(6)}, '
      '${location.longitude.toStringAsFixed(6)}';
}