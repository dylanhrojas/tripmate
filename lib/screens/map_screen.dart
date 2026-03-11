import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LocationService _locationService = LocationService();
  final StorageService _storageService = StorageService();
  GoogleMapController? _mapController;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  Set<Marker> _markers = {};
  bool _isTracking = false;
  SavedLocation? _lastSavedLocation;
  static const MarkerId _currentLocationMarkerId = MarkerId('current_location');
  static const MarkerId _savedLocationMarkerId = MarkerId('saved_location');

  @override
  void initState() {
    super.initState();
    _loadLastSavedLocation();
    _initializeLocation();
    _checkAutoTracking();
  }

  Future<void> _checkAutoTracking() async {
    // Check if tracking is enabled in preferences
    final trackingEnabled = await _storageService.getTrackingEnabled();
    if (trackingEnabled && mounted) {
      // Wait a bit for location permission to be handled
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted && !_isTracking) {
        _startTracking();
      }
    }
  }

  Future<void> _initializeLocation() async {
    // Check permission
    bool hasPermission = await _locationService.handleLocationPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission required'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Get initial position
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _updateMarker(position);
        });

        // Move camera to current location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            15,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateMarker(Position position) {
    Set<Marker> newMarkers = {
      Marker(
        markerId: _currentLocationMarkerId,
        position: LatLng(position.latitude, position.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: 'Current Location',
          snippet: 'Lat: ${position.latitude.toStringAsFixed(6)}, '
              'Lng: ${position.longitude.toStringAsFixed(6)}',
        ),
      ),
    };

    // Add saved location marker if it exists
    if (_lastSavedLocation != null) {
      newMarkers.add(
        Marker(
          markerId: _savedLocationMarkerId,
          position: LatLng(
            _lastSavedLocation!.latitude,
            _lastSavedLocation!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Last Saved Location',
            snippet: 'Saved: ${_lastSavedLocation!.timestamp.toString().substring(0, 16)}',
          ),
        ),
      );
    }

    setState(() {
      _markers = newMarkers;
    });
  }

  void _startTracking() {
    if (_isTracking) return;

    setState(() {
      _isTracking = true;
    });

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        setState(() {
          _currentPosition = position;
          _updateMarker(position);
        });

        // Animate camera to follow user
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
      },
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tracking error: $error'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isTracking = false;
        });
      },
    );
  }

  void _stopTracking() {
    _positionStreamSubscription?.cancel();
    setState(() {
      _isTracking = false;
    });
  }

  Future<void> _saveCurrentLocation() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No location available to save'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _storageService.saveLastLocation(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );

      setState(() {
        _lastSavedLocation = SavedLocation(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          timestamp: DateTime.now(),
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location saved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadLastSavedLocation() async {
    final savedLocation = await _storageService.getLastLocation();
    if (savedLocation != null && mounted) {
      setState(() {
        _lastSavedLocation = savedLocation;
      });

      // Update markers to include saved location
      if (_currentPosition != null) {
        _updateMarker(_currentPosition!);
      } else {
        // If no current position yet, just add the saved location marker
        setState(() {
          _markers = {
            Marker(
              markerId: _savedLocationMarkerId,
              position: LatLng(
                savedLocation.latitude,
                savedLocation.longitude,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              infoWindow: InfoWindow(
                title: 'Last Saved Location',
                snippet: 'Saved: ${savedLocation.timestamp.toString().substring(0, 16)}',
              ),
            ),
          };
        });

        // Move camera to saved location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(savedLocation.latitude, savedLocation.longitude),
            15,
          ),
        );
      }

      // Show notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Last saved location loaded (${savedLocation.timestamp.toString().substring(0, 16)})',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(_isTracking ? Icons.stop : Icons.my_location),
            onPressed: _isTracking ? _stopTracking : _startTracking,
            tooltip: _isTracking ? 'Stop Tracking' : 'Start Tracking',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : const LatLng(0, 0),
              zoom: 15,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            compassEnabled: true,
            mapToolbarEnabled: false,
          ),
          if (_isTracking)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Tracking Active',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_currentPosition != null || _lastSavedLocation != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_currentPosition != null) ...[
                        const Text(
                          'Current Position',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          'Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          'Accuracy: ${_currentPosition!.accuracy.toStringAsFixed(2)}m',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _saveCurrentLocation,
                          icon: const Icon(Icons.save),
                          label: const Text('Save My Location'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                      if (_lastSavedLocation != null) ...[
                        if (_currentPosition != null)
                          const Divider(height: 24),
                        Row(
                          children: [
                            Icon(Icons.bookmark, color: Colors.green[700], size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Last Saved Location',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Lat: ${_lastSavedLocation!.latitude.toStringAsFixed(6)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          'Lng: ${_lastSavedLocation!.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          'Saved: ${_lastSavedLocation!.timestamp.toString().substring(0, 19)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
