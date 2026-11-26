enum LocationReadStatus { success, disabled, denied, unavailable }

class LocationReadResult {
  const LocationReadResult({
    required this.status,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.message = '',
  });

  final LocationReadStatus status;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String message;

  bool get isSuccess => status == LocationReadStatus.success;

  factory LocationReadResult.success({
    required double latitude,
    required double longitude,
    double? accuracy,
  }) {
    return LocationReadResult(
      status: LocationReadStatus.success,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      message: 'Current GPS location captured.',
    );
  }

  factory LocationReadResult.disabled() {
    return const LocationReadResult(
      status: LocationReadStatus.disabled,
      message: 'Enable GPS to capture your current location.',
    );
  }

  factory LocationReadResult.denied({bool permanently = false}) {
    return LocationReadResult(
      status: LocationReadStatus.denied,
      message: permanently
          ? 'Location permission is permanently denied. Enable it in app settings.'
          : 'Location permission was denied.',
    );
  }

  factory LocationReadResult.unavailable(String message) {
    return LocationReadResult(
      status: LocationReadStatus.unavailable,
      message: message,
    );
  }
}

class PassengerProfile {
  const PassengerProfile({
    required this.passengerId,
    required this.passengerClass,
    this.currentLatitude,
    this.currentLongitude,
  });

  final String passengerId;
  final String passengerClass;
  final double? currentLatitude;
  final double? currentLongitude;

  bool get hasCurrentLocation =>
      currentLatitude != null && currentLongitude != null;

  factory PassengerProfile.fromJson(Map<String, dynamic> json) {
    return PassengerProfile(
      passengerId: json['passengerId'] as String? ?? json['passenger_id'] as String? ?? '',
      passengerClass:
          json['passengerClass'] as String? ?? json['passenger_class'] as String? ?? 'standard',
      currentLatitude: _toDouble(
        json['currentLatitude'] ?? json['current_latitude'],
      ),
      currentLongitude: _toDouble(
        json['currentLongitude'] ?? json['current_longitude'],
      ),
    );
  }
}

class PassengerRequest {
  const PassengerRequest({
    required this.requestId,
    required this.passengerId,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.destinationName,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.passengerClass,
    required this.priorityScore,
    required this.status,
    required this.requestedAt,
  });

  final String requestId;
  final String passengerId;
  final double pickupLatitude;
  final double pickupLongitude;
  final String destinationName;
  final double destinationLatitude;
  final double destinationLongitude;
  final String passengerClass;
  final double priorityScore;
  final String status;
  final DateTime requestedAt;

  factory PassengerRequest.fromJson(Map<String, dynamic> json) {
    return PassengerRequest(
      requestId: json['requestId'] as String? ?? json['request_id'] as String? ?? '',
      passengerId: json['passengerId'] as String? ?? json['passenger_id'] as String? ?? '',
      pickupLatitude: _requiredDouble(json['pickupLatitude'] ?? json['pickup_latitude']),
      pickupLongitude: _requiredDouble(json['pickupLongitude'] ?? json['pickup_longitude']),
      destinationName:
          json['destinationName'] as String? ?? json['destination_name'] as String? ?? '',
      destinationLatitude:
          _requiredDouble(json['destinationLatitude'] ?? json['destination_latitude']),
      destinationLongitude:
          _requiredDouble(json['destinationLongitude'] ?? json['destination_longitude']),
      passengerClass:
          json['passengerClass'] as String? ?? json['passenger_class'] as String? ?? 'standard',
      priorityScore: _requiredDouble(json['priorityScore'] ?? json['priority_score']),
      status: json['status'] as String? ?? 'searching',
      requestedAt: DateTime.tryParse(
            json['requestedAt'] as String? ?? json['requested_at'] as String? ?? '',
          ) ??
          DateTime.now(),
    );
  }
}

double? _toDouble(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

double _requiredDouble(dynamic value) {
  return _toDouble(value) ?? 0;
}
