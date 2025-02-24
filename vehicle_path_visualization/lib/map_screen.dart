// Import necessary Flutter and external libraries
import 'package:flutter/material.dart'; // Provides core UI widgets
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Allows Google Maps integration
import 'data_parser.dart'; // Custom module to parse vehicle path and store data
import 'dart:math'; // Provides mathematical functions like max() and trigonometric calculations

/// Displays the vehicle path and highlights key data.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController; // Controller for Google Maps
  Set<Marker> _markers = {}; // Holds store location markers
  Set<Polyline> _polylines = {}; // Holds the vehicle travel path
  bool _isLoading = true; // Indicates if data is being loaded
  double _totalDistance = 0.0; // Stores total distance traveled
  double _maxSpeed = 0.0; // Stores the highest speed recorded
  Store? _closestStore; // Stores the nearest store to the vehicle path
  String? _firstTimestampNearStore; // First timestamp when near a store

  @override
  void initState() {
    super.initState();
    _loadData(); // Load vehicle path and store data when the screen initializes
  }

  /// Loads vehicle path and store data asynchronously.
  Future<void> _loadData() async {
    try {
      // Parse vehicle path data from JSON file
      final vehiclePath = await parseVehiclePath();
      // Parse store data from CSV file
      final stores = await parseStores();

      // Compute total distance traveled and highest speed reached
      _calculatePathMetrics(vehiclePath);

      // Find the closest store to the vehicle path
      _findClosestStore(vehiclePath, stores);

      setState(() {
        // Create markers for stores on the map
        _markers = stores
            .map((store) => Marker(
                  markerId: MarkerId(store.name), // Unique marker ID
                  position:
                      LatLng(store.latitude, store.longitude), // Store location
                  infoWindow: InfoWindow(title: store.name), // Store name popup
                  icon: store == _closestStore
                      ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor
                          .hueGreen) // Highlight closest store in green
                      : BitmapDescriptor
                          .defaultMarker, // Default marker for others
                ))
            .toSet();

        // Draw polyline for vehicle travel path
        _polylines = {
          Polyline(
            polylineId: const PolylineId('vehicle_path'), // Unique ID
            color: const Color.fromARGB(253, 240, 104, 20) // Path color

            ,
            width: 4, // Line thickness
            points: vehiclePath
                .map((point) => LatLng(point.latitude,
                    point.longitude)) // Convert points to LatLng format
                .toList(),
          ),
        };

        _isLoading = false; // Mark data as loaded
      });
    } catch (e) {
      print("Error loading data: $e"); // Handle any errors in loading data
    }
  }

  /// Calculates total distance traveled and max speed reached.
  void _calculatePathMetrics(List<VehiclePoint> path) {
    double totalDistance = 0.0;
    double maxSpeed = 0.0;

    // Loop through vehicle path data
    for (int i = 1; i < path.length; i++) {
      totalDistance += _calculateDistance(path[i - 1].latitude,
          path[i - 1].longitude, path[i].latitude, path[i].longitude);
      maxSpeed = max(maxSpeed, path[i].speed); // Get maximum speed
    }

    _totalDistance = totalDistance;
    _maxSpeed = maxSpeed;
  }

  /// Finds the closest store to the vehicle path.
  void _findClosestStore(List<VehiclePoint> path, List<Store> stores) {
    double minDistance = double.infinity; // Initialize with a large value
    Store? closest;
    String? firstTimestamp;

    // Loop through each store
    for (var store in stores) {
      // Loop through each vehicle path point
      for (var point in path) {
        // Calculate distance between store and vehicle location
        double distance = _calculateDistance(
            point.latitude, point.longitude, store.latitude, store.longitude);

        if (distance < minDistance) {
          minDistance = distance; // Update shortest distance
          closest = store; // Update closest store
          firstTimestamp =
              point.timestamp; // Record first timestamp near the store
        }
      }
    }

    _closestStore = closest;
    _firstTimestampNearStore = firstTimestamp;
  }

  /// Calculates distance between two GPS points using the Haversine formula.
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371e3; // Earth's radius in meters
    double phi1 = lat1 * pi / 180; // Convert latitude to radians
    double phi2 = lat2 * pi / 180;
    double deltaLat = (lat2 - lat1) * pi / 180; // Difference in latitude
    double deltaLon = (lon2 - lon1) * pi / 180; // Difference in longitude

    // Haversine formula
    double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLon / 2) * sin(deltaLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c; // Return distance in meters
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle Path Map')), // App bar title
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator()) // Show loading spinner
          : Column(
              children: [
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(-33.92, 18.85), // Default map center
                      zoom: 10, // Default zoom level
                    ),
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller; // Store map controller
                    },
                    markers: _markers, // Display store markers
                    polylines: _polylines, // Display vehicle path
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0), // Add some padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          "Total Distance: ${(_totalDistance / 1000).toStringAsFixed(2)} km"), // Display total distance
                      Text(
                          "Highest Speed: ${_maxSpeed.toStringAsFixed(2)} km/h"), // Display max speed
                      if (_closestStore != null)
                        Text(
                            "Closest Store: ${_closestStore!.name}"), // Display closest store
                      if (_firstTimestampNearStore != null)
                        Text(
                            "First Near Store: $_firstTimestampNearStore"), // Display first timestamp
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
