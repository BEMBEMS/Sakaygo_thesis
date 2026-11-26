import 'package:geolocator/geolocator.dart';

import '../domain/passenger_models.dart';

abstract class LocationReader {
  const LocationReader();

  Future<LocationReadResult> readCurrentLocation();

  Future<void> openLocationSettings();
}

class DeviceLocationReader implements LocationReader {
  const DeviceLocationReader();

  @override
  Future<LocationReadResult> readCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return LocationReadResult.disabled();
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return LocationReadResult.denied();
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationReadResult.denied(permanently: true);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      return LocationReadResult.success(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );
    } catch (error) {
      return LocationReadResult.unavailable('Unable to read GPS: $error');
    }
  }

  @override
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}
