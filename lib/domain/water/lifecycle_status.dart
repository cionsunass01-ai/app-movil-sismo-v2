/// Represents the lifecycle status of a registered water point infrastructure.
///
/// Note: This represents the administrative lifecycle of the asset itself,
/// completely separated from the temporal operational status (open, closed,
/// water available, etc.) during an emergency.
enum LifecycleStatus {
  /// The infrastructure is officially registered, recognized, and in active service catalog.
  active,

  /// The infrastructure was present in an earlier source delivery but is missing
  /// from the latest delivery. It is NOT automatically retired without verification.
  missingFromLatestSource,

  /// The infrastructure record has flagged inconsistencies (e.g. location discrepancy)
  /// and is awaiting technical review.
  pendingReview,

  /// The infrastructure has been officially decommissioned or confirmed invalid by SUNASS/SEDAPAL.
  retired;

  String get displayName {
    switch (this) {
      case LifecycleStatus.active:
        return 'Activo en Catálogo';
      case LifecycleStatus.missingFromLatestSource:
        return 'No Listado en Última Entrega';
      case LifecycleStatus.pendingReview:
        return 'Pendiente de Revisión Técnica';
      case LifecycleStatus.retired:
        return 'Retirado / Desmantelado';
    }
  }

  static LifecycleStatus fromString(String? value) {
    if (value == null) return LifecycleStatus.active;
    switch (value.trim().toUpperCase()) {
      case 'ACTIVE':
      case 'ACTIVO':
        return LifecycleStatus.active;
      case 'MISSING_FROM_LATEST_SOURCE':
      case 'NO_LISTADO':
        return LifecycleStatus.missingFromLatestSource;
      case 'PENDING_REVIEW':
      case 'PENDIENTE_REVISION':
        return LifecycleStatus.pendingReview;
      case 'RETIRED':
      case 'RETIRADO':
        return LifecycleStatus.retired;
      default:
        return LifecycleStatus.active;
    }
  }
}
