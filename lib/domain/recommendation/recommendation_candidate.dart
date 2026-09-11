import '../water/water_point.dart';
import '../water/water_point_status.dart';
import '../source/freshness.dart';
import '../source/confidence_level.dart';
import 'recommendation_reason.dart';

/// Represents an evaluated water point candidate within the recommendation pipeline.
///
/// Contains the base infrastructure details, any available live operational status,
/// calculated pedestrian routing metrics, freshness evaluation, and explainability tags.
class WaterPointCandidate {
  /// The underlying immutable infrastructure asset.
  final WaterPoint waterPoint;

  /// The dynamic operational status evaluated at query time, if available.
  final WaterPointStatus? status;

  /// Real walking distance in meters computed via pedestrian A* routing.
  final double? routeDistanceMeters;

  /// Estimated walking duration in minutes at standard walking pace (e.g. 4.0 km/h).
  final int? routeWalkingMinutes;

  /// Evaluated freshness of the operational data.
  final FreshnessState freshness;

  /// Source trust / confidence level of the operational data.
  final ConfidenceLevel confidence;

  /// Justification reasons explaining why this candidate was scored or selected.
  final List<RecommendationReason> reasons;

  /// Non-fatal warnings associated with this point (e.g. aging data, moderate queue).
  final List<String> warnings;

  /// Reason for exclusion, if the candidate failed a hard filter.
  final ExclusionReason? exclusionReason;

  const WaterPointCandidate({
    required this.waterPoint,
    this.status,
    this.routeDistanceMeters,
    this.routeWalkingMinutes,
    this.freshness = FreshnessState.unknown,
    this.confidence = ConfidenceLevel.unknown,
    this.reasons = const [],
    this.warnings = const [],
    this.exclusionReason,
  });

  /// True if this candidate is physically reachable and passed all hard filters.
  bool get isEligible => exclusionReason == null && routeDistanceMeters != null;

  /// True if live operational status has been confirmed open or available.
  bool get hasConfirmedAvailability => status?.isPotentiallyOpen == true;

  Map<String, dynamic> toJson() => {
    'waterPoint': waterPoint.toJson(),
    if (status != null) 'status': status!.toJson(),
    if (routeDistanceMeters != null) 'routeDistanceMeters': routeDistanceMeters,
    if (routeWalkingMinutes != null) 'routeWalkingMinutes': routeWalkingMinutes,
    'freshness': freshness.name,
    'confidence': confidence.name,
    'reasons': reasons.map((r) => r.name).toList(),
    'warnings': warnings,
    if (exclusionReason != null) 'exclusionReason': exclusionReason!.name,
  };
}
