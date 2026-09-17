import "package:flutter/material.dart";
import "package:lucide_icons_flutter/lucide_icons.dart";
import "../../../../core/constants/app_colors.dart";
import "../../../widgets/operational_chips.dart";

class WaterPointMapSheet extends StatelessWidget {
  final Map<String, dynamic> pointData;
  final bool hasActiveRoute;
  final String? routeDistance;
  final String? routeDuration;
  final VoidCallback onCalculateRoute;
  final VoidCallback onRecenter;
  final VoidCallback onClearRoute;
  final VoidCallback onClose;
  final bool isEmergency;

  const WaterPointMapSheet({
    super.key,
    required this.pointData,
    required this.hasActiveRoute,
    this.routeDistance,
    this.routeDuration,
    required this.onCalculateRoute,
    required this.onRecenter,
    required this.onClearRoute,
    required this.onClose,
    this.isEmergency = false,
  });

  @override
  Widget build(BuildContext context) {
    final pointId = pointData["water_point_id"]?.toString() ?? "";
    final district = pointData["district"]?.toString() ?? "";
    final location = pointData["location_description"]?.toString() ?? "";
    final tipo = pointData["point_type"]?.toString() ?? "PUNTO";

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: AppColors.slate200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Eyebrow + Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.sunassNavy,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        pointId.isNotEmpty ? pointId : "PUNTO",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tipo.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    LucideIcons.x,
                    size: 18,
                    color: AppColors.slate400,
                  ),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Point Title & District
            Text(
              district.isNotEmpty ? "$district — $tipo" : tipo,
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
                color: AppColors.slate900,
                letterSpacing: -0.2,
              ),
            ),
            if (location.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                location,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.slate600,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),

            // Honest Operational Chips
            const Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                OperationalStatusChip(statusText: "Estado no confirmado"),
                SourceChip(sourceLabel: "Catálogo local"),
              ],
            ),

            // 48h Post-Disaster Update Disclaimer
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.slate200),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.clockAlert,
                    size: 14,
                    color: Color(0xFF0284C7),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Actualización operativa: La habilitación física en campo de este punto será confirmada por los equipos técnicos en un plazo máximo de 48 horas tras ocurrida la emergencia.",
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.slate600,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Distance & Estimated Walk Time if route active
            if (hasActiveRoute && routeDistance != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.softGreen,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderGreen),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.footprints,
                      size: 16,
                      color: AppColors.darkGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Ruta peatonal estimada: ",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkGreen,
                              ),
                            ),
                            TextSpan(
                              text: "$routeDistance  •  ${routeDuration ?? ''}",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: AppColors.slate900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Calculada según el grafo peatonal y la información cartográfica disponible.",
                style: TextStyle(
                  fontSize: 10.5,
                  color: AppColors.slate500,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Action Buttons
            if (!hasActiveRoute) ...[
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: onCalculateRoute,
                  icon: const Icon(LucideIcons.navigation, size: 18),
                  label: const Text(
                    "CALCULAR RUTA PEATONAL",
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sunassBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: OutlinedButton.icon(
                        onPressed: onRecenter,
                        icon: const Icon(LucideIcons.locateFixed, size: 16),
                        label: const Text(
                          "RECENTRAR",
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.sunassNavy,
                          side: const BorderSide(color: AppColors.slate300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: OutlinedButton.icon(
                        onPressed: onClearRoute,
                        icon: const Icon(LucideIcons.x, size: 16),
                        label: const Text(
                          "DESPEJAR",
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.slate700,
                          side: const BorderSide(color: AppColors.slate300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
