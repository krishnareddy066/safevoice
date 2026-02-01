import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {

  static Future<Map<String, dynamic>> getCurrentLocation() async {

    // Check permission
    LocationPermission permission =
    await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permission denied");
    }

    // Get GPS position
    Position position =
    await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    // Convert to address
    List<Placemark> places =
    await placemarkFromCoordinates(
        position.latitude,
        position.longitude);

    String address = "";

    if (places.isNotEmpty) {
      final p = places.first;

      address =
      "${p.locality}, ${p.administrativeArea}, ${p.country}";
    }

    return {
      "latitude": position.latitude,
      "longitude": position.longitude,
      "address": address,
    };
  }
}
