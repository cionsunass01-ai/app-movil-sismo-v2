import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/water_point.dart';
import '../models/sector_data.dart';
import '../models/citizen_report.dart';
import '../models/user_location.dart';
import '../sources/mock_water_points.dart';
import '../../core/utils/geo_utils.dart';

class WaterRepository {
  static const String _queuedReportsKey = 'aguacion_queued_reports';

  List<WaterPoint> _points = List.from(MockWaterData.initialPoints);
  final List<SectorData> _sectors = List.from(MockWaterData.sectoresData);

  List<WaterPoint> getPoints(UserLocation userLocation) {
    return _points.map((p) {
      final int dist = GeoUtils.calculateDistanceMeters(
        userLocation.lat,
        userLocation.lon,
        p.lat,
        p.lon,
      );
      return p.copyWith(distMeters: dist);
    }).toList()
      ..sort((a, b) => (a.distMeters ?? 0).compareTo(b.distMeters ?? 0));
  }

  List<SectorData> getSectors() => _sectors;

  List<UserLocation> getPredefinedLocations() => MockWaterData.userLocations;

  void updatePointStatus({
    required String pointId,
    required EmergencyStatus status,
    required String statusText,
  }) {
    _points = _points.map((p) {
      if (p.id == pointId) {
        return p.copyWith(
          estE: status,
          estETxt: statusText,
        );
      }
      return p;
    }).toList();
  }

  void resetPoints() {
    _points = List.from(MockWaterData.initialPoints);
  }

  // --- Offline Queued Reports Persistence ---

  Future<List<CitizenReport>> loadQueuedReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? jsonList = prefs.getStringList(_queuedReportsKey);
      if (jsonList == null || jsonList.isEmpty) return [];

      return jsonList
          .map((item) => CitizenReport.fromJson(json.decode(item) as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveQueuedReport(CitizenReport report) async {
    final prefs = await SharedPreferences.getInstance();
    final List<CitizenReport> currentList = await loadQueuedReports();
    currentList.insert(0, report);

    final List<String> encodedList =
        currentList.map((r) => json.encode(r.toJson())).toList();
    await prefs.setStringList(_queuedReportsKey, encodedList);
  }

  Future<void> clearQueuedReports() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queuedReportsKey);
  }
}
