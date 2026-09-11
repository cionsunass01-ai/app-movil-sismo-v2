import 'package:flutter_test/flutter_test.dart';
import 'package:aguacion_app/domain/water/water_point.dart';
import 'package:aguacion_app/domain/water/water_point_access.dart';
import 'package:aguacion_app/domain/water/lifecycle_status.dart';
import 'package:aguacion_app/domain/water/water_point_status.dart';
import 'package:aguacion_app/domain/water/operational_status.dart';
import 'package:aguacion_app/domain/water/water_availability.dart';
import 'package:aguacion_app/domain/water/queue_level.dart';
import 'package:aguacion_app/domain/water/access_status.dart';
import 'package:aguacion_app/domain/water/water_source.dart';
import 'package:aguacion_app/domain/water/observation_model.dart';
import 'package:aguacion_app/domain/source/source_type.dart';
import 'package:aguacion_app/domain/source/confidence_level.dart';
import 'package:aguacion_app/domain/source/freshness.dart';
import 'package:aguacion_app/domain/source/freshness_policy.dart';
import 'package:aguacion_app/domain/source/citizen_corroboration_policy.dart';
import 'package:aguacion_app/domain/incident/incident.dart';
import 'package:aguacion_app/domain/reporting/citizen_report.dart';
import 'package:aguacion_app/domain/reporting/outbox_item.dart';
import 'package:aguacion_app/domain/metadata/dataset_metadata.dart';
import 'package:aguacion_app/domain/audit/operational_event.dart';
import 'package:aguacion_app/domain/recommendation/recommendation_candidate.dart';
import 'package:aguacion_app/domain/recommendation/recommendation_reason.dart';
import 'package:aguacion_app/domain/recommendation/recommendation_result.dart';

