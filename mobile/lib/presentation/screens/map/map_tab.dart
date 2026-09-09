import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/geo_utils.dart';
import '../../providers/app_state_provider.dart';
import '../points/point_detail_sheet.dart';
import 'widgets/vector_map_painter.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  bool _showRoute = true;
  String? _selectedPointId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final nearestPoint = state.nearestPoint;

    return Column(
      children: [
        // Map Top Bar Controls
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(bottom: BorderSide(color: AppColors.slate200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(LucideIcons.map, size: 15, color: AppColors.sunassBlue),
                  SizedBox(width: 6),
                  Text(
                    'Cartografía Vectorial Offline',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate900,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => setState(() => _showRoute = !_showRoute),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _showRoute ? AppColors.softGreen : AppColors.slate100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _showRoute ? AppColors.borderGreen : AppColors.slate300,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (_showRoute)
                        const Icon(LucideIcons.check, size: 11, color: AppColors.darkGreen),
                      if (_showRoute) const SizedBox(width: 4),
                      Text(
                        _showRoute ? 'Ruta a pie activa' : 'Mostrar ruta a pie',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _showRoute ? AppColors.darkGreen : AppColors.slate700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Interactive Map Canvas Area
        Expanded(
          child: Stack(
            children: [
              // Vector Map Interactive Canvas
              Positioned.fill(
                child: InteractiveViewer(
                  boundaryMargin: const EdgeInsets.all(50),
                  minScale: 0.8,
                  maxScale: 3.0,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: VectorMapPainter(
                      points: state.points,
                      isEmergency: state.isEmergency,
                      showRoute: _showRoute,
                      activePointId: _selectedPointId,
                    ),
                  ),
                ),
              ),

              // Floating Bottom Card (Nearest Point Focus)
              if (nearestPoint != null)
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.slate300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: AppColors.safeGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      nearestPoint.n,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.slate900,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.softGreen,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${GeoUtils.formatDistance(nearestPoint.distMeters ?? 0)} • ${GeoUtils.formatWalkingTime(nearestPoint.distMeters ?? 0)}',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.darkGreen,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${nearestPoint.ref} • ${nearestPoint.tipo.label} (${nearestPoint.horario})',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.slate600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Divider(color: AppColors.slate100, height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () {
                                state.selectPoint(nearestPoint);
                                PointDetailSheet.show(
                                  context,
                                  point: nearestPoint,
                                  isEmergency: state.isEmergency,
                                  onReportTapped: () => state.setActiveTab(AppTab.reportar),
                                );
                              },
                              child: const Row(
                                children: [
                                  Text(
                                    'Abrir ficha técnica completa',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.sunassBlue,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(LucideIcons.chevronRight, size: 12, color: AppColors.sunassBlue),
                                ],
                              ),
                            ),
                            const Text(
                              'Cruce seguro CENEPRED',
                              style: TextStyle(
                                fontSize: 9.5,
                                color: AppColors.slate500,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Map Legend Bottom Strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(top: BorderSide(color: AppColors.slate200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _legendItem(color: AppColors.safeGreen, label: 'Con agua'),
              _legendItem(color: AppColors.sunassBlue, label: 'Pileta fija'),
              _legendItem(color: AppColors.primaryRed, label: 'Sin agua / Falla'),
              _legendItem(color: AppColors.slate900, label: 'Tu ubicación'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legendItem({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.slate600),
        ),
      ],
    );
  }
}
