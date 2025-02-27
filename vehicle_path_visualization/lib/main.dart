// Import Flutter's material design library.
import 'package:flutter/material.dart';
// Import the MapScreen widget from the local file.
import 'map_screen.dart';

/// The entry point of the Flutter application.
void main() {
  // runApp initializes the app by inflating the given widget and attaching it to the screen.
  runApp(const MyApp());
}

/// MyApp is a stateless widget that sets up the root of the application.
class MyApp extends StatelessWidget {
  // Constructor for MyApp. 'const' indicates that this widget is immutable.
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // MaterialApp is a convenience widget that provides many default settings.
    return const MaterialApp(
      // The title of the application.
      title: 'Vehicle Path Visualization',
      // Remove the debug banner.
      debugShowCheckedModeBanner: false,
      // The home property specifies the default route of the app. Here it is set to MapScreen.
      home: MapScreen(),
    );
  }
}
