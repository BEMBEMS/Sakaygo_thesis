final RegExp _usernamePattern = RegExp(r'^[A-Za-z0-9_.-]+$');
final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? validateUsername(String? value) {
  final text = value?.trim() ?? '';

  if (text.isEmpty) {
    return 'Username is required';
  }
  if (text.length < 3 || text.length > 50) {
    return 'Username must be 3 to 50 characters';
  }
  if (!_usernamePattern.hasMatch(text)) {
    return 'Use letters, numbers, dot, dash, or underscore only';
  }
  return null;
}

String? validatePassword(String? value) {
  final text = value ?? '';

  if (text.isEmpty) {
    return 'Password is required';
  }
  if (text.length < 8) {
    return 'Password must be at least 8 characters';
  }
  return null;
}

String? validateName(String? value, String label) {
  final text = value?.trim() ?? '';

  if (text.isEmpty) {
    return '$label is required';
  }
  if (text.length > 100) {
    return '$label must be 100 characters or fewer';
  }
  return null;
}

String? validateEmail(String? value) {
  final text = value?.trim() ?? '';

  if (text.isEmpty) {
    return null;
  }
  if (!_emailPattern.hasMatch(text)) {
    return 'Enter a valid email address';
  }
  return null;
}

String? validatePhone(String? value) {
  final text = value?.trim() ?? '';

  if (text.isEmpty) {
    return null;
  }
  if (text.length < 7 || text.length > 20) {
    return 'Phone number must be 7 to 20 characters';
  }
  return null;
}

String? validateRequired(String? value, String label) {
  final text = value?.trim() ?? '';

  if (text.isEmpty) {
    return '$label is required';
  }
  return null;
}
