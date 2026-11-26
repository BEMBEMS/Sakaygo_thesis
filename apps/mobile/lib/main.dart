import 'package:flutter/material.dart';

import 'src/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await authController.restore();
  runApp(const TricycleMatchingApp());
}
