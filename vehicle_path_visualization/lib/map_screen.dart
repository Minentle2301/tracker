// Import the Dart library for asynchronous programming.
import 'dart:async';
// Import the Dart math library for functions like sin, cos, and max.
import 'dart:math';
// Import Flutter's material design library for UI components.
import 'package:flutter/material.dart';
// Import the Google Maps Flutter package to display maps.
import 'package:google_maps_flutter/google_maps_flutter.dart';
// Import the internationalization package for date formatting.
import 'package:intl/intl.dart';
// Import the custom data parser for vehicle and store data.
import 'data_parser.dart';

/// The MapScreen widget displays the vehicle path, markers, and key metrics on a Google Map.
class MapScreen extends StatefulWidget {
  // Constructor for MapScreen.
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

/// The state class for MapScreen that manages the map, markers, and data loading.
class _MapScreenState extends State<MapScreen> {
  // Controller for interacting with the Google Map.
  GoogleMapController? _mapController;
  // Set of markers to be displayed on the map.
  Set<Marker> _markers = {};
  // Set of polylines (paths) to be drawn on the map.
  Set<Polyline> _polylines = {};
  // Flag indicating whether the data is still loading.
  bool _isLoading = true;
  // Variable to store the total distance of the vehicle path in meters.
  double _totalDistance = 0.0;
  // Variable to store the highest speed recorded during the trip.
  double _maxSpeed = 0.0;
  // The store that is closest to the vehicle path.
  Store? _closestStore;
  // The timestamp when the vehicle first came close to the closest store.
  String? _firstTimestampNearStore;
  // The distance to the closest store.
  double? _closestDistance;

  // List of vehicle points loaded from the JSON asset.
  List<VehiclePoint> vehiclePoints = [];
  // List of stores loaded from the JSON asset.
  List<Store> stores = [];
  // Formatter for converting epoch timestamps to a human-readable date/time string.
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');

  @override
  void initState() {
    // Called when this widget is inserted into the widget tree.
    super.initState();
    // Load vehicle and store data, then update the map accordingly.
    _loadData();
  }

  /// Loads vehicle and store data, calculates metrics, and sets up markers on the map.
  Future<void> _loadData() async {
    // Parse vehicle path data from the JSON asset.
    vehiclePoints = await parseVehiclePath();
    // Parse store data from the JSON asset.
    stores = await parseStores();

    // Log the number of vehicle points and stores loaded for debugging purposes.
    print('Loaded ${vehiclePoints.length} vehicle points.');
    print('Loaded ${stores.length} stores.');

    // Calculate the total distance traveled and the highest speed from the vehicle points.
    _calculatePathMetrics(vehiclePoints);
    // Find the store that is closest to the vehicle path and record when the vehicle first approached it.
    _findClosestStore(vehiclePoints, stores);

    // Update the state with the newly loaded data.
    setState(() {
      // Create markers for each store.
      _markers = stores
          .map((store) => Marker(
                // Each marker uses the store's unique id.
                markerId: MarkerId(store.id),
                // Set the marker's position based on the store's latitude and longitude.
                position: LatLng(store.latitude, store.longitude),
                // Set an info window displaying the store's name.
                infoWindow: InfoWindow(title: store.name),
                // Highlight the closest store with a green marker; others use the default marker.
                icon: (store == _closestStore)
                    ? BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueGreen)
                    : BitmapDescriptor.defaultMarker,
              ))
          .toSet();

      // Create markers for each vehicle point with detailed metrics.
      _markers = _markers.union(vehiclePoints.map((point) {
        // Parse the timestamp string into an integer (assumed to be epoch seconds).
        final timestampInt = int.tryParse(point.timestamp) ?? 0;
        return Marker(
          // Create a unique marker ID combining the timestamp and coordinates.
          markerId: MarkerId(
              'vehicle_${point.timestamp}_${point.latitude}_${point.longitude}'),
          // Set the marker's position using the vehicle point's coordinates.
          position: LatLng(point.latitude, point.longitude),
          // Set an info window displaying the vehicle's metrics.
          infoWindow: InfoWindow(
            title: 'Vehicle Metrics',
            snippet: '''
Time: ${timestampInt != 0 ? _dateFormatter.format(DateTime.fromMillisecondsSinceEpoch(timestampInt * 1000)) : 'N/A'}
Speed: ${point.speed.toStringAsFixed(1)} km/h
Heading: ${point.heading.toStringAsFixed(1)}°
''',
          ),
          // Use blue markers for vehicle points.
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        );
      }).toSet());

      // Create a polyline that connects all the vehicle points to form the vehicle's path.
      _polylines = {
        Polyline(
          // Unique identifier for the polyline.
          polylineId: const PolylineId('vehicle_path'),
          // Set the polyline color with some transparency.
          color: Colors.orange.withOpacity(0.7),
          // Set the width of the polyline.
          width: 4,
          // Convert each vehicle point into a LatLng coordinate and form a list.
          points: vehiclePoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList(),
        ),
      };

      // Set the loading flag to false once data has been loaded and processed.
      _isLoading = false;
    });

    // If the map controller is available, adjust the camera to include all markers.
    if (_mapController != null) _recenterCamera();
  }

