import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Model class for a vehicle path point.
class VehiclePoint {
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final int heading;
  final double speed;

  VehiclePoint({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.heading,
    required this.speed,
  });

  factory VehiclePoint.fromJson(Map<String, dynamic> json) {
    // Assuming the provided timestamp is in seconds.
    return VehiclePoint(
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timeStamp'] * 1000),
      latitude: json['latitude'],
      longitude: json['longitude'],
      heading: json['heading'],
      speed: (json['speed'] as num).toDouble(),
    );
  }
}

/// Model class for a store.
class Store {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  Store({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  factory Store.fromCsv(List<String> fields) {
    // Assuming CSV fields are: id, name, latitude, longitude
    return Store(
      id: fields[0],
      name: fields[1],
      latitude: double.parse(fields[2]),
      longitude: double.parse(fields[3]),
    );
  }
}

/// Main application widget.
void main() {
  runApp(const MaterialApp(
    home: MapScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  List<VehiclePoint> vehiclePoints = [];
  List<Store> stores = [];

  // Calculated metrics.
  double totalDistance = 0.0;
  double highestSpeed = 0.0;
  Store? closestStore;
  DateTime? closestTimestamp; // When vehicle first came near the closest store.
  double minStoreDistance = double.infinity;

  static const LatLng _initialPosition = LatLng(-34.0128416, 18.690535);

  @override
  void initState() {
    super.initState();
    loadData();
  }

  /// Loads the JSON and CSV data from assets.
  Future<void> loadData() async {
    await Future.wait([loadVehiclePoints(), loadStores()]);
    computeMetrics();
    addPathPolyline();
    addVehicleMarkers();
    addStoreMarkers();
    setState(() {});
  }

  /// Loads vehicle path points from the JSON file.
  Future<void> loadVehiclePoints() async {
    final String jsonString =
        await rootBundle.loadString('assets/PathTravelled.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    vehiclePoints =
        jsonList.map((json) => VehiclePoint.fromJson(json)).toList();
  }

  /// Loads store locations from the CSV file.
  Future<void> loadStores() async {
    final String csvString =
        await rootBundle.loadString('assets/stores.Copy.csv');
    // Split by lines and remove empty lines.
    final List<String> lines =
        csvString.split('\n').where((line) => line.trim().isNotEmpty).toList();
    // Assuming first line is a header.
    for (int i = 1; i < lines.length; i++) {
      // A simple CSV parser assuming no commas inside quoted strings.
      final List<String> fields = lines[i].split(',');
      if (fields.length >= 4) {
        stores.add(Store.fromCsv(fields));
      }
    }
  }

  /// Computes total distance, highest speed, and finds the store closest to the vehicle path.
  void computeMetrics() {
    if (vehiclePoints.isEmpty) return;
    totalDistance = 0.0;
    highestSpeed = 0.0;
    // Iterate over vehicle points to calculate total distance and highest speed.
    for (int i = 1; i < vehiclePoints.length; i++) {
      totalDistance += calculateDistance(
        vehiclePoints[i - 1].latitude,
        vehiclePoints[i - 1].longitude,
        vehiclePoints[i].latitude,
        vehiclePoints[i].longitude,
      );
      highestSpeed = max(highestSpeed, vehiclePoints[i].speed);
    }

    // Find the store that is closest to any vehicle point.
    for (final store in stores) {
      for (final point in vehiclePoints) {
        final double distance = calculateDistance(
          store.latitude,
          store.longitude,
          point.latitude,
          point.longitude,
        );
        if (distance < minStoreDistance) {
          minStoreDistance = distance;
          closestStore = store;
          closestTimestamp = point.timestamp;
        }
      }
    }
  }

  /// Adds the vehicle path as a polyline.
  void addPathPolyline() {
    final List<LatLng> polylineCoordinates = vehiclePoints
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();

    _polylines.add(
      Polyline(
        polylineId: const PolylineId('vehicle_path'),
        points: polylineCoordinates,
        color: Colors.red,
        width: 3,
        onTap: () {
          // Optionally handle tap events on the entire path.
        },
      ),
    );
  }

  /// Adds markers for each vehicle point.
  void addVehicleMarkers() {
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
                'Time: ${point.timestamp}\nSpeed: ${point.speed} km/h\nHeading: ${point.heading}°',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
  }

  /// Adds markers for each store. The closest store is highlighted with a different color.
  void addStoreMarkers() {
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
                ? 'Closest Store\nDistance: ${minStoreDistance.toStringAsFixed(2)} km\nClosest at: ${closestTimestamp.toString()}'
                : null,
          ),
          icon: isClosest
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)
              : BitmapDescriptor.defaultMarker,
        ),
      );
    }
  }

  /// Haversine formula to calculate distance (in kilometers) between two latitude/longitude points.
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
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

  double _deg2rad(double deg) => deg * (pi / 180);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Path & Stores Map'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 13,
            ),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
          ),
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
                      'Closest Store: ${closestStore!.name} at ${closestTimestamp.toString()}',
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
