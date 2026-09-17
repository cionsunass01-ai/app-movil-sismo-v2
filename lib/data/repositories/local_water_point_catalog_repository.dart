import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/water_point.dart';

enum CatalogStatus { uninitialized, available, unavailable }

/// Canonical single source of truth for the local water point catalog.
///
/// Loads the official normalized dataset of Lima & Callao (433 points)
/// from local offline assets. If the asset is missing, status is explicitly
/// [CatalogStatus.unavailable] and NO mock/legacy points are injected.
class LocalWaterPointCatalogRepository {
  final AssetBundle _bundle;
  static const String assetPath =
      'assets/poc/data/water_points_normalized.json';

  CatalogStatus _status = CatalogStatus.uninitialized;
  CatalogStatus get status => _status;
  bool get isAvailable => _status == CatalogStatus.available;

  List<WaterPoint> _cachedPoints = [];
  List<WaterPoint> get cachedPoints => List.unmodifiable(_cachedPoints);

  LocalWaterPointCatalogRepository({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  /// Loads the canonical catalog from offline storage.
  ///
  /// Returns the parsed points if available, or an empty list if unavailable.
  Future<List<WaterPoint>> loadCatalog() async {
    try {
      String jsonStr;

      // In Flutter test runner, read synchronously from disk to avoid FakeAsync deadlocks
      if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
        final diskFile = File(assetPath);
        if (diskFile.existsSync()) {
          jsonStr = diskFile.readAsStringSync();
        } else {
          _status = CatalogStatus.unavailable;
          _cachedPoints = [];
          return [];
        }
      } else {
        jsonStr = await _bundle.loadString(assetPath);
      }

      final dynamic decoded = json.decode(jsonStr);

      final List<dynamic> records;
      if (decoded is Map && decoded.containsKey('records')) {
        records = decoded['records'] as List<dynamic>;
      } else if (decoded is List) {
        records = decoded;
      } else {
        records = [];
      }

      if (records.isEmpty) {
        _status = CatalogStatus.unavailable;
        _cachedPoints = [];
        return [];
      }

      final List<WaterPoint> points = [];
      for (final item in records) {
        if (item is Map<String, dynamic>) {
          try {
            points.add(WaterPoint.fromNormalizedJson(item));
          } catch (_) {
            // Omit invalid/corrupted records lacking valid coordinates
          }
        }
      }

      if (points.isEmpty) {
        _status = CatalogStatus.unavailable;
        _cachedPoints = [];
        return [];
      }

      _cachedPoints = points;
      _status = CatalogStatus.available;
      return List.unmodifiable(_cachedPoints);
    } catch (_) {
      _status = CatalogStatus.unavailable;
      _cachedPoints = [];
      return [];
    }
  }

  /// Clears in-memory catalog cache (primarily for tests)
  void clearCache() {
    _cachedPoints = [];
    _status = CatalogStatus.uninitialized;
  }
}
