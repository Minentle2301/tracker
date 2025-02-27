// Import the Dart library for JSON encoding and decoding.
import 'dart:convert';
// Import Flutter services to load assets (e.g., JSON files).
import 'package:flutter/services.dart';

/// Represents a vehicle path point with geospatial and temporal data.
class VehiclePoint {
  // Latitude coordinate.
  final double latitude;
  // Longitude coordinate.
  final double longitude;
  // Timestamp when this point was recorded (stored as a string).
  final String timestamp;
  // Speed at this point.
  final double speed;
  // Heading (direction) at this point, in degrees.
  final double heading;

  // Constructor for creating a VehiclePoint.
  VehiclePoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.speed,
    required this.heading,
  });
}

/// Represents a store location with a unique identifier.
class Store {
  // Unique identifier for the store.
  final String id;
  // Display name of the store.
  final String name;
  // Latitude coordinate of the store.
  final double latitude;
  // Longitude coordinate of the store.
  final double longitude;

  // Constructor for creating a Store.
  Store({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

/// Parses vehicle path data from a JSON asset.
/// Reads the JSON file from assets, decodes it, and returns a list of VehiclePoint objects.
Future<List<VehiclePoint>> parseVehiclePath() async {
  try {
    // Load the JSON file 'PathTravelled.json' from the assets folder as a string.
    final String response =
        await rootBundle.loadString('assets/PathTravelled.json');
    // If the response is empty, throw an exception.
    if (response.isEmpty) throw Exception("Empty JSON file for vehicle path");

    // Decode the JSON string into a list of dynamic objects.
    final List<dynamic> data = json.decode(response);
    // Map each JSON object to a VehiclePoint instance and return as a list.
    return data
        .map((point) => VehiclePoint(
              // Convert the 'latitude' value to double; default to 0.0 if missing.
              latitude: point['latitude']?.toDouble() ?? 0.0,
              // Convert the 'longitude' value to double; default to 0.0 if missing.
              longitude: point['longitude']?.toDouble() ?? 0.0,
              // Use the key "timeStamp" (note the capital S) for the timestamp; default to "0".
              timestamp: point['timeStamp']?.toString() ?? "0",
              // Convert the 'speed' value to double; default to 0.0 if missing.
              speed: point['speed']?.toDouble() ?? 0.0,
              // Convert the 'heading' value to double; default to 0.0 if missing.
              heading: point['heading']?.toDouble() ?? 0.0,
            ))
        .toList();
  } catch (e) {
    // Print any errors encountered during parsing.
    print("Vehicle path parsing error: $e");
    // Return an empty list if parsing fails.
    return [];
  }
}

/// Parses store data from a JSON asset.
/// Reads the JSON file from assets, decodes it, and returns a list of Store objects.
Future<List<Store>> parseStores() async {
  try {
    // Load the JSON file 'storesCopy.json' from the assets folder as a string.
    final String response =
        await rootBundle.loadString('assets/storesCopy.json');
    // If the response is empty, throw an exception.
    if (response.isEmpty) throw Exception("Empty JSON file for stores");

    // Decode the JSON string into a list of dynamic objects.
    final List<dynamic> data = json.decode(response);
    // Map each JSON object to a Store instance and return as a list.
    return data
        .map((store) => Store(
              // Use the 'store' key from JSON for both id and name.
              id: store['store'],
              name: store['store'],
              // Convert the 'latitude' value to double.
              latitude: (store['latitude'] as num).toDouble(),
              // Convert the 'longitude' value to double.
              longitude: (store['longitude'] as num).toDouble(),
            ))
        .toList();
  } catch (e) {
    // Print any errors encountered during parsing.
    print("Store parsing error: $e");
    // Return an empty list if parsing fails.
    return [];
  }
}
