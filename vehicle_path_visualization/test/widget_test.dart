import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vehicle_path_visualization/map_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Import GoogleMap

void main() {
  testWidgets('MapScreen loads and displays GoogleMap',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: MapScreen()));

    // Verify that a GoogleMap widget is present.
    expect(find.byType(GoogleMap), findsOneWidget);
  });
}
