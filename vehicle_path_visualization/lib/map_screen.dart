import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'data_parser.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  double _totalDistance = 0.0;
  double _maxSpeed = 0.0;
  Store? _closestStore;
  String? _firstTimestampNearStore;

  List<VehiclePoint> vehiclePoints = [];
  List<Store> stores = [];
  // Formatter for displaying date and time.
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Loads vehicle and store data, calculates metrics, and sets up markers.
  Future<void> _loadData() async {
    // Parse vehicle and store data from JSON.
    vehiclePoints = await parseVehiclePath();
    stores = await parseStores();

    // Debug logs to ensure data is loaded.
    print('Loaded ${vehiclePoints.length} vehicle points.');
    print('Loaded ${stores.length} stores.');

    // Calculate the total distance traveled and highest speed.
    _calculatePathMetrics(vehiclePoints);
    // Determine the store closest to the vehicle path.
    _findClosestStore(vehiclePoints, stores);

    setState(() {
      // Create markers for stores.
      _markers = stores
          .map((store) => Marker(
                markerId: MarkerId(store.id),
                position: LatLng(store.latitude, store.longitude),
                infoWindow: InfoWindow(title: store.name),
                // Highlight the closest store with a green marker.
                icon: (store == _closestStore)
                    ? BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueGreen)
                    : BitmapDescriptor.defaultMarker,
              ))
          .toSet();

      // Create markers for each vehicle point with detailed metrics.
      _markers = _markers.union(vehiclePoints.map((point) {
        // Attempt to parse the timestamp. If parsing fails, use 0.
        final timestampInt = int.tryParse(point.timestamp) ?? 0;
        return Marker(
          markerId: MarkerId(
              'vehicle_${point.timestamp}_${point.latitude}_${point.longitude}'),
          position: LatLng(point.latitude, point.longitude),
          infoWindow: InfoWindow(
            title: 'Vehicle Metrics',
            snippet: '''
Time: ${timestampInt != 0 ? _dateFormatter.format(DateTime.fromMillisecondsSinceEpoch(timestampInt * 1000)) : 'N/A'}
Speed: ${point.speed.toStringAsFixed(1)} km/h
Heading: ${point.heading.toStringAsFixed(1)}°
''',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        );
      }).toSet());

      // Draw a polyline connecting the vehicle points.
      _polylines = {
        Polyline(
          polylineId: const PolylineId('vehicle_path'),
          color: Colors.orange.withOpacity(0.7),
          width: 4,
          points: vehiclePoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList(),
        ),
      };

      _isLoading = false;
    });

    // Once the data is loaded, recenter the camera.
    if (_mapController != null) _recenterCamera();
  }

  /// Calculates the total distance and highest speed from the vehicle path.
  void _calculatePathMetrics(List<VehiclePoint> path) {
    if (path.isEmpty) return;
    _totalDistance = 0.0;
    _maxSpeed = 0.0;
    for (int i = 1; i < path.length; i++) {
      _totalDistance += _calculateDistance(
        path[i - 1].latitude,
        path[i - 1].longitude,
        path[i].latitude,
        path[i].longitude,
      );
      _maxSpeed = max(_maxSpeed, path[i].speed);
    }
  }

  /// Finds the closest store to the vehicle path.
  /// Also records the timestamp when the vehicle first came close to that store.
  void _findClosestStore(List<VehiclePoint> path, List<Store> stores) {
    double minDistance = double.infinity;
    Store? closest;
    String? firstTimestamp;

    for (var store in stores) {
      for (var point in path) {
        double distance = _calculateDistance(
            point.latitude, point.longitude, store.latitude, store.longitude);
        if (distance < minDistance) {
          minDistance = distance;
          closest = store;
          firstTimestamp = point.timestamp;
        }
      }
    }
    _closestStore = closest;
    _firstTimestampNearStore = firstTimestamp;
    print('Closest store: ${_closestStore?.name}, at distance: $minDistance');
  }

  /// Calculates the distance between two coordinates using the haversine formula.
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371e3; // Earth's radius in meters
    double phi1 = lat1 * pi / 180;
    double phi2 = lat2 * pi / 180;
    double deltaLat = (lat2 - lat1) * pi / 180;
    double deltaLon = (lon2 - lon1) * pi / 180;

    double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLon / 2) * sin(deltaLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  /// Creates map bounds that encompass all markers and vehicle points.
  LatLngBounds _createBoundsFromAllPoints() {
    List<LatLng> allPoints = _markers.map((m) => m.position).toList()
      ..addAll(vehiclePoints.map((p) => LatLng(p.latitude, p.longitude)));

    double minLat = allPoints.first.latitude;
    double maxLat = allPoints.first.latitude;
    double minLng = allPoints.first.longitude;
    double maxLng = allPoints.first.longitude;

    for (LatLng point in allPoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  /// Recenters the map camera to include all markers and points.
  void _recenterCamera() {
    if (_mapController == null) return;
    final bounds = _createBoundsFromAllPoints();
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle Path Map')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // The Google Map widget.
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(-34.0, 18.7), // Default starting position.
                      zoom: 10,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _recenterCamera();
                    },
                    markers: _markers,
                    polylines: _polylines,
                  ),
                ),
                // Display key information.
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          "Total Distance: ${(_totalDistance / 1000).toStringAsFixed(2)} km"),
                      Text(
                          "Highest Speed: ${_maxSpeed.toStringAsFixed(2)} km/h"),
                      if (_closestStore != null)
                        Text("Closest Store: ${_closestStore!.name}"),
                      if (_firstTimestampNearStore != null)
                        Builder(
                          builder: (context) {
                            final timestamp =
                                int.tryParse(_firstTimestampNearStore!) ?? 0;
                            return Text(
                                "First Near Store: ${timestamp != 0 ? _dateFormatter.format(DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)) : 'Unknown'}");
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
