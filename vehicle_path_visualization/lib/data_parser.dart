import 'dart:convert';
import 'package:flutter/services.dart';

/// Represents a vehicle path point with geospatial and temporal data.
class VehiclePoint {
  final double latitude;
  final double longitude;
  // Note: The key in the JSON is "timeStamp" (with a capital S).
  final String timestamp;
  final double speed;
  final double heading;

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
  final String id; // Unique store identifier.
  final String name; // Store display name.
  final double latitude;
  final double longitude;

  Store({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

/// Parses vehicle path data from a JSON asset.
Future<List<VehiclePoint>> parseVehiclePath() async {
  try {
    // Load the JSON file as a string.
    final String response =
        await rootBundle.loadString('assets/PathTravelled.json');
    if (response.isEmpty) throw Exception("Empty JSON file for vehicle path");

    final List<dynamic> data = json.decode(response);
    // Map each JSON object to a VehiclePoint.
    return data
        .map((point) => VehiclePoint(
              latitude: point['latitude']?.toDouble() ?? 0.0,
              longitude: point['longitude']?.toDouble() ?? 0.0,
              // Use the correct key "timeStamp" here.
              timestamp: point['timeStamp']?.toString() ?? "0",
              speed: point['speed']?.toDouble() ?? 0.0,
              heading: point['heading']?.toDouble() ?? 0.0,
            ))
        .toList();
  } catch (e) {
    print("Vehicle path parsing error: $e");
    return [];
  }
}

/// Parses store data from a JSON asset.
Future<List<Store>> parseStores() async {
  try {
    final String response =
        await rootBundle.loadString('assets/storesCopy.json');
    if (response.isEmpty) throw Exception("Empty JSON file for stores");

    final List<dynamic> data = json.decode(response);
    // Map each JSON object to a Store.
    return data
        .map((store) => Store(
              // Assuming the JSON key 'store' holds both ID and name.
              id: store['store'],
              name: store['store'],
              latitude: (store['latitude'] as num).toDouble(),
              longitude: (store['longitude'] as num).toDouble(),
            ))
        .toList();
  } catch (e) {
    print("Store parsing error: $e");
    return [];
  }
}
