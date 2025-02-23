import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';

class VehiclePoint {
  double latitude;
  double longitude;
  String timestamp;
  double speed;
  double heading;

  VehiclePoint(
      {required this.latitude,
      required this.longitude,
      required this.timestamp,
      required this.speed,
      required this.heading});
}

class Store {
  String name;
  double latitude;
  double longitude;

  Store({required this.name, required this.latitude, required this.longitude});
}

// Parse JSON
Future<List<VehiclePoint>> parseVehiclePath() async {
  try {
    final String response =
        await rootBundle.loadString('assets/PathTravelled.json');
    if (response.isEmpty) throw Exception("Empty JSON file");

    final List<dynamic> data = json.decode(response);
    return data
        .map((point) => VehiclePoint(
              latitude: point['latitude'] ?? 0.0,
              longitude: point['longitude'] ?? 0.0,
              timestamp: point['timestamp']?.toString() ?? "Unknown",
              speed: point['speed'] ?? 0.0,
              heading: point['heading'] ?? 0.0,
            ))
        .toList();
  } catch (e) {
    print("Error loading JSON: $e");
    return [];
  }
}

// Parse CSV
Future<List<Store>> parseStores() async {
  try {
    final String response =
        await rootBundle.loadString('assets/stores.Copy.csv');
    if (response.isEmpty) throw Exception("Empty CSV file");

    List<List<dynamic>> csvData = const CsvToListConverter().convert(response);

    return csvData
        .skip(1) // Skip headers
        .where((row) => row.length >= 3) // Ensure at least 3 columns exist
        .map((row) => Store(
              name: row[0].toString(),
              latitude: double.tryParse(row[1].toString()) ?? 0.0,
              longitude: double.tryParse(row[2].toString()) ?? 0.0,
            ))
        .toList();
  } catch (e) {
    print("Error loading CSV: $e");
    return [];
  }
}
