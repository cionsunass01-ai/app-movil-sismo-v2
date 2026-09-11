import '../water/water_point.dart';
import '../water/water_point_status.dart';
import '../water/observation_model.dart';
import '../incident/incident.dart';
import '../reporting/citizen_report.dart';
import '../reporting/outbox_item.dart';
import '../metadata/dataset_metadata.dart';
import '../audit/operational_event.dart';

/// Abstract repository for static water supply infrastructure assets.
abstract class IWaterPointRepository {
  Future<List<WaterPoint>> getAllWaterPoints();
  Future<WaterPoint?> getWaterPointById(String id);
  Future<List<WaterPoint>> getWaterPointsByDistrict(String district);
  Future<int> count();
}

/// Abstract repository for dynamic operational statuses and observation records.
abstract class IWaterPointStatusRepository {
  Future<WaterPointStatus?> getStatus(String waterPointId);
  Future<Map<String, WaterPointStatus>> getStatuses(List<String> waterPointIds);
  Future<void> saveStatus(WaterPointStatus status);
  Future<void> recordObservation(WaterPointObservation observation);
  Future<List<WaterPointObservation>> getObservations(String waterPointId);
  Future<List<SourceConflict>> getConflicts();
}

/// Abstract repository for physical and operational incidents.
abstract class IIncidentRepository {
  Future<List<Incident>> getActiveIncidents(DateTime referenceTime);
  Future<Incident?> getIncidentById(String incidentId);
  Future<void> saveIncident(Incident incident);
}

/// Abstract repository for citizen reports.
abstract class ICitizenReportRepository {
  Future<List<CitizenReport>> getPendingReports();
  Future<void> saveReport(CitizenReport report);
  Future<void> updateSyncStatus(String reportId, ReportSyncStatus status);
}

/// Abstract repository for durable offline Store & Forward queue.
abstract class IOutboxRepository {
  Future<List<OutboxItem>> getPendingItems({int limit = 50});
  Future<void> enqueue(OutboxItem item);
  Future<void> updateItem(OutboxItem item);
  Future<void> removeItem(String outboxId);
}

/// Abstract repository for offline dataset versioning and integrity.
abstract class IDatasetMetadataRepository {
  Future<DatasetMetadata?> getInstalledMetadata(String datasetId);
  Future<void> saveMetadata(DatasetMetadata metadata);
}

/// Abstract repository for append-only institutional audit events.
abstract class IOperationalEventRepository {
  Future<void> recordEvent(OperationalEvent event);
  Future<List<OperationalEvent>> getEventsForEntity(String entityId);
}
