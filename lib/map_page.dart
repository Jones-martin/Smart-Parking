import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

// ── Parking Station Model ────────────────────────────────────────────────────
class ParkingStation {
  final String id;
  final String name;
  final String address;
  final LatLng position;
  final int totalSlots;
  final int availableSlots;
  final double pricePerHour;
  final String city;

  const ParkingStation({
    required this.id,
    required this.name,
    required this.address,
    required this.position,
    required this.totalSlots,
    required this.availableSlots,
    required this.pricePerHour,
    required this.city,
  });

  bool get isFull => availableSlots == 0;
  double get occupancyPct =>
      totalSlots > 0 ? (totalSlots - availableSlots) / totalSlots : 0;

  Color get statusColor {
    if (isFull) return Colors.redAccent;
    final free = availableSlots / totalSlots;
    if (free > 0.5) return Colors.greenAccent;
    if (free > 0.2) return Colors.amber;
    return Colors.redAccent;
  }

  String get statusLabel {
    if (isFull) return 'Full';
    final free = availableSlots / totalSlots;
    if (free > 0.5) return 'Available';
    if (free > 0.2) return 'Filling Up';
    return 'Almost Full';
  }
}

// ── All Parking Stations ─────────────────────────────────────────────────────
const List<ParkingStation> kParkingStations = [
  // ── Chennai ──────────────────────────────────────────────────────────────
  ParkingStation(
    id: 'CH-1',
    name: 'Station CH-1 — T.Nagar',
    address: 'Pondy Bazaar, T.Nagar, Chennai',
    position: LatLng(13.0400, 80.2340),
    totalSlots: 120,
    availableSlots: 42,
    pricePerHour: 60,
    city: 'Chennai',
  ),
  ParkingStation(
    id: 'CH-2',
    name: 'Station CH-2 — Anna Nagar',
    address: '2nd Avenue, Anna Nagar, Chennai',
    position: LatLng(13.0868, 80.2101),
    totalSlots: 80,
    availableSlots: 0,
    pricePerHour: 50,
    city: 'Chennai',
  ),
  ParkingStation(
    id: 'CH-3',
    name: 'Station CH-3 — Adyar',
    address: 'Gandhi Nagar, Adyar, Chennai',
    position: LatLng(13.0012, 80.2565),
    totalSlots: 60,
    availableSlots: 55,
    pricePerHour: 40,
    city: 'Chennai',
  ),
  ParkingStation(
    id: 'CH-4',
    name: 'Station CH-4 — Egmore',
    address: 'Egmore High Road, Chennai',
    position: LatLng(13.0799, 80.2620),
    totalSlots: 100,
    availableSlots: 8,
    pricePerHour: 50,
    city: 'Chennai',
  ),
  ParkingStation(
    id: 'CH-5',
    name: 'Station CH-5 — OMR IT Park',
    address: 'Old Mahabalipuram Road, Sholinganallur',
    position: LatLng(12.9010, 80.2280),
    totalSlots: 200,
    availableSlots: 130,
    pricePerHour: 60,
    city: 'Chennai',
  ),
  ParkingStation(
    id: 'CH-6',
    name: 'Station CH-6 — Central Station',
    address: 'Chennai Central, Park Town',
    position: LatLng(13.0827, 80.2750),
    totalSlots: 150,
    availableSlots: 60,
    pricePerHour: 40,
    city: 'Chennai',
  ),

  // ── Coimbatore ───────────────────────────────────────────────────────────
  ParkingStation(
    id: 'CB-A',
    name: 'Station CB-A — RS Puram',
    address: 'Scheme Road, RS Puram, Coimbatore',
    position: LatLng(11.0168, 76.9558),
    totalSlots: 50,
    availableSlots: 18,
    pricePerHour: 50,
    city: 'Coimbatore',
  ),
  ParkingStation(
    id: 'CB-B',
    name: 'Station CB-B — Gandhipuram',
    address: 'Cross Cut Road, Gandhipuram, Coimbatore',
    position: LatLng(11.0210, 76.9718),
    totalSlots: 80,
    availableSlots: 0,
    pricePerHour: 40,
    city: 'Coimbatore',
  ),
  ParkingStation(
    id: 'CB-C',
    name: 'Station CB-C — Town Hall',
    address: 'Town Hall Road, Coimbatore',
    position: LatLng(11.0025, 76.9620),
    totalSlots: 60,
    availableSlots: 45,
    pricePerHour: 30,
    city: 'Coimbatore',
  ),
  ParkingStation(
    id: 'CB-D',
    name: 'Station CB-D — Peelamedu',
    address: 'Avanashi Rd, Peelamedu, Coimbatore',
    position: LatLng(11.0290, 77.0340),
    totalSlots: 100,
    availableSlots: 72,
    pricePerHour: 50,
    city: 'Coimbatore',
  ),
  ParkingStation(
    id: 'CB-E',
    name: 'Station CB-E — Saibaba Colony',
    address: 'Bharathi Park Rd, Saibaba Colony, Coimbatore',
    position: LatLng(11.0342, 76.9610),
    totalSlots: 40,
    availableSlots: 6,
    pricePerHour: 40,
    city: 'Coimbatore',
  ),
  ParkingStation(
    id: 'CB-F',
    name: 'Station CB-F — Tidel Park',
    address: 'Tidel Park, Avinashi Road, Coimbatore',
    position: LatLng(11.0480, 77.0200),
    totalSlots: 120,
    availableSlots: 90,
    pricePerHour: 60,
    city: 'Coimbatore',
  ),
];

