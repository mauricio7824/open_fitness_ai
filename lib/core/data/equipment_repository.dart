import 'package:flutter/services.dart';

import '../models/equipment.dart';

abstract interface class EquipmentRepository {
  Future<EquipmentCatalog> load();
}

class AssetEquipmentRepository implements EquipmentRepository {
  AssetEquipmentRepository({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;
  static const assetPath = 'assets/catalog/equipment.v1.json';
  final AssetBundle _bundle;
  EquipmentCatalog? _cached;
  @override
  Future<EquipmentCatalog> load() async => _cached ??= EquipmentCatalog.decode(
    await _bundle.loadString(assetPath, cache: false),
  );
}
