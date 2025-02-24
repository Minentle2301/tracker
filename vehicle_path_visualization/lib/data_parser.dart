// Import necessary Flutter and external libraries
import 'dart:convert'; // Used for decoding JSON data
import 'package:flutter/services.dart'; // Used to load assets like JSON and CSV files
import 'package:csv/csv.dart'; // Used for parsing CSV files

/// Represents a single point in the vehicle's travel path.
class VehiclePoint {
  double latitude; // Latitude coordinate
  double longitude; // Longitude coordinate
  String timestamp; // Timestamp of when this data point was recorded
  double speed; // Vehicle speed at this point
  double heading; // Vehicle heading (direction)

  // Constructor to initialize a VehiclePoint object with required values
  VehiclePoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.speed,
    required this.heading,
  });
}

/// Represents a store's location.
class Store {
  String name; // Store name
  double latitude; // Store latitude coordinate
  double longitude; // Store longitude coordinate

  // Constructor to initialize a Store object with required values
  Store({
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

/// **Function to parse vehicle path data from a JSON file.**
/// - Reads the `PathTravelled.json` file from assets.
/// - Converts JSON data into a list of `VehiclePoint` objects.
/// - Returns a list of `VehiclePoint` objects.
Future<List<VehiclePoint>> parseVehiclePath() async {
  try {
    // Load the JSON file from assets as a string
    final String response =
        await rootBundle.loadString('assets/PathTravelled.json');

    // Check if the file is empty
    if (response.isEmpty) throw Exception("Empty JSON file");

    // Decode the JSON string into a dynamic list
    final List<dynamic> data = json.decode(response);

    // Convert each JSON object into a `VehiclePoint` object and return the list
    return data
        .map((point) => VehiclePoint(
              latitude: point['latitude'] ??
                  0.0, // Extract latitude, default to 0.0 if missing
              longitude: point['longitude'] ??
                  0.0, // Extract longitude, default to 0.0 if missing
              timestamp: point['timestamp']?.toString() ??
                  "Unknown", // Extract timestamp, default to "Unknown"
              speed: point['speed'] ?? 0.0, // Extract speed, default to 0.0
              heading:
                  point['heading'] ?? 0.0, // Extract heading, default to 0.0
            ))
        .toList();
  } catch (e) {
    // Print error message if loading JSON fails
    print("Error loading JSON: $e");
    return []; // Return an empty list if an error occurs
  }
}

/// **Function to parse store data from a CSV file.**
/// - Reads the `stores.Copy.csv` file from assets.
/// - Converts CSV data into a list of `Store` objects.
/// - Returns a list of `Store` objects.
Future<List<Store>> parseStores() async {
  try {
    // Load the CSV file from assets as a string
    final String response =
        await rootBundle.loadString('assets/stores.Copy.csv');

    // Check if the file is empty
    if (response.isEmpty) throw Exception("Empty CSV file");

    // Convert CSV string into a list of lists (rows and columns)
    List<List<dynamic>> csvData = const CsvToListConverter().convert(response);

    // Convert each valid row (excluding header) into a `Store` object and return the list
    return csvData
        .skip(1) // Skip the first row (header)
        .where(
            (row) => row.length >= 3) // Ensure the row has at least 3 columns
        .map((row) => Store(
              name: row[0].toString(), // Store name (column 1)
              latitude: double.tryParse(row[1].toString()) ??
                  0.0, // Convert latitude (column 2) to double
              longitude: double.tryParse(row[2].toString()) ??
                  0.0, // Convert longitude (column 3) to double
            ))
        .toList();
  } catch (e) {
    // Print error message if loading CSV fails
    print("Error loading CSV: $e");
    return []; // Return an empty list if an error occurs
  }
}
