import 'package:flutter/services.dart';

import '../models/exercise.dart';

abstract interface class ExerciseRepository {
  Future<ExerciseCatalog> load();
}

/// Bundled local storage: available from the first launch, with no network I/O.
/// A future editable storage adapter can implement the same contract.
class AssetExerciseRepository implements ExerciseRepository {
  AssetExerciseRepository({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;
  static const assetPath = 'assets/catalog/exercises.v1.json';
  final AssetBundle _bundle;
  ExerciseCatalog? _cached;

  @override
  Future<ExerciseCatalog> load() async {
    final cached = _cached;
    if (cached != null) return cached;
    final catalog = ExerciseCatalog.decode(
      await _bundle.loadString(assetPath, cache: false),
    );
    _cached = catalog;
    return catalog;
  }
}
