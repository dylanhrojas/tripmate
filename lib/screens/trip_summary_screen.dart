import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/trip_tracking.dart';

class TripSummaryScreen extends StatefulWidget {
  final TripTracking tracking;

  const TripSummaryScreen({super.key, required this.tracking});

  @override
  State<TripSummaryScreen> createState() => _TripSummaryScreenState();
}

class _TripSummaryScreenState extends State<TripSummaryScreen> {
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initializeMapData();
  }

  void _initializeMapData() {
    if (widget.tracking.path.isEmpty) return;

    // Create polyline from path
    final pathCoordinates = widget.tracking.path
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();

    final polyline = Polyline(
      polylineId: const PolylineId('trip_path'),
      points: pathCoordinates,
      color: Colors.blue,
      width: 4,
      patterns: [PatternItem.dot, PatternItem.gap(10)],
    );

    // Create markers for start and end
    final startPoint = widget.tracking.path.first;
    final endPoint = widget.tracking.path.last;

    final startMarker = Marker(
      markerId: const MarkerId('start'),
      position: LatLng(startPoint.latitude, startPoint.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(
        title: 'Start',
        snippet: startPoint.timestamp.toString().substring(0, 16),
      ),
    );

    final endMarker = Marker(
      markerId: const MarkerId('end'),
      position: LatLng(endPoint.latitude, endPoint.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(
        title: 'End',
        snippet: endPoint.timestamp.toString().substring(0, 16),
      ),
    );

    setState(() {
      _polylines = {polyline};
      _markers = {startMarker, endMarker};
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Zoom to fit all points
    if (widget.tracking.path.isNotEmpty) {
      _fitMapToPath();
    }
  }

  void _fitMapToPath() {
    if (widget.tracking.path.isEmpty) return;

    double minLat = widget.tracking.path.first.latitude;
    double maxLat = widget.tracking.path.first.latitude;
    double minLng = widget.tracking.path.first.longitude;
    double maxLng = widget.tracking.path.first.longitude;

    for (final point in widget.tracking.path) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  @override
  Widget build(BuildContext context) {
    final startPoint = widget.tracking.path.isNotEmpty
        ? widget.tracking.path.first
        : null;
    final endPoint = widget.tracking.path.isNotEmpty
        ? widget.tracking.path.last
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Summary'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Trip Info Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.tracking.tripName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        widget.tracking.startTime.toString().substring(0, 16),
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Stats Cards
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Distance',
                          '${widget.tracking.distanceInKm} km',
                          Icons.straighten,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Duration',
                          widget.tracking.formattedDuration,
                          Icons.timer,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Points',
                          '${widget.tracking.path.length}',
                          Icons.location_on,
                          Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Status',
                          widget.tracking.isActive ? 'Active' : 'Completed',
                          widget.tracking.isActive ? Icons.play_circle : Icons.check_circle,
                          widget.tracking.isActive ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Location Details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Location Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (startPoint != null)
                    _buildLocationCard(
                      'Starting Location',
                      startPoint.latitude,
                      startPoint.longitude,
                      startPoint.timestamp,
                      Colors.green,
                      Icons.play_arrow,
                    ),
                  const SizedBox(height: 12),
                  if (endPoint != null)
                    _buildLocationCard(
                      'Ending Location',
                      endPoint.latitude,
                      endPoint.longitude,
                      endPoint.timestamp,
                      Colors.red,
                      Icons.stop,
                    ),
                ],
              ),
            ),

            // Map
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Travel Path',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: widget.tracking.path.isEmpty
                        ? const Center(
                            child: Text('No path data available'),
                          )
                        : GoogleMap(
                            onMapCreated: _onMapCreated,
                            initialCameraPosition: CameraPosition(
                              target: LatLng(
                                widget.tracking.path.first.latitude,
                                widget.tracking.path.first.longitude,
                              ),
                              zoom: 15,
                            ),
                            polylines: _polylines,
                            markers: _markers,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: true,
                            mapToolbarEnabled: false,
                          ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem(Colors.green, 'Start'),
                      const SizedBox(width: 16),
                      _buildLegendItem(Colors.blue, 'Path'),
                      const SizedBox(width: 16),
                      _buildLegendItem(Colors.red, 'End'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(
    String title,
    double lat,
    double lng,
    DateTime timestamp,
    Color color,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lat: ${lat.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Lng: ${lng.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    timestamp.toString().substring(0, 16),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: label == 'Path' ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: label == 'Path' ? BorderRadius.circular(2) : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
