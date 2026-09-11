/// Models physical accessibility characteristics of a water point's surroundings.
///
/// NOTE: Every single attribute is nullable to represent UNKNOWN explicitly.
/// Under zero circumstances should an algorithm or UI assume wheelchair accessibility
/// or smooth terrain if empirical data has not been recorded.
class AccessibilityInfo {
  final bool? wheelchairAccessible;
  final bool? hasStairs;
  final String? surfaceType;
  final double? slopeDegree;
  final String? notes;

  const AccessibilityInfo({
    this.wheelchairAccessible,
    this.hasStairs,
    this.surfaceType,
    this.slopeDegree,
    this.notes,
  });

  /// True if any accessibility attribute is verified and known.
  bool get hasAnyKnownData =>
      wheelchairAccessible != null ||
      hasStairs != null ||
      surfaceType != null ||
      slopeDegree != null;

  AccessibilityInfo copyWith({
    bool? wheelchairAccessible,
    bool? hasStairs,
    String? surfaceType,
    double? slopeDegree,
    String? notes,
  }) {
    return AccessibilityInfo(
      wheelchairAccessible: wheelchairAccessible ?? this.wheelchairAccessible,
      hasStairs: hasStairs ?? this.hasStairs,
      surfaceType: surfaceType ?? this.surfaceType,
      slopeDegree: slopeDegree ?? this.slopeDegree,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    if (wheelchairAccessible != null)
      'wheelchairAccessible': wheelchairAccessible,
    if (hasStairs != null) 'hasStairs': hasStairs,
    if (surfaceType != null) 'surfaceType': surfaceType,
    if (slopeDegree != null) 'slopeDegree': slopeDegree,
    if (notes != null) 'notes': notes,
  };

  factory AccessibilityInfo.fromJson(Map<String, dynamic> json) {
    return AccessibilityInfo(
      wheelchairAccessible: json['wheelchairAccessible'] as bool?,
      hasStairs: json['hasStairs'] as bool?,
      surfaceType: json['surfaceType'] as String?,
      slopeDegree: (json['slopeDegree'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
    );
  }
}