// ── MapPage ──────────────────────────────────────────────────────────────────
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final TextEditingController _startController = TextEditingController();
  final MapController _mapController = MapController();

  List<LatLng> _routePoints = [];
  bool _isLoading = false;
  bool _isLocating = false;
  ParkingStation? _selectedStation;
  bool _routeVisible = false;
  LatLng? _userLocation;

  // Default center — Chennai
  static const LatLng _defaultCenter = LatLng(13.0827, 80.2707);
  static const double _defaultZoom = 12.0;

  @override
  void initState() {
    super.initState();
    _detectUserLocation();
  }

  // ── Get current location ─────────────────────────────────────────────────
  Future<void> _detectUserLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _startController.text = 'Chennai, Tamil Nadu';
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _startController.text = 'Chennai, Tamil Nadu';
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final loc = LatLng(pos.latitude, pos.longitude);
      setState(() => _userLocation = loc);

      // Reverse geocode to fill start field
      final address = await _reverseGeocode(pos.latitude, pos.longitude);
      _startController.text = address;

      // Move map to user location
      _mapController.move(loc, _defaultZoom);
    } catch (_) {
      _startController.text = 'Chennai, Tamil Nadu';
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<String> _reverseGeocode(double lat, double lon) async {
    try {
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json');
      final res = await http.get(uri,
          headers: {'User-Agent': 'com.example.smart_parking'});
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>? ?? {};
        // Build a short human-readable address
        final parts = <String>[
          if (addr['neighbourhood'] != null) addr['neighbourhood'] as String,
          if (addr['suburb'] != null) addr['suburb'] as String,
          if (addr['city'] != null) addr['city'] as String,
        ];
        return parts.isNotEmpty ? parts.join(', ') : (data['display_name'] ?? 'Your Location');
      }
    } catch (_) {}
    return 'Your Location';
  }

  // ── Build station markers ────────────────────────────────────────────────
  List<Marker> _buildStationMarkers() {
    return kParkingStations.map((station) {
      final isSelected = _selectedStation?.id == station.id;
      return Marker(
        point: station.position,
        width: isSelected ? 110 : 88,
        height: isSelected ? 84 : 68,
        child: GestureDetector(
          onTap: () => _onStationTap(station),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.amber
                      : station.statusColor.withOpacity(0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.amber : station.statusColor,
                    width: isSelected ? 2.5 : 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: Colors.amber.withOpacity(0.6),
                              blurRadius: 12,
                              spreadRadius: 2)
                        ]
                      : [],
                ),
                child: Icon(
                  Icons.local_parking_rounded,
                  color: isSelected ? Colors.black : station.statusColor,
                  size: isSelected ? 26 : 22,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  station.id,
                  style: TextStyle(
                    color: isSelected ? Colors.amber : Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  // ── User location marker ─────────────────────────────────────────────────
  List<Marker> _buildUserMarker() {
    if (_userLocation == null) return [];
    return [
      Marker(
        point: _userLocation!,
        width: 52,
        height: 52,
        child: Stack(alignment: Alignment.center, children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withOpacity(0.15),
              border: Border.all(color: Colors.blue.withOpacity(0.4), width: 1),
            ),
          ),
          Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue,
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ]),
      ),
    ];
  }

  // ── Route end marker ─────────────────────────────────────────────────────
  List<Marker> _buildRouteMarkers() {
    if (!_routeVisible || _selectedStation == null) return [];
    return [
      Marker(
        point: _selectedStation!.position,
        width: 60,
        height: 60,
        child: const Icon(Icons.flag_rounded, color: Colors.amber, size: 36),
      ),
    ];
  }

  void _onStationTap(ParkingStation station) {
    setState(() {
      _selectedStation = station;
      _routePoints = [];
      _routeVisible = false;
    });
    _mapController.move(station.position, 14);
    _showStationSheet(station);
  }

  void _showStationSheet(ParkingStation station) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _StationSheet(
        station: station,
        onNavigate: () {
          Navigator.pop(context);
          _navigateToStation(station);
        },
        onBook: station.isFull
            ? null
            : () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/booking');
              },
      ),
    );
  }

  Future<void> _navigateToStation(ParkingStation station) async {
    final startText = _startController.text.trim();
    if (startText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Start location not available'),
          backgroundColor: Colors.redAccent));
      return;
    }
    setState(() => _isLoading = true);
    try {
      LatLng start;
      if (_userLocation != null &&
          (startText == 'Your Location' ||
              startText.isEmpty ||
              startText == 'Chennai, Tamil Nadu')) {
        start = _userLocation!;
      } else {
        start = await _geocode(startText);
      }
      await _fetchRoute(start, station.position);
      setState(() {
        _routeVisible = true;
        _userLocation ??= start;
      });
      // Fit map to show full route
      _mapController.move(start, 12);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<LatLng> _geocode(String query) async {
    final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1');
    final res = await http.get(uri,
        headers: {'User-Agent': 'com.example.smart_parking'});
    if (res.statusCode == 200) {
      final data = json.decode(res.body) as List;
      if (data.isNotEmpty) {
        return LatLng(
            double.parse(data[0]['lat']), double.parse(data[0]['lon']));
      }
    }
    throw Exception('Location not found: $query');
  }

  Future<void> _fetchRoute(LatLng start, LatLng end) async {
    final uri = Uri.parse(
        'http://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson');
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final coords =
          data['routes']?.first['geometry']?['coordinates'] as List?;
      if (coords != null) {
        setState(() {
          _routePoints = coords
              .map((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
              .toList();
        });
      }
    }
  }

  Widget _zoomBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.82),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFB00000), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFFB00000),
        foregroundColor: Colors.white,
        title: const Text('Parking Stations',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'All Stations',
            onPressed: _showAllStationsSheet,
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Map ────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: _defaultZoom,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all,
                scrollWheelVelocity: 0.005,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.smart_parking',
              ),
              PolylineLayer(
                polylines: [
                  if (_routePoints.isNotEmpty)
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5.0,
                      color: const Color(0xFFFF4444),
                      borderStrokeWidth: 2.0,
                      borderColor: const Color(0xFF7A0000),
                    ),
                ],
              ),
              MarkerLayer(
                markers: [
                  ..._buildStationMarkers(),
                  ..._buildUserMarker(),
                  ..._buildRouteMarkers(),
                ],
              ),
            ],
          ),

          // ── Start location bar ─────────────────────────────────────
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.88),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFFB00000).withOpacity(0.6),
                    width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 4))
                ],
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                const Icon(Icons.trip_origin, color: Colors.greenAccent,
                    size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: _isLocating
                      ? const Text('Detecting your location...',
                          style: TextStyle(color: Colors.white54, fontSize: 14))
                      : TextField(
                          controller: _startController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Your start location...',
                            hintStyle: TextStyle(color: Colors.white38),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                ),
                if (_isLoading || _isLocating)
                  const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.redAccent, strokeWidth: 2))
                else
                  GestureDetector(
                    onTap: _detectUserLocation,
                    child: const Icon(Icons.my_location,
                        color: Colors.redAccent, size: 22),
                  ),
              ]),
            ),
          ),

          // ── Zoom buttons ───────────────────────────────────────────
          Positioned(
            right: 14,
            top: 90,
            child: Column(children: [
              _zoomBtn(Icons.add, () {
                _mapController.move(_mapController.camera.center,
                    _mapController.camera.zoom + 1);
              }),
              const SizedBox(height: 6),
              _zoomBtn(Icons.remove, () {
                _mapController.move(_mapController.camera.center,
                    _mapController.camera.zoom - 1);
              }),
              const SizedBox(height: 14),
              _zoomBtn(Icons.my_location, () {
                if (_userLocation != null) {
                  _mapController.move(_userLocation!, 14);
                } else {
                  _mapController.move(_defaultCenter, _defaultZoom);
                }
              }),
            ]),
          ),

          // ── Hint / Route banner ────────────────────────────────────
          if (_selectedStation == null && !_isLocating)
            Positioned(
              bottom: 90,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('🅿️  Tap a station marker to navigate',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 13)),
                ),
              ),
            ),

          if (_routeVisible && _selectedStation != null)
            Positioned(
              bottom: 90,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFFB00000).withOpacity(0.5)),
                ),
                child: Row(children: [
                  const Icon(Icons.directions_car, color: Colors.redAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Navigating to ${_selectedStation!.name}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (!_selectedStation!.isFull)
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/booking'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      child: const Text('Book Slot'),
                    ),
                ]),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF2C2C2C),
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) Navigator.pushNamed(context, '/home');
          if (index == 2) Navigator.pushNamed(context, '/profile');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_parking), label: 'Book'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Profile'),
        ],
      ),
    );
  }

  // ── All Stations Sheet ───────────────────────────────────────────────────
  void _showAllStationsSheet() {
    final cities = kParkingStations.map((s) => s.city).toSet().toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A0000),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 14),
            const Text('All Parking Stations',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final city in cities) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(children: [
                        const Icon(Icons.location_city,
                            color: Colors.redAccent, size: 16),
                        const SizedBox(width: 8),
                        Text(city.toUpperCase(),
                            style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2)),
                        const SizedBox(width: 8),
                        const Expanded(child: Divider(color: Colors.white12)),
                      ]),
                    ),
                    for (final s in kParkingStations.where(
                        (st) => st.city == city))
                      ListTile(
                        onTap: () {
                          Navigator.pop(context);
                          _onStationTap(s);
                        },
                        leading: CircleAvatar(
                          backgroundColor: s.statusColor.withOpacity(0.18),
                          radius: 20,
                          child: Text(s.id.split('-').last,
                              style: TextStyle(
                                  color: s.statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ),
                        title: Text(s.name,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13)),
                        subtitle: Text(
                          '${s.availableSlots}/${s.totalSlots} slots  •  ₹${s.pricePerHour.toInt()}/hr',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: s.statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(s.statusLabel,
                              style: TextStyle(
                                  color: s.statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Station Info Bottom Sheet ────────────────────────────────────────────────
class _StationSheet extends StatelessWidget {
  final ParkingStation station;
  final VoidCallback onNavigate;
  final VoidCallback? onBook;

  const _StationSheet({
    required this.station,
    required this.onNavigate,
    this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3A0000), Colors.black],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
              color: Colors.white24, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 16),

        // Header
        Row(children: [
          CircleAvatar(
            backgroundColor: station.statusColor.withOpacity(0.2),
            radius: 26,
            child: Text(station.id.split('-').last,
                style: TextStyle(
                    color: station.statusColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(station.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.location_city,
                    color: Colors.white38, size: 12),
                const SizedBox(width: 4),
                Text(station.city,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
              ]),
              const SizedBox(height: 2),
              Text(station.address,
                  style:
                      const TextStyle(color: Colors.white54, fontSize: 11)),
            ]),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: station.statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: station.statusColor.withOpacity(0.5), width: 1),
            ),
            child: Text(station.statusLabel,
                style: TextStyle(
                    color: station.statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
        ]),
        const SizedBox(height: 20),

        // Stats
        Row(children: [
          _stat('Available', '${station.availableSlots}',
              Icons.local_parking, station.statusColor),
          const SizedBox(width: 12),
          _stat('Total', '${station.totalSlots}', Icons.grid_view,
              Colors.white70),
          const SizedBox(width: 12),
          _stat('Rate', '₹${station.pricePerHour.toInt()}/hr',
              Icons.currency_rupee, Colors.amber),
        ]),

        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: station.occupancyPct,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation(station.statusColor),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 4),
        Row(children: const [
          Text('Empty', style: TextStyle(color: Colors.white38, fontSize: 10)),
          Spacer(),
          Text('Full', style: TextStyle(color: Colors.white38, fontSize: 10)),
        ]),

        const SizedBox(height: 20),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onNavigate,
              icon: const Icon(Icons.directions, color: Colors.white70),
              label: const Text('Navigate Here',
                  style: TextStyle(color: Colors.white70)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onBook,
              icon: Icon(
                  station.isFull ? Icons.block : Icons.check_circle_outline),
              label: Text(station.isFull ? 'No Slots' : 'Book Slot'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    station.isFull ? Colors.grey.shade800 : Colors.amber,
                foregroundColor:
                    station.isFull ? Colors.white38 : Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _stat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 5),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 2),
          Text(label,
              style:
                  const TextStyle(color: Colors.white38, fontSize: 10)),
        ]),
      ),
    );
  }
}
