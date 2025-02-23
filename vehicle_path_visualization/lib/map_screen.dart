import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'data_parser.dart';

/// Displays the vehicle path and stores on a Google Map.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Loads vehicle path and store data.
  Future<void> _loadData() async {
    try {
      final vehiclePath = await parseVehiclePath();
      final stores = await parseStores();

      setState(() {
        _markers = stores
            .map((store) => Marker(
                  markerId: MarkerId(store.name),
                  position: LatLng(store.latitude, store.longitude),
                  infoWindow: InfoWindow(title: store.name),
                ))
            .toSet();

        _polylines = {
          Polyline(
            polylineId: const PolylineId('vehicle_path'),
            color: Colors.blue,
            width: 4,
            points: vehiclePath
                .map((point) => LatLng(point.latitude, point.longitude))
                .toList(),
          ),
        };

        _isLoading = false;
      });
    } catch (e) {
      print("Error loading data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle Path Map')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(-33.92, 18.85), // Default starting point
                zoom: 10,
              ),
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              markers: _markers,
              polylines: _polylines,
            ),
    );
  }
}
