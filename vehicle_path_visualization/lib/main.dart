import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart'; // Used to format dates into a human-readable string

/// Model class representing a point on the vehicle's path.
class VehiclePoint {
  final DateTime timestamp; // The time when the vehicle was at this point
  final double latitude; // Latitude coordinate
  final double longitude; // Longitude coordinate
  final int heading; // Direction the vehicle was facing (in degrees)
  final double speed; // Speed of the vehicle at this point (km/h)

  VehiclePoint({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.heading,
    required this.speed,
  });

  /// Factory method to create a VehiclePoint instance from JSON.
  /// The JSON's "timeStamp" is expected to be in seconds.
  factory VehiclePoint.fromJson(Map<String, dynamic> json) {
    return VehiclePoint(
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timeStamp'] * 1000),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      heading: json['heading'] as int,
      speed: (json['speed'] as num).toDouble(),
    );
  }
}

/// Model class representing a store.
class Store {
  final String id; // Unique id (using store name)
  final String name; // Store name
  final double latitude; // Store latitude coordinate
  final double longitude; // Store longitude coordinate

  Store({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  /// Factory method to create a Store instance from a row in a CSV file.
  /// CSV format: [store name, latitude, longitude]
  factory Store.fromCsv(List<dynamic> fields) {
    final String storeName = fields[0].toString().trim();
    return Store(
      id: storeName, // Use store name as the unique identifier
      name: storeName,
      latitude: double.tryParse(fields[1].toString().trim()) ?? 0.0,
      longitude: double.tryParse(fields[2].toString().trim()) ?? 0.0,
    );
  }
}

/// Asynchronously parses vehicle path data from a JSON asset.
/// Reads the file from assets/PathTravelled.json and converts it into a list of VehiclePoint objects.
Future<List<VehiclePoint>> parseVehiclePath() async {
  try {
    final String response =
        await rootBundle.loadString('assets/PathTravelled.json');
    if (response.isEmpty) throw Exception("Empty JSON file");
    final List<dynamic> data = json.decode(response);
    return data.map((point) => VehiclePoint.fromJson(point)).toList();
  } catch (e) {
    print("Error loading JSON: $e");
    return [];
  }
}

/// Asynchronously parses store data from a CSV asset.
/// Reads the file from assets/stores.Copy.csv and converts each row (after the header) into a Store object.
Future<List<Store>> parseStores() async {
  try {
    final String response =
        await rootBundle.loadString('assets/stores.Copy.csv');
    if (response.isEmpty) throw Exception("Empty CSV file");
    List<List<dynamic>> csvData = const CsvToListConverter().convert(response);
    // Skip the header row and only convert rows with at least 3 columns.
    return csvData
        .skip(1)
        .where((row) => row.length >= 3)
        .map((row) => Store.fromCsv(row))
        .toList();
  } catch (e) {
    print("Error loading CSV: $e");
    return [];
  }
}

/// Main application widget.
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vehicle Path and Stores Map',
      debugShowCheckedModeBanner: false,
      home: const MapScreen(),
    );
  }
}

void main() {
  runApp(const MyApp());
}

/// MapScreen displays the vehicle path and store markers on a Google Map.
class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

/// State class for MapScreen.
class _MapScreenState extends State<MapScreen> {
  late GoogleMapController
      _mapController; // Controller for interacting with the Google Map.
  final Set<Marker> _markers = {}; // Set of markers to display on the map.
  final Set<Polyline> _polylines =
      {}; // Set of polylines to represent the vehicle path.

  List<VehiclePoint> vehiclePoints =
      []; // List to hold the parsed vehicle path points.
  List<Store> stores = []; // List to hold the parsed store data.

  // Metrics to be displayed.
  double totalDistance = 0.0; // Total distance traveled by the vehicle.
  double highestSpeed = 0.0; // Highest speed recorded.
  Store? closestStore; // The store closest to any point on the vehicle's path.
  DateTime?
      closestTimestamp; // Timestamp when the vehicle was closest to the closest store.
  double minStoreDistance =
      double.infinity; // Minimum distance between a vehicle point and a store.

  bool _isLoading = true; // Flag to indicate if data is still loading.
  static const LatLng _initialPosition =
      LatLng(-34.0128416, 18.690535); // Default starting position.

  final DateFormat _dateFormatter =
      DateFormat('yyyy-MM-dd HH:mm:ss'); // Formatter for date/time display.

  @override
  void initState() {
    super.initState();
    _loadData(); // Load vehicle and store data as soon as the widget initializes.
  }

  /// Loads vehicle path and store data, computes metrics, and sets up markers and polyline.
  Future<void> _loadData() async {
    vehiclePoints = await parseVehiclePath();
    stores = await parseStores();

    // Compute total distance and highest speed from the vehicle path.
    _calculatePathMetrics(vehiclePoints);
    // Determine the closest store to any point on the vehicle path.
    _findClosestStore(vehiclePoints, stores);

    // Print debug information to verify closest store computation.
    if (closestStore != null) {
      print(
          'Closest store is ${closestStore!.name} with distance ${minStoreDistance.toStringAsFixed(2)} km');
    } else {
      print('No closest store found.');
    }

    // Add markers for stores and vehicle points, and add the polyline for the vehicle path.
    _addStoreMarkers();
    _addVehicleMarkers();
    _addPathPolyline();

    // Data is now loaded so update the state to hide the loading indicator.
    setState(() {
      _isLoading = false;
    });

    // Recenter the camera after a short delay to ensure all markers are visible.
    Future.delayed(const Duration(milliseconds: 500), () {
      _recenterCamera();
    });
  }

