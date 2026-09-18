import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../data/models/water_point.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/operational_chips.dart';
import 'point_detail_sheet.dart';

enum PointFilterType { all, cisterna, pileta, surtidor }

class PointsTab extends StatefulWidget {
  const PointsTab({super.key});

  @override
  State<PointsTab> createState() => _PointsTabState();
}

class _PointsTabState extends State<PointsTab> {
  String _searchTerm = '';
  PointFilterType _filter = PointFilterType.all;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<WaterPoint> _filterPoints(List<WaterPoint> points) {
    return points.where((p) {
      final matchesSearch =
          p.n.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          p.sector.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          p.ref.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          p.tipo.label.toLowerCase().contains(_searchTerm.toLowerCase());

      if (!matchesSearch) return false;

      switch (_filter) {
        case PointFilterType.all:
          return true;
        case PointFilterType.cisterna:
          return p.tipo == PointType.cisterna;
        case PointFilterType.pileta:
          return p.tipo == PointType.pileta;
        case PointFilterType.surtidor:
          return p.tipo == PointType.surtidor || p.tipo == PointType.pozo;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();

    // If catalog is explicitly unavailable
    if (state.catalogStatus == CatalogStatus.unavailable) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.databaseZap,
                size: 44,
                color: AppColors.warningAmber,
              ),
              const SizedBox(height: 14),
              const Text(
                'Catálogo local no disponible en esta instalación.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'El archivo local de puntos oficiales de Lima y Callao no fue detectado en el dispositivo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: AppColors.slate600),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => state.loadCatalog(),
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final allPoints = state.points;
    final filteredPoints = _filterPoints(allPoints);

    // Limit display to top 20 nearest when not searching, or show all filtered
    final displayPoints = _searchTerm.isEmpty && _filter == PointFilterType.all
        ? filteredPoints.take(20).toList()
        : filteredPoints;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        // Demo Simulation Banner if emergency mode is active
        if (state.isEmergency) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.softAmber,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderAmber),
            ),
            child: const Row(
              children: [
                Icon(
                  LucideIcons.shieldAlert,
                  size: 16,
                  color: AppColors.darkAmber,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ESTADO DE CONTINGENCIA: Red de distribución de emergencia activa.',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkAmber,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Search Bar
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.slate200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchTerm = val),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Buscar distrito, parque o punto...',
              hintStyle: const TextStyle(
                fontSize: 13,
                color: AppColors.slate400,
              ),
              prefixIcon: const Icon(
                LucideIcons.search,
                size: 18,
                color: AppColors.slate400,
              ),
              suffixIcon: _searchTerm.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        LucideIcons.x,
                        size: 16,
                        color: AppColors.slate500,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchTerm = '');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 14,
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Type Filter Chips Bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'Todos (${allPoints.length})',
                isSelected: _filter == PointFilterType.all,
                onTap: () => setState(() => _filter = PointFilterType.all),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Cisternas',
                isSelected: _filter == PointFilterType.cisterna,
                onTap: () => setState(() => _filter = PointFilterType.cisterna),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Piletas',
                isSelected: _filter == PointFilterType.pileta,
                onTap: () => setState(() => _filter = PointFilterType.pileta),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Pozos / PTAP',
                isSelected: _filter == PointFilterType.surtidor,
                onTap: () => setState(() => _filter = PointFilterType.surtidor),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Results summary header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'PUNTOS DE ABASTECIMIENTO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate500,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _searchTerm.isEmpty && _filter == PointFilterType.all
                    ? '${displayPoints.length} más cercanos (${allPoints.length} reg.)'
                    : '${filteredPoints.length} encontrados',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate500,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Point cards list
        if (displayPoints.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            alignment: Alignment.center,
            child: const Column(
              children: [
                Icon(LucideIcons.searchX, color: AppColors.slate400, size: 40),
                SizedBox(height: 12),
                Text(
                  'No se encontraron puntos de agua',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Intenta cambiar el texto de búsqueda o el tipo de punto.',
                  style: TextStyle(fontSize: 12, color: AppColors.slate500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...displayPoints.map((point) {
            return _PointCard(
              point: point,
              onTap: () {
                state.selectPoint(point);
                PointDetailSheet.show(
                  context,
                  point: point,
                  isEmergency: state.isEmergency,
                  onReportTapped: () => state.setActiveTab(AppTab.reportar),
                );
              },
              onViewOnMap: () {
                state.selectPointAndNavigateToMap(point);
              },
            );
          }),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.sunassBlue : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.sunassBlue : AppColors.slate200,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.sunassBlue.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AppColors.white : AppColors.slate700,
          ),
        ),
      ),
    );
  }
}

class _PointCard extends StatelessWidget {
  final WaterPoint point;
  final VoidCallback onTap;
  final VoidCallback onViewOnMap;

  const _PointCard({
    required this.point,
    required this.onTap,
    required this.onViewOnMap,
  });

  @override
  Widget build(BuildContext context) {
    final dist = point.distMeters;
    final bool isApproximate = point.isDistanceApproximate;

    final String distLabel;
    final String timeLabel;

    if (dist == null) {
      distLabel = '--';
      timeLabel = 'Sin ubicación';
    } else if (isApproximate) {
      // Honest geodetic approximation: NEVER claim walking time
      if (dist >= 1000) {
        distLabel = '~${(dist / 1000).toStringAsFixed(1)} km';
      } else {
        distLabel = '~$dist m';
      }
      timeLabel = 'Distancia aprox.';
    } else {
      // Exact routed pedestrian distance and time
      distLabel = GeoUtils.formatDistance(dist);
      timeLabel = '≈ ${GeoUtils.formatWalkingTime(dist)}';
    }

    final typeLabel = switch (point.tipo) {
      PointType.cisterna => 'CISTERNA',
      PointType.pileta => 'PILETA',
      PointType.surtidor => 'SURTIDOR',
      PointType.pozo => 'POZO',
      PointType.noEspecificado =>
        point.componentTypeRaw != null && point.componentTypeRaw!.isNotEmpty
            ? point.componentTypeRaw!.toUpperCase()
            : 'NO ESPECIFICADO',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Type tag & Distance badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.slate100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    typeLabel,
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.slate700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  point.sector,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.slate500,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            point.n,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (point.ref.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              point.ref,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.slate600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.slate50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            distLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: AppColors.slate900,
                            ),
                          ),
                          Text(
                            timeLabel,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: isApproximate
                                  ? AppColors.slate500
                                  : AppColors.darkGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(color: AppColors.slate100, height: 1),
                const SizedBox(height: 10),

                // Bottom strip: Honest operational chips + View on Map button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          OperationalStatusChip(
                            statusText: point.estETxt.isNotEmpty
                                ? point.estETxt
                                : 'Estado no confirmado',
                            isConfirmed: point.estE == EmergencyStatus.ok,
                          ),
                          SourceChip(
                            sourceLabel: point.estN.isNotEmpty
                                ? point.estN
                                : 'Catálogo local',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onViewOnMap,
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Ver en mapa',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.sunassBlue,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(
                              LucideIcons.chevronRight,
                              size: 14,
                              color: AppColors.sunassBlue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
