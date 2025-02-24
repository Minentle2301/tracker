import 'package:flutter/material.dart';
import 'map_screen.dart';

void main() {
  runApp(const MyApp());
}

/// **Main application widget**
/// - Uses Material Design 3 for a modern look
/// - Supports light and dark themes
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Removes debug banner for a clean UI
      title: 'Vehicle Path Visualization',

      /// **Modern Theming**
      theme: ThemeData(
        useMaterial3: true, // Enables Material Design 3
        brightness: Brightness.light, // Light theme by default
        primarySwatch: Colors.blue, // Primary color for UI
        scaffoldBackgroundColor: Colors.grey[200], // Light grey background
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white, // Modern white AppBar
          elevation: 3, // Adds a subtle shadow
          centerTitle: true, // Centers title text
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: Colors.black), // Black icons
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.blueAccent, // Stylish FAB color
          foregroundColor: Colors.white, // White FAB icon color
          elevation: 5, // Elevated shadow effect
        ),
      ),

      /// **Dark Mode Theme**
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black, // Dark background
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 3,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          elevation: 5,
        ),
      ),

      themeMode:
          ThemeMode.system, // Adapts to system settings (light/dark mode)
      home: const HomeScreen(), // Updated home screen
    );
  }
}

/// **New HomeScreen with a modern layout**
/// - Wraps `MapScreen` with additional UI elements
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle Path Map')),

      /// **Main Body: Embeds the MapScreen**
      body: const MapScreen(),

      /// **Floating Action Button (FAB)**
      /// - Used for adding new features or interactions
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Feature coming soon!"),
              duration: Duration(seconds: 2),
            ),
          );
        },
        child: const Icon(Icons.refresh), // Refresh button (or add new feature)
      ),
    );
  }
}
