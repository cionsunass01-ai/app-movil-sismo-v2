import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../data/models/water_point.dart';

class PointDetailSheet extends StatelessWidget {
  final WaterPoint point;
  final bool isEmergency;
  final VoidCallback onReportTapped;

  const PointDetailSheet({
    super.key,
    required this.point,
    required this.isEmergency,
    required this.onReportTapped,
  });

  static void show(
    BuildContext context, {
    required WaterPoint point,
    required bool isEmergency,
    required VoidCallback onReportTapped,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PointDetailSheet(
        point: point,
        isEmergency: isEmergency,
        onReportTapped: onReportTapped,
      ),
    );
  }

  void _sharePointInfo(BuildContext context) {
    final dist = point.distMeters;
    final String distText;
    if (dist == null) {
      distText = 'Distancia: No disponible';
    } else if (point.isDistanceApproximate) {
      distText = 'Distancia aprox.: ${GeoUtils.formatDistance(dist)}';
    } else {
      distText =
          'Distancia por ruta: ${GeoUtils.formatDistance(dist)} (≈ ${GeoUtils.formatWalkingTime(dist)})';
    }

    final buffer = StringBuffer();
    buffer.writeln('Punto de Agua AguaCION: ${point.n} (${point.sector})');
    if (point.ref.isNotEmpty) buffer.writeln('Ubicación: ${point.ref}');
    if (point.horario != null && point.horario!.isNotEmpty) {
      buffer.writeln('Horario: ${point.horario}');
    }
    if (point.cap != null && point.cap!.isNotEmpty) {
      buffer.writeln('Capacidad: ${point.cap}');
    }
    if (point.calidad != null) {
      buffer.writeln('Calidad: ${point.calidad!.label}');
    }
    buffer.write(distText);

    SharePlus.instance.share(
      ShareParams(
        text: buffer.toString(),
        subject: 'Punto de Abastecimiento - ${point.n}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dist = point.distMeters;
    final String formattedDist = dist != null
        ? GeoUtils.formatDistance(dist)
        : '--';
    final String walkTime = dist != null
        ? GeoUtils.formatWalkingTime(dist)
        : '--';
    final String distanceLabel;
    if (dist == null) {
      distanceLabel = '📍 Distancia no disponible';
    } else if (point.isDistanceApproximate) {
      distanceLabel = '📍 Distancia aprox.: $formattedDist';
    } else {
      distanceLabel = '📍 Distancia por ruta: $formattedDist • ≈ $walkTime';
    }

    // Prepare dynamic spec cards only for fields supported with actual data
    final List<Widget> specCards = [];
    if (point.horario != null && point.horario!.isNotEmpty) {
      specCards.add(
        _SpecCard(
          icon: LucideIcons.clock,
          iconColor: AppColors.slate700,
          title: 'HORARIO',
          value: point.horario!,
          subtitle: 'Turno de reparto',
        ),
      );
    }
    if (point.cap != null && point.cap!.isNotEmpty) {
      final bool hasKnownUnit =
          point.capacityUnit != null &&
          point.capacityUnit!.isNotEmpty &&
          point.capacityUnit != 'UNKNOWN';
      specCards.add(
        _SpecCard(
          icon: LucideIcons.droplet,
          iconColor: AppColors.accentBlue,
          title: 'CAPACIDAD',
          value: point.cap!,
          subtitle: hasKnownUnit ? 'Por viaje/ciclo' : 'Unidad no confirmada',
        ),
      );
    }
    if (point.recarga != null && point.recarga!.isNotEmpty) {
      specCards.add(
        _SpecCard(
          icon: LucideIcons.truck,
          iconColor: AppColors.warningAmber,
          title: 'FUENTE DE RECARGA',
          value: point.recarga!,
          subtitle: 'Red troncal',
        ),
      );
    }
    if (point.pobl != null && point.pobl! > 0) {
      specCards.add(
        _SpecCard(
          icon: LucideIcons.users,
          iconColor: AppColors.safeGreen,
          title: 'POBLACIÓN ASIGNADA',
          value: '${point.pobl} hab.',
          subtitle: 'Radio de cobertura',
        ),
      );
    }

    // Prepare metadata rows only for verified info
    final List<Widget> metaRows = [];
    if (point.acceso != null && point.acceso!.isNotEmpty) {
      metaRows.add(
        _MetaRow(
          label: 'Accesibilidad de Vía:',
          value: point.pend != null && point.pend!.isNotEmpty
              ? '${point.acceso} (${point.pend})'
              : point.acceso!,
        ),
      );
    }
    if (point.resp != null && point.resp!.isNotEmpty) {
      if (metaRows.isNotEmpty) {
        metaRows.add(const Divider(color: AppColors.slate100, height: 16));
      }
      metaRows.add(_MetaRow(label: 'Entidad Responsable:', value: point.resp!));
    }
    if (point.ver != null && point.ver!.isNotEmpty) {
      if (metaRows.isNotEmpty) {
        metaRows.add(const Divider(color: AppColors.slate100, height: 16));
      }
      metaRows.add(
        _MetaRow(
          label: 'Verificación en Campo:',
          value: (point.verMeses != null && point.verMeses! > 0)
              ? '${point.ver} (hace ${point.verMeses} meses)'
              : '${point.ver} (vigente)',
          valueColor: (point.verMeses ?? 0) > 6
              ? AppColors.darkAmber
              : AppColors.darkGreen,
        ),
      );
    }
    if (point.validFrom != null && point.validFrom!.isNotEmpty) {
      if (metaRows.isNotEmpty) {
        metaRows.add(const Divider(color: AppColors.slate100, height: 16));
      }
      metaRows.add(
        _MetaRow(label: 'Fecha Catálogo / Fuente:', value: point.validFrom!),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.slate300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header with gradient
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.slate900, AppColors.slate950],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryRed,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            point.id,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          point.tipo.label,
                          style: const TextStyle(
                            color: AppColors.slate300,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.x,
                        color: AppColors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  point.n,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                if (point.ref.isNotEmpty || point.sector.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.mapPin,
                        color: Color(0xFFF87171),
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          point.ref.isNotEmpty
                              ? '${point.ref} • ${point.sector}'
                              : point.sector,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.slate300,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    _StatusBadge(point: point, isEmergency: isEmergency),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.slate800,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        distanceLabel,
                        style: const TextStyle(
                          color: AppColors.slate200,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Scrollable Body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quality Banner
                  _buildQualityBanner(point),

                  // Technical Specs Grid (only if specs exist)
                  if (specCards.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    GridView.count(
                      crossAxisCount: specCards.length == 1 ? 1 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: specCards.length == 1 ? 3.2 : 1.6,
                      children: specCards,
                    ),
                  ],

                  // Access and verification box (only if meta exists)
                  if (metaRows.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: Column(children: metaRows),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom Action Buttons
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: AppColors.slate200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onReportTapped();
                    },
                    icon: const Icon(
                      LucideIcons.messageSquare,
                      size: 15,
                      color: AppColors.warningAmber,
                    ),
                    label: const Text(
                      'Reportar Falla',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate800,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.slate300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: () => _sharePointInfo(context),
                  icon: const Icon(LucideIcons.share2, size: 18),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.navigation, size: 15),
                    label: const Text(
                      'Entendido',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityBanner(WaterPoint point) {
    if (point.calidad == WaterQuality.requiereTratamiento) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.softAmber,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderAmber),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              LucideIcons.alertTriangle,
              color: AppColors.warningAmber,
              size: 18,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Agua requiere tratamiento obligatorio',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: AppColors.darkAmber,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Consulta las indicaciones oficiales vigentes de MINSA/DIGESA para el uso y desinfección del agua antes de beber.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.darkAmber,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (point.calidad == WaterQuality.apta) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.softGreen,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderGreen),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.shieldCheck, color: AppColors.safeGreen, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Agua apta para consumo humano directo',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: AppColors.darkGreen,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Punto verificado con control de cloro residual y turbidez bajo estándares de SUNASS.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.darkGreen,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Default when no verified evidence exists: NEVER falsely claim safe/verified
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.helpCircle, color: AppColors.slate600, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calidad del agua: Sin información actual',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: AppColors.slate800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'No se dispone de mediciones recientes de cloro residual o turbidez en este registro.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.slate600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final WaterPoint point;
  final bool isEmergency;

  const _StatusBadge({required this.point, required this.isEmergency});

  @override
  Widget build(BuildContext context) {
    if (!isEmergency) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.slate100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.slate300),
        ),
        child: Text(
          point.estN.isNotEmpty ? point.estN : 'Catálogo local',
          style: const TextStyle(
            color: AppColors.slate700,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    final isSafe = point.estE == EmergencyStatus.ok;
    final isWarn = point.estE == EmergencyStatus.warn;
    final isBad = point.estE == EmergencyStatus.bad;

    final Color bgColor;
    final Color borderColor;
    final Color textColor;

    if (isSafe) {
      bgColor = AppColors.softGreen;
      borderColor = AppColors.borderGreen;
      textColor = AppColors.darkGreen;
    } else if (isWarn) {
      bgColor = AppColors.softAmber;
      borderColor = AppColors.borderAmber;
      textColor = AppColors.darkAmber;
    } else if (isBad) {
      bgColor = AppColors.softRed;
      borderColor = AppColors.borderRed;
      textColor = AppColors.darkRed;
    } else {
      // Neutral presentation for unknown: NEVER green confirmation
      bgColor = AppColors.slate100;
      borderColor = AppColors.slate300;
      textColor = AppColors.slate700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        point.estETxt.isNotEmpty ? point.estETxt : 'Estado no confirmado',
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SpecCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;

  const _SpecCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: iconColor),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppColors.slate900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 9, color: AppColors.slate500),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MetaRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.slate500),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.slate800,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
