String? validateLatitude(String? value) {
  final text = value?.trim() ?? '';

  if (text.isEmpty) {
    return 'Latitude is required';
  }

  final latitude = double.tryParse(text);

  if (latitude == null || latitude < -90 || latitude > 90) {
    return 'Latitude must be between -90 and 90';
  }

  return null;
}

String? validateLongitude(String? value) {
  final text = value?.trim() ?? '';

  if (text.isEmpty) {
    return 'Longitude is required';
  }

  final longitude = double.tryParse(text);

  if (longitude == null || longitude < -180 || longitude > 180) {
    return 'Longitude must be between -180 and 180';
  }

  return null;
}

String? validateDestinationName(String? value) {
  final text = value?.trim() ?? '';

  if (text.isEmpty) {
    return 'Destination is required';
  }
  if (text.length > 200) {
    return 'Destination must be 200 characters or fewer';
  }

  return null;
}