  /// Calculates the total distance traveled and the highest speed recorded along the vehicle path.
  void _calculatePathMetrics(List<VehiclePoint> path) {
    // If there are no points in the path, exit the function.
    if (path.isEmpty) return;
    // Initialize total distance and maximum speed.
    _totalDistance = 0.0;
    _maxSpeed = 0.0;
    // Loop through the vehicle points starting from the second point.
    for (int i = 1; i < path.length; i++) {
      // Calculate the distance between the current point and the previous point.
      _totalDistance += _calculateDistance(
        path[i - 1].latitude,
        path[i - 1].longitude,
        path[i].latitude,
        path[i].longitude,
      );
      // Update the maximum speed if the current point's speed is higher than the current max.
      _maxSpeed = max(_maxSpeed, path[i].speed);
    }
  }

  /// Finds the store closest to the vehicle path and records the first timestamp when the vehicle was near that store.
  void _findClosestStore(List<VehiclePoint> path, List<Store> stores) {
    // Initialize the minimum distance to infinity.
    double minDistance = double.infinity;
    // Variable to store the closest store.
    Store? closest;
    // Variable to store the timestamp when the vehicle first approached the store.
    String? firstTimestamp;

    // Loop over each store.
    for (var store in stores) {
      // For each store, loop over every vehicle point.
      for (var point in path) {
        // Calculate the distance between the store and the current vehicle point.
        double distance = _calculateDistance(
            point.latitude, point.longitude, store.latitude, store.longitude);
        // If this distance is less than the current minimum, update the closest store and record the timestamp.
        if (distance < minDistance) {
          minDistance = distance;
          closest = store;
          firstTimestamp = point.timestamp;
        }
      }
    }
    // Save the closest store and the first timestamp when it was near the vehicle path.
    _closestStore = closest;
    _firstTimestampNearStore = firstTimestamp;
    // Also save the calculated minimum distance.
    _closestDistance = minDistance;
    // Debug: Log the closest store and its distance.
    print('Closest store: ${_closestStore?.name}, at distance: $minDistance');
  }

  /// Calculates the distance between two geographic coordinates using the haversine formula.
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371e3; // Earth's radius in meters.
    double phi1 = lat1 * pi / 180; // Convert latitude 1 to radians.
    double phi2 = lat2 * pi / 180; // Convert latitude 2 to radians.
    double deltaLat =
        (lat2 - lat1) * pi / 180; // Difference in latitudes in radians.
    double deltaLon =
        (lon2 - lon1) * pi / 180; // Difference in longitudes in radians.

    // Apply the haversine formula.
    double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLon / 2) * sin(deltaLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    // Return the calculated distance in meters.
    return R * c;
  }

  /// Creates a bounding box that encompasses all markers and vehicle points.
  LatLngBounds _createBoundsFromAllPoints() {
    // Create a list of positions from all markers.
    List<LatLng> allPoints = _markers.map((m) => m.position).toList()
      // Also add positions for all vehicle points.
      ..addAll(vehiclePoints.map((p) => LatLng(p.latitude, p.longitude)));

    // Initialize the minimum and maximum latitude/longitude using the first point.
    double minLat = allPoints.first.latitude;
    double maxLat = allPoints.first.latitude;
    double minLng = allPoints.first.longitude;
    double maxLng = allPoints.first.longitude;

    // Iterate through all points to find the extreme coordinates.
    for (LatLng point in allPoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    // Return a LatLngBounds object that covers all the points.
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  /// Recenters the map camera to include all markers and vehicle points.
  void _recenterCamera() {
    // If the map controller is null, exit the function.
    if (_mapController == null) return;
    // Get the bounds that cover all markers and points.
    final bounds = _createBoundsFromAllPoints();
    // Animate the camera to these bounds with a padding of 50.
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  @override
  Widget build(BuildContext context) {
    // Build the UI for the MapScreen.
    return Scaffold(
      // App bar with the title of the screen.
      appBar: AppBar(title: const Text('Vehicle Path Map')),
      // The body: if data is loading, show a progress indicator; otherwise, show the map and key metrics.
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Expanded widget to let the map fill available space.
                Expanded(
                  child: GoogleMap(
                    // Set the initial camera position.
                    initialCameraPosition: const CameraPosition(
                      target:
                          LatLng(-34.0, 18.7), // Default starting coordinates.
                      zoom: 10,
                    ),
                    // Callback when the map is created.
                    onMapCreated: (controller) {
                      _mapController = controller; // Save the controller.
                      _recenterCamera(); // Recenter the camera after the map is ready.
                    },
                    // Provide the markers to display.
                    markers: _markers,
                    // Provide the polylines to display.
                    polylines: _polylines,
                  ),
                ),
                // Padding for the key information below the map.
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display the total distance (converted to kilometers).
                      Text(
                          "Total Distance: ${(_totalDistance / 1000).toStringAsFixed(2)} km"),
                      // Display the highest speed recorded.
                      Text(
                          "Highest Speed: ${_maxSpeed.toStringAsFixed(2)} km/h"),
                      // Display the closest store name if available.
                      if (_closestStore != null)
                        Text("Closest Store: ${_closestStore!.name}"),
                      // Display the distance to the closest store if available.
                      if (_closestDistance != null)
                        Text(
                            "Distance to Closest Store: ${_closestDistance!.toStringAsFixed(2)} m"),
                      // Display the first timestamp when the vehicle was near the closest store.
                      if (_firstTimestampNearStore != null)
                        Builder(
                          builder: (context) {
                            // Try parsing the timestamp; if it fails, default to 0.
                            final timestamp =
                                int.tryParse(_firstTimestampNearStore!) ?? 0;
                            // Format the timestamp if valid; otherwise, show 'Unknown'.
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