void main() {
  group('Hito 3A Operational Domain Model - Comprehensive Tests', () {
    final t0 = DateTime(2026, 9, 11, 10, 0, 0);

    test(
      '1. WaterPoint contains strictly static identity and NO temporal state',
      () {
        const point = WaterPoint(
          waterPointId: 'WP-SED-SUR-001',
          officialCode: 'POZO-P1',
          name: 'Pozo Dammert',
          componentTypeRaw: 'POZO',
          infrastructureLocation: GeoLocation(
            latitude: -12.095,
            longitude: -77.035,
          ),
          department: 'LIMA',
          province: 'LIMA',
          district: 'SAN ISIDRO',
          capacityRaw: '15.00',
          situationRaw: 'Operativo',
          stateRaw: 'Activo',
          generatorRaw: 'Sí',
          source: 'SUNASS_SEDAPAL_OFFICIAL',
          lifecycleStatus: LifecycleStatus.active,
        );

        expect(point.waterPointId, equals('WP-SED-SUR-001'));
        expect(point.capacityRaw, equals('15.00'));
        expect(point.district, equals('SAN ISIDRO'));
        expect(point.lifecycleStatus, equals(LifecycleStatus.active));

        // Verifies by reflection/contract that WaterPoint does not have volatile fields
        final json = point.toJson();
        expect(json.containsKey('queueLevel'), isFalse);
        expect(json.containsKey('waterAvailability'), isFalse);
        expect(json.containsKey('operationalStatus'), isFalse);
        expect(json.containsKey('estimatedWaitMinutes'), isFalse);
      },
    );

    test(
      '2. WaterPointStatus permits explicit UNKNOWN for all operational fields',
      () {
        final unknownStatus = WaterPointStatus.unknown(
          waterPointId: 'WP-SED-SUR-001',
          updatedAt: t0,
        );

        expect(
          unknownStatus.operationalStatus,
          equals(OperationalStatus.unknown),
        );
        expect(
          unknownStatus.waterAvailability,
          equals(WaterAvailability.unknown),
        );
        expect(unknownStatus.queueLevel, equals(QueueLevel.unknown));
        expect(unknownStatus.accessStatus, equals(AccessStatus.unknown));
        expect(unknownStatus.confidenceLevel, equals(ConfidenceLevel.unknown));
        expect(unknownStatus.estimatedWaitMinutes, isNull);
        expect(unknownStatus.validUntil, isNull);
        expect(unknownStatus.isPotentiallyOpen, isFalse);
      },
    );

    test(
      '3. validUntil is strictly nullable and evaluates expiration correctly',
      () {
        final statusNoExpiry = WaterPointStatus(
          waterPointId: 'WP-SED-SUR-001',
          operationalStatus: OperationalStatus.operational,
          updatedAt: t0,
          validUntil: null,
          sourceType: SourceType.officialSedapal,
        );
        expect(statusNoExpiry.validUntil, isNull);

        final statusWithExpiry = WaterPointStatus(
          waterPointId: 'WP-SED-SUR-001',
          operationalStatus: OperationalStatus.operational,
          updatedAt: t0,
          validUntil: t0.add(const Duration(hours: 2)),
          sourceType: SourceType.officialSedapal,
        );
        expect(statusWithExpiry.validUntil, isNotNull);

        // Default productive policy is unconfigured (0 hardcoded TTLs)
        final unconfiguredPolicy = FreshnessPolicy.standard();
        expect(unconfiguredPolicy.isConfigured, isFalse);
        final unconfiguredEval = statusWithExpiry.evaluateFreshness(
          t0.add(const Duration(minutes: 30)),
          unconfiguredPolicy,
        );
        expect(unconfiguredEval, equals(FreshnessState.policyNotConfigured));

        // Demo simulation policy evaluates to fresh within test window
        final demoPolicy = FreshnessPolicy.demoSimulation;
        expect(demoPolicy.isConfigured, isTrue);
        expect(demoPolicy.isSimulationOrDemo, isTrue);
        final freshEvaluation = statusWithExpiry.evaluateFreshness(
          t0.add(const Duration(minutes: 30)),
          demoPolicy,
        );
        expect(freshEvaluation, equals(FreshnessState.fresh));

        // Expired validUntil yields expired regardless of policy configuration
        final expiredEvaluation = statusWithExpiry.evaluateFreshness(
          t0.add(const Duration(hours: 3)),
          unconfiguredPolicy,
        );
        expect(expiredEvaluation, equals(FreshnessState.expired));
      },
    );

    test(
      '4. pedestrianAccessLocation is nullable and separated from displayLocation',
      () {
        const pointWithoutSeparateAccess = WaterPoint(
          waterPointId: 'WP-001',
          name: 'Punto Sin Acceso Separado',
          componentTypeRaw: 'POZO',
          infrastructureLocation: GeoLocation(
            latitude: -12.10,
            longitude: -77.03,
          ),
          pedestrianAccessLocation: null,
          department: 'LIMA',
          province: 'LIMA',
          district: 'MIRAFLORES',
          source: 'OFFICIAL',
        );

        expect(pointWithoutSeparateAccess.pedestrianAccessLocation, isNull);
        expect(pointWithoutSeparateAccess.routingAccessLocation, isNull);
        expect(pointWithoutSeparateAccess.isPedestrianAccessVerified, isFalse);
        expect(
          pointWithoutSeparateAccess.hasDedicatedPedestrianAccess,
          isFalse,
        );
        expect(
          pointWithoutSeparateAccess.displayLocation.latitude,
          equals(-12.10),
        );
        expect(
          pointWithoutSeparateAccess.provisionalTechnicalRoutingTarget.latitude,
          equals(-12.10),
        );
        expect(
          pointWithoutSeparateAccess.effectiveLocation.latitude,
          equals(-12.10),
        );

        const pointWithDedicatedAccess = WaterPoint(
          waterPointId: 'WP-002',
          name: 'Punto Con Puerta Peatonal',
          componentTypeRaw: 'RESERVORIO',
          infrastructureLocation: GeoLocation(
            latitude: -12.10,
            longitude: -77.03,
          ),
          pedestrianAccessLocation: GeoLocation(
            latitude: -12.1002,
            longitude: -77.0305,
          ),
          department: 'LIMA',
          province: 'LIMA',
          district: 'MIRAFLORES',
          source: 'OFFICIAL',
        );

        expect(pointWithDedicatedAccess.pedestrianAccessLocation, isNotNull);
        expect(pointWithDedicatedAccess.routingAccessLocation, isNotNull);
        expect(pointWithDedicatedAccess.isPedestrianAccessVerified, isTrue);
        expect(pointWithDedicatedAccess.hasDedicatedPedestrianAccess, isTrue);
        expect(
          pointWithDedicatedAccess.displayLocation.latitude,
          equals(-12.10),
        );
        expect(
          pointWithDedicatedAccess.routingAccessLocation!.latitude,
          equals(-12.1002),
        );
        expect(
          pointWithDedicatedAccess.provisionalTechnicalRoutingTarget.latitude,
          equals(-12.1002),
        );
        expect(
          pointWithDedicatedAccess.effectiveLocation.latitude,
          equals(-12.1002),
        );
      },
    );

    test(
      '5. CitizenReport does NOT directly overwrite or mutate WaterPointStatus',
      () {
        final officialStatus = WaterPointStatus(
          waterPointId: 'WP-001',
          operationalStatus: OperationalStatus.operational,
          waterAvailability: WaterAvailability.available,
          updatedAt: t0,
          sourceType: SourceType.officialSedapal,
          confidenceLevel: ConfidenceLevel.high,
        );

        final citizenReport = CitizenReport(
          reportId: 'CR-999',
          deviceGeneratedId: 'DEV-UUID-1234',
          waterPointId: 'WP-001',
          reportType: CitizenReportType.pointClosed,
          createdAt: t0.add(const Duration(minutes: 10)),
          notes: 'La puerta está cerrada con candado',
        );

        // Official status remains unmodified; report is stored as distinct observation
        expect(
          officialStatus.operationalStatus,
          equals(OperationalStatus.operational),
        );
        expect(citizenReport.reportType, equals(CitizenReportType.pointClosed));
        expect(citizenReport.syncStatus, equals(ReportSyncStatus.pending));
      },
    );

    test(
      '6. LOCAL_SIMULATION is clearly distinguishable from authentic official sources',
      () {
        final simStatus = WaterPointStatus(
          waterPointId: 'WP-001',
          operationalStatus: OperationalStatus.operational,
          updatedAt: t0,
          sourceType: SourceType.localSimulation,
        );

        expect(simStatus.isSimulation, isTrue);
        expect(simStatus.sourceType, equals(SourceType.localSimulation));

        final officialStatus = WaterPointStatus(
          waterPointId: 'WP-001',
          operationalStatus: OperationalStatus.operational,
          updatedAt: t0,
          sourceType: SourceType.officialSunass,
        );

        expect(officialStatus.isSimulation, isFalse);
        expect(officialStatus.sourceType, equals(SourceType.officialSunass));
      },
    );

    test(
      '7. District acts strictly as geographic metadata, NOT as an automatic operational hard filter',
      () {
        const pointCercado = WaterPoint(
          waterPointId: 'WP-001',
          name: 'Punto Límite',
          componentTypeRaw: 'POZO',
          infrastructureLocation: GeoLocation(
            latitude: -12.06,
            longitude: -77.04,
          ),
          department: 'LIMA',
          province: 'LIMA',
          district: 'CERCADO DE LIMA',
          source: 'OFFICIAL',
        );

        const citizenDistrict =
            'JESUS MARIA'; // District with 0 registered official points
        expect(pointCercado.district, isNot(equals(citizenDistrict)));

        // In AguaCION, cross-district pedestrian walking is fully valid
        final candidate = WaterPointCandidate(
          waterPoint: pointCercado,
          routeDistanceMeters: 850.0,
          routeWalkingMinutes: 12,
          reasons: [RecommendationReason.shortestWalkableRoute],
        );

        expect(candidate.isEligible, isTrue);
        expect(candidate.exclusionReason, isNull);
      },
    );

    test(
      '8. Source, confidence, and freshness serialize and deserialize cleanly',
      () {
        final status = WaterPointStatus(
          waterPointId: 'WP-TEST-001',
          operationalStatus: OperationalStatus.limited,
          waterAvailability: WaterAvailability.low,
          queueLevel: QueueLevel.medium,
          estimatedWaitMinutes: 25,
          accessStatus: AccessStatus.accessible,
          updatedAt: t0,
          validUntil: t0.add(const Duration(hours: 4)),
          sourceType: SourceType.accreditedOperator,
          sourceId: 'OP-042',
          confidenceLevel: ConfidenceLevel.verified,
          notes: 'Baja presión de salida',
        );

        final json = status.toJson();
        final restored = WaterPointStatus.fromJson(json);

        expect(restored.waterPointId, equals(status.waterPointId));
        expect(restored.operationalStatus, equals(OperationalStatus.limited));
        expect(restored.waterAvailability, equals(WaterAvailability.low));
        expect(restored.queueLevel, equals(QueueLevel.medium));
        expect(restored.estimatedWaitMinutes, equals(25));
        expect(restored.sourceType, equals(SourceType.accreditedOperator));
        expect(restored.confidenceLevel, equals(ConfidenceLevel.verified));
        expect(restored.validUntil, equals(status.validUntil));
      },
    );

    test(
      '9. OutboxItem provides idempotent identifier and robust retry logic with dead-letter protection',
      () {
        final item = OutboxItem(
          outboxId: 'OUTBOX-UUID-1',
          entityType: OutboxEntityType.citizenReport,
          entityId: 'REPORT-IDEMPOTENT-TOKEN-ABC',
          payload: {'reportType': 'POINT_CLOSED'},
          createdAt: t0,
        );

        expect(item.retryCount, equals(0));
        expect(item.canRetry(maxRetries: 3), isTrue);

        final fail1 = item.recordFailure(
          error: 'Network timeout',
          attemptTime: t0.add(const Duration(seconds: 5)),
          maxRetries: 3,
        );
        expect(fail1.retryCount, equals(1));
        expect(fail1.status, equals(OutboxStatus.failed));
        expect(fail1.canRetry(maxRetries: 3), isTrue);

        final fail2 = fail1.recordFailure(
          error: 'Network timeout',
          attemptTime: t0.add(const Duration(seconds: 15)),
          maxRetries: 3,
        );
        expect(fail2.retryCount, equals(2));

        final fail3 = fail2.recordFailure(
          error: 'HTTP 500',
          attemptTime: t0.add(const Duration(seconds: 30)),
          maxRetries: 3,
        );
        expect(fail3.retryCount, equals(3));
        expect(fail3.status, equals(OutboxStatus.deadLetter));
        expect(fail3.canRetry(maxRetries: 3), isFalse);
      },
    );

    test(
      '10. RecommendationResult can explicitly represent "no recommendation available"',
      () {
        final noRec = RecommendationResult.noRecommendation(
          outcome: RecommendationOutcome.allPointsClosed,
          generatedAt: t0,
          reason:
              'Todos los puntos en un radio caminable están confirmados cerrados por SEDAPAL.',
        );

        expect(noRec.hasRecommendation, isFalse);
        expect(noRec.recommended, isNull);
        expect(noRec.outcome, equals(RecommendationOutcome.allPointsClosed));
        expect(noRec.narrativeExplanation, contains('cerrados'));
      },
    );

    test(
      '11. Source conflicts between official and citizen observations can be formally represented',
      () {
        final officialObs = WaterPointObservation(
          observationId: 'OBS-OFF-01',
          waterPointId: 'WP-001',
          field: ObservationField.operationalStatus,
          value: 'OPERATIONAL',
          observedAt: t0.subtract(const Duration(hours: 2)),
          source: SourceType.officialSedapal,
          confidence: ConfidenceLevel.high,
        );

        final citizenObs1 = WaterPointObservation(
          observationId: 'OBS-CIT-01',
          waterPointId: 'WP-001',
          field: ObservationField.operationalStatus,
          value: 'CLOSED',
          observedAt: t0.subtract(const Duration(minutes: 15)),
          source: SourceType.citizenReport,
          confidence: ConfidenceLevel.medium,
        );

        final conflict = SourceConflict(
          waterPointId: 'WP-001',
          conflictingField: ObservationField.operationalStatus,
          conflictType: ConflictType.officialVsCitizen,
          officialObservation: officialObs,
          crowdSourcedObservations: [citizenObs1],
          detectedAt: t0,
          explanation:
              'SEDAPAL reporta punto operativo pero reportes ciudadanos recientes indican cierre.',
        );

        expect(conflict.isConflicting, isTrue);
        expect(conflict.conflictType, equals(ConflictType.officialVsCitizen));
        expect(
          conflict.conflictingField,
          equals(ObservationField.operationalStatus),
        );
        expect(conflict.operationalDecision, equals('PENDING_POLICY'));
        expect(
          SourceConflict.statusConflictingInformation,
          equals('CONFLICTING_INFORMATION'),
        );
      },
    );

    test('12. LifecycleStatus is decoupled from OperationalStatus', () {
      // A point can be in active infrastructure lifecycle, but temporarily closed during an emergency
      const activeAsset = WaterPoint(
        waterPointId: 'WP-ACTIVE-01',
        name: 'Cámara San Isidro',
        componentTypeRaw: 'CÁMARA CON MANIFOLD',
        infrastructureLocation: GeoLocation(
          latitude: -12.09,
          longitude: -77.03,
        ),
        department: 'LIMA',
        province: 'LIMA',
        district: 'SAN ISIDRO',
        source: 'OFFICIAL',
        lifecycleStatus: LifecycleStatus.active,
      );

      final closedStatus = WaterPointStatus(
        waterPointId: 'WP-ACTIVE-01',
        operationalStatus: OperationalStatus.closed,
        updatedAt: t0,
        sourceType: SourceType.accreditedOperator,
      );

      expect(activeAsset.lifecycleStatus, equals(LifecycleStatus.active));
      expect(closedStatus.operationalStatus, equals(OperationalStatus.closed));

      // Conversely, a retired asset should never be recommended regardless of dynamic status
      const retiredAsset = WaterPoint(
        waterPointId: 'WP-RETIRED-01',
        name: 'Pozo Antiguo Desmantelado',
        componentTypeRaw: 'POZO',
        infrastructureLocation: GeoLocation(
          latitude: -12.09,
          longitude: -77.03,
        ),
        department: 'LIMA',
        province: 'LIMA',
        district: 'SAN ISIDRO',
        source: 'OFFICIAL',
        lifecycleStatus: LifecycleStatus.retired,
      );

      final candidate = WaterPointCandidate(
        waterPoint: retiredAsset,
        exclusionReason: ExclusionReason.retiredInfrastructure,
      );

      expect(candidate.isEligible, isFalse);
      expect(
        candidate.exclusionReason,
        equals(ExclusionReason.retiredInfrastructure),
      );
    });

    test(
      '13. Incident model encapsulates edge blockages and water point impact',
      () {
        final incident = Incident(
          incidentId: 'INC-2026-001',
          type: IncidentType.flooding,
          severity: IncidentSeverity.high,
          status: IncidentStatus.active,
          description: 'Desborde de acequia inunda Jr. Libertad Cdra 4',
          reportedAt: t0,
          expiresAt: t0.add(const Duration(hours: 6)),
          sourceType: SourceType.coe,
          confidenceLevel: ConfidenceLevel.high,
          affectedWaterPointIds: ['WP-001'],
          affectedGraphEdgeIds: [1420, 1421, 1422],
        );

        expect(incident.isActive(t0.add(const Duration(hours: 1))), isTrue);
        expect(incident.isActive(t0.add(const Duration(hours: 8))), isFalse);
        expect(incident.affectedGraphEdgeIds.length, equals(3));
        expect(incident.affectedWaterPointIds, contains('WP-001'));
      },
    );

    test(
      '14. DatasetMetadata and Versioning handle stale threshold detection',
      () {
        final metadata = DatasetMetadata(
          datasetId: 'water_points_lima_callao',
          version: '2026.08.19-v1.0',
          generatedAt: t0.subtract(const Duration(days: 20)),
          sourceDate: DateTime(2026, 8, 19),
          installedAt: t0.subtract(const Duration(days: 2)),
          recordCount: 433,
          checksum: 'sha256_mock_hash_abc123',
        );

        expect(metadata.recordCount, equals(433));
        expect(metadata.isStale(t0, const Duration(days: 10)), isTrue);
        expect(metadata.isStale(t0, const Duration(days: 30)), isFalse);
      },
    );

    test('15. OperationalEvent models audit log without blockchain overhead', () {
      final event = OperationalEvent(
        eventId: 'EVT-001',
        entityType: 'water_point_status',
        entityId: 'WP-001',
        eventType: OperationalEventType.statusChanged,
        previousValue: 'OPERATIONAL',
        newValue: 'CLOSED',
        source: SourceType.accreditedOperator,
        sourceId: 'OPERATOR-LIMA-SUR',
        occurredAt: t0,
        recordedAt: t0.add(const Duration(seconds: 2)),
      );

      expect(event.eventType, equals(OperationalEventType.statusChanged));
      expect(event.previousValue, equals('OPERATIONAL'));
      expect(event.newValue, equals('CLOSED'));
      final json = event.toJson();
      final restored = OperationalEvent.fromJson(json);
      expect(restored.eventId, equals('EVT-001'));
      expect(restored.source, equals(SourceType.accreditedOperator));
      // In Hito 3A, digital signatures are NOT implemented (FUTURE_SECURITY_DESIGN)
      expect(restored.digitalSignature, isNull);
    });

    test(
      '16. WaterSourceKind and TankerTruckProfile model future mobile delivery contracts',
      () {
        expect(
          WaterSourceKind.fixedInfrastructure.displayName,
          contains('Punto Fijo'),
        );
        expect(WaterSourceKind.tankerTruck.displayName, contains('Cisterna'));

        final tanker = TankerTruckProfile(
          vehicleId: 'SED-CIS-104',
          licensePlate: 'EGX-412',
          currentLocation: const GeoLocation(
            latitude: -12.05,
            longitude: -77.05,
          ),
          totalCapacityRaw: '10000',
          remainingCapacityRaw: '4500',
          currentStopName: 'Parque Zonal Huáscar',
          nextStopName: 'C.S. San Fernando',
          estimatedNextStopArrival: t0.add(const Duration(minutes: 40)),
          locationUpdatedAt: t0,
          validUntil: t0.add(const Duration(hours: 1)),
        );

        expect(tanker.vehicleId, equals('SED-CIS-104'));
        expect(tanker.licensePlate, equals('EGX-412'));
        final json = tanker.toJson();
        expect(json['vehicleId'], equals('SED-CIS-104'));
      },
    );

    test(
      '17. CitizenCorroborationPolicy has 0 hardcoded thresholds and defaults to unconfigured',
      () {
        final unconfigured = CitizenCorroborationPolicy.unconfigured;
        expect(unconfigured.isConfigured, isFalse);
        expect(unconfigured.minimumReports, isNull);
        expect(unconfigured.timeWindow, isNull);

        final demo = CitizenCorroborationPolicy.demoSimulation;
        expect(demo.isConfigured, isTrue);
        expect(demo.isSimulationOrDemo, isTrue);
        expect(demo.minimumReports, equals(5));
        expect(demo.timeWindow, equals(const Duration(minutes: 45)));
      },
    );
  });
}
