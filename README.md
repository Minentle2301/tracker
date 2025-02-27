



# Vehicle Path Visualization

This Flutter application visualizes a vehicle's journey on a Google Map. It displays the vehicle path using a polyline, places markers for each vehicle point (showing detailed metrics such as timestamp, speed, and heading), and plots store locations—highlighting the closest store to the vehicle's path. Key trip metrics like total distance traveled, the highest speed recorded, and the time the vehicle first came near the closest store are shown in the UI.

## Features

- **Vehicle Path Visualization:**  
  - Plots a polyline representing the path traveled by the vehicle.
  - Marks individual vehicle points with red markers.
  - Each vehicle marker shows:
    - **Timestamp:** Formatted as a human-readable date and time.
    - **Speed:** Recorded speed in km/h.
    - **Heading:** Vehicle's heading in degrees.

- **Store Markers & Closest Store Highlight:**  
  - Displays store locations on the map.
  - Highlights the closest store to the vehicle path.
  - Shows an info window with the store name.

- **Trip Metrics Display:**  
  - **Total Distance:** The distance traveled by the vehicle (in km).
  - **Highest Speed:** The maximum speed recorded during the trip.
  - **First Near Store Timestamp:** The time when the vehicle first came close to the closest store.

- **Interactive UI:**  
  - Users can tap on markers to view detailed information.
  - The app is responsive and works on both desktop and mobile devices.

## File Structure

- **main.dart:**  
  Entry point of the Flutter app.

- **map_screen.dart:**  
  Contains the UI and logic for displaying the Google Map, markers, polyline, and trip metrics.

- **data_parser.dart:**  
  Handles parsing of JSON data for vehicle points and store locations from assets.

- **assets/PathTravelled.json:**  
  JSON file containing the vehicle path data.  
  **Example JSON structure:**
  ```json
  {
    "timeStamp": 1739404904,
    "latitude": -34.0128416,
    "longitude": 18.690535,
    "heading": 0,
    "speed": 0
  }


loom video explaining url : [https://www.loom.com/share/ef98275fa4794627a09b064724d67bf1?sid=13bdf7b7-13db-40b3-8ce7-bb679a862bd7]
