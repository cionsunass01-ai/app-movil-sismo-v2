import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../data/models/water_point.dart';
import '../../providers/app_state_provider.dart';
import 'point_detail_sheet.dart';

enum FilterType {
  all,
  conAgua,
  cisterna,
  pileta,
  surtidor,
}

class PointsTab extends StatefulWidget {
  const PointsTab({super.key});

  @override
  State<PointsTab> createState() => _PointsTabState();
}

class _PointsTabState extends State<PointsTab> {
  String _searchTerm = '';
  FilterType _filter = FilterType.all;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<WaterPoint> _filterPoints(List<WaterPoint> points, bool isEmergency) {
    return points.where((p) {
      final matchesSearch = p.n.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          p.sector.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          p.ref.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          p.tipo.label.toLowerCase().contains(_searchTerm.toLowerCase());

      if (!matchesSearch) return false;

      switch (_filter) {
        case FilterType.all:
          return true;
        case FilterType.conAgua:
          return isEmergency ? p.estE == EmergencyStatus.ok : true;
        case FilterType.cisterna:
          return p.tipo == PointType.cisterna;
        case FilterType.pileta:
          return p.tipo == PointType.pileta;
        case FilterType.surtidor:
          return p.tipo == PointType.surtidor || p.tipo == PointType.pozo;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final allPoints = state.points;
    final filteredPoints = _filterPoints(allPoints, state.isEmergency);

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      children: [
        // Sismo Stat Card
        if (state.isEmergency) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${state.activePointsCount} ',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.slate900,
                            ),
                          ),
                          TextSpan(
                            text: 'de ${allPoints.length} puntos',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Puntos con agua activa ahora mismo en la ciudad',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.slate600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.softGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.droplet, color: AppColors.safeGreen, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Search bar
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.slate200),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchTerm = val),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Buscar parque, sector, cisterna...',
              hintStyle: const TextStyle(fontSize: 12, color: AppColors.slate400),
              prefixIcon: const Icon(LucideIcons.search, size: 16, color: AppColors.slate400),
              suffixIcon: _searchTerm.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, size: 16, color: AppColors.slate500),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchTerm = '');
                      },
                    )
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Filter chips bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'Todos (${allPoints.length})',
                isSelected: _filter == FilterType.all,
                onTap: () => setState(() => _filter = FilterType.all),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Con agua (${state.activePointsCount})',
                isSelected: _filter == FilterType.conAgua,
                isHighlight: true,
                onTap: () => setState(() => _filter = FilterType.conAgua),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Cisternas',
                isSelected: _filter == FilterType.cisterna,
                onTap: () => setState(() => _filter = FilterType.cisterna),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Piletas',
                isSelected: _filter == FilterType.pileta,
                onTap: () => setState(() => _filter = FilterType.pileta),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Pozos / PTAP',
                isSelected: _filter == FilterType.surtidor,
                onTap: () => setState(() => _filter = FilterType.surtidor),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Subheader
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ORDENADOS POR CERCANÍA A TU UBICACIÓN',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: AppColors.slate500,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              '${filteredPoints.length} resultados',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.slate500,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // List of point cards
        if (filteredPoints.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            alignment: Alignment.center,
            child: const Column(
              children: [
                Icon(LucideIcons.searchX, color: AppColors.slate400, size: 36),
                SizedBox(height: 10),
                Text(
                  'No se encontraron puntos de agua',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slate700),
                ),
                SizedBox(height: 4),
                Text(
                  'Intenta cambiar los filtros o el término de búsqueda.',
                  style: TextStyle(fontSize: 11, color: AppColors.slate500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...filteredPoints.map((point) {
            return _PointCard(
              point: point,
              isEmergency: state.isEmergency,
              onTap: () {
                state.selectPoint(point);
                PointDetailSheet.show(
                  context,
                  point: point,
                  isEmergency: state.isEmergency,
                  onReportTapped: () => state.setActiveTab(AppTab.reportar),
                );
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
  final bool isHighlight;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.isHighlight = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.white;
    Color border = AppColors.slate200;
    Color text = AppColors.slate600;

    if (isSelected) {
      if (isHighlight) {
        bg = AppColors.safeGreen;
        border = AppColors.safeGreen;
        text = AppColors.white;
      } else {
        bg = AppColors.slate900;
        border = AppColors.slate900;
        text = AppColors.white;
      }
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: text,
          ),
        ),
      ),
    );
  }
}

class _PointCard extends StatelessWidget {
  final WaterPoint point;
  final bool isEmergency;
  final VoidCallback onTap;

  const _PointCard({
    required this.point,
    required this.isEmergency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dist = point.distMeters ?? 0;
    final formattedDist = GeoUtils.formatDistance(dist);
    final walkTime = GeoUtils.formatWalkingTime(dist);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Type, Sector, Distance Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.slate100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  point.tipo.label.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.slate700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  point.sector,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.slate500,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            point.n,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            point.ref,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.slate500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.slate50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formattedDist,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: AppColors.slate900,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Text(
                            walkTime,
                            style: const TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                const Divider(color: AppColors.slate100, height: 1),
                const SizedBox(height: 6),

                // Bottom strip: status badge & verification date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CardStatusBadge(point: point, isEmergency: isEmergency),
                    Row(
                      children: [
                        Text(
                          'Verificado: ${point.ver}',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: point.verMeses > 6 ? AppColors.darkAmber : AppColors.slate500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(LucideIcons.chevronRight, size: 12, color: AppColors.slate400),
                      ],
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

class _CardStatusBadge extends StatelessWidget {
  final WaterPoint point;
  final bool isEmergency;

  const _CardStatusBadge({required this.point, required this.isEmergency});

  @override
  Widget build(BuildContext context) {
    if (!isEmergency) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.softBlue,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.borderBlue),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.checkCircle2, color: AppColors.accentBlue, size: 10),
            const SizedBox(width: 4),
            Text(
              point.estN,
              style: const TextStyle(
                color: Color(0xFF1E40AF),
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    final isSafe = point.estE == EmergencyStatus.ok;
    final isWarn = point.estE == EmergencyStatus.warn;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isSafe
            ? AppColors.softGreen
            : isWarn
                ? AppColors.softAmber
                : AppColors.softRed,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSafe
              ? AppColors.borderGreen
              : isWarn
                  ? AppColors.borderAmber
                  : AppColors.borderRed,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSafe
                ? LucideIcons.droplet
                : isWarn
                    ? LucideIcons.alertTriangle
                    : LucideIcons.alertTriangle,
            color: isSafe
                ? AppColors.safeGreen
                : isWarn
                    ? AppColors.warningAmber
                    : AppColors.primaryRed,
            size: 10,
          ),
          const SizedBox(width: 4),
          Text(
            point.estETxt,
            style: TextStyle(
              color: isSafe
                  ? AppColors.darkGreen
                  : isWarn
                      ? AppColors.darkAmber
                      : AppColors.darkRed,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