  /// Calculates total distance traveled and highest speed using the Haversine formula.
  void _calculatePathMetrics(List<VehiclePoint> path) {
    if (path.isEmpty) return;
    totalDistance = 0.0;
    highestSpeed = 0.0;
    // Iterate through consecutive points to compute distance and compare speeds.
    for (int i = 1; i < path.length; i++) {
      totalDistance += _calculateDistance(
        path[i - 1].latitude,
        path[i - 1].longitude,
        path[i].latitude,
        path[i].longitude,
      );
      highestSpeed = max(highestSpeed, path[i].speed);
    }
  }

  /// Finds the closest store to any point on the vehicle path.
  /// Also captures the timestamp when the vehicle was closest to that store.
  void _findClosestStore(List<VehiclePoint> path, List<Store> storesList) {
    double minDistanceLocal = double.infinity;
    Store? closest;
    DateTime? firstTime;

    // Iterate over each store and each vehicle point.
    for (var store in storesList) {
      for (var point in path) {
        double distance = _calculateDistance(
          point.latitude,
          point.longitude,
          store.latitude,
          store.longitude,
        );
        if (distance < minDistanceLocal) {
          minDistanceLocal = distance;
          closest = store;
          firstTime = point.timestamp;
        }
      }
    }
    minStoreDistance = minDistanceLocal;
    closestStore = closest;
    closestTimestamp = firstTime;
  }

  /// Adds markers for each store on the map.
  /// The store closest to the vehicle path is highlighted in green.
  void _addStoreMarkers() {
    for (final store in stores) {
      final markerId = MarkerId('store_${store.id}');
      final isClosest = (closestStore != null && store.id == closestStore!.id);
      _markers.add(
        Marker(
          markerId: markerId,
          position: LatLng(store.latitude, store.longitude),
          infoWindow: InfoWindow(
            title: store.name,
            snippet: isClosest
                ? 'Closest Store\nDistance: ${minStoreDistance.toStringAsFixed(2)} km\nTime: ${closestTimestamp != null ? _dateFormatter.format(closestTimestamp!) : "N/A"}'
                : null,
          ),
          // Use green color for the closest store, default marker for others.
          icon: isClosest
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
              : BitmapDescriptor.defaultMarker,
        ),
      );
    }
  }

  /// Adds markers for each vehicle point.
  /// Tapping on a marker displays detailed information (formatted timestamp, speed, and heading).
  void _addVehicleMarkers() {
    for (final point in vehiclePoints) {
      final markerId =
          MarkerId('vehicle_${point.timestamp.millisecondsSinceEpoch}');
      _markers.add(
        Marker(
          markerId: markerId,
          position: LatLng(point.latitude, point.longitude),
          infoWindow: InfoWindow(
            title: 'Vehicle Point',
            snippet:
                'Time: ${_dateFormatter.format(point.timestamp)}\nSpeed: ${point.speed.toStringAsFixed(1)} km/h\nHeading: ${point.heading}°',
          ),
          // Use red markers for vehicle points.
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
  }

  /// Adds a polyline representing the vehicle's traveled path on the map.
  /// Note: Google Maps Flutter does not support tap events on polylines reliably.
  void _addPathPolyline() {
    final List<LatLng> polylineCoordinates = vehiclePoints
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('vehicle_path'),
        points: polylineCoordinates,
        color: Colors.red,
        width: 3,
      ),
    );
  }

  /// Recenters the map camera to include all markers.
  Future<void> _recenterCamera() async {
    if (_markers.isEmpty) return;
    double minLat = 90, minLng = 180, maxLat = -90, maxLng = -180;
    // Find the bounds that include all marker positions.
    for (var marker in _markers) {
      final LatLng pos = marker.position;
      if (pos.latitude < minLat) minLat = pos.latitude;
      if (pos.longitude < minLng) minLng = pos.longitude;
      if (pos.latitude > maxLat) maxLat = pos.latitude;
      if (pos.longitude > maxLng) maxLng = pos.longitude;
    }
    final LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  /// Uses the Haversine formula to calculate the distance between two points on Earth.
  /// Returns the distance in kilometers.
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371; // Earth's radius in kilometers.
    final double dLat = _deg2rad(lat2 - lat1);
    final double dLon = _deg2rad(lon2 - lon1);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  /// Converts degrees to radians.
  double _deg2rad(double deg) => deg * (pi / 180);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle Path and Stores Map')),
      body: _isLoading
          // Show a loading indicator while data is being loaded.
          ? const Center(child: CircularProgressIndicator())
          // Once data is loaded, display the map with markers, polylines, and key metrics.
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: _initialPosition,
                    zoom: 13,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  // Note: Hover events are not supported on mobile.
                  // On desktop or web, tapping a marker opens an info window.
                ),
                // A panel at the bottom of the screen displays key information.
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.white70,
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total Distance: ${totalDistance.toStringAsFixed(2)} km',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Highest Speed: ${highestSpeed.toStringAsFixed(2)} km/h',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (closestStore != null && closestTimestamp != null)
                          Text(
                            'Closest Store: ${closestStore!.name} at ${_dateFormatter.format(closestTimestamp!)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
