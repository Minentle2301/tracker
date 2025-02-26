import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';

/// Represents a vehicle path point with geospatial and temporal data
class VehiclePoint {
  final double latitude;
  final double longitude;
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

/// Represents a store location with unique identifier
class Store {
  final String id; // Unique store identifier
  final String name; // Store display name
  final double latitude;
  final double longitude;

  Store({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

/// Parses vehicle path data from JSON asset
Future<List<VehiclePoint>> parseVehiclePath() async {
  try {
    final String response =
        await rootBundle.loadString('assets/PathTravelled.json');
    if (response.isEmpty) throw Exception("Empty JSON file");

    final List<dynamic> data = json.decode(response);
    return data
        .map((point) => VehiclePoint(
              latitude: point['latitude']?.toDouble() ?? 0.0,
              longitude: point['longitude']?.toDouble() ?? 0.0,
              timestamp: point['timestamp']?.toString() ?? "Unknown",
              speed: point['speed']?.toDouble() ?? 0.0,
              heading: point['heading']?.toDouble() ?? 0.0,
            ))
        .toList();
  } catch (e) {
    print("Vehicle path parsing error: $e");
    return [];
  }
}

/// Parses store data from JSON asset
Future<List<Store>> parseStores() async {
  try {
    final String response =
        await rootBundle.loadString('assets/storesCopy.json');
    if (response.isEmpty) throw Exception("Empty store JSON file");

    final List<dynamic> data = json.decode(response);
    return data
        .map((store) => Store(
              id: store['store'], // Unique identifier from JSON
              name: store['store'], // Display name
              latitude: (store['latitude'] as num).toDouble(),
              longitude: (store['longitude'] as num).toDouble(),
            ))
        .toList();
  } catch (e) {
    print("Store parsing error: $e");
    return [];
  }
}
