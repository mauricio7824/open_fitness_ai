import 'package:flutter/material.dart';

import 'app.dart';
import 'core/data/fitness_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(OpenFitnessApp(store: PreferencesFitnessStore()));
}
