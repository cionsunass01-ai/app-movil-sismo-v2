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
    final dist = point.distMeters ?? 0;
    final text =
        'Punto de Agua AguaCION: ${point.n} (${point.sector})\n'
        'Ubicación: ${point.ref}\n'
        'Horario: ${point.horario}\n'
        'Capacidad: ${point.cap}\n'
        'Calidad: ${point.calidad.label}\n'
        'Distancia estimada: ${GeoUtils.formatDistance(dist)} (${GeoUtils.formatWalkingTime(dist)})';

    SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'Punto de Abastecimiento - ${point.n}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dist = point.distMeters ?? 0;
    final formattedDist = GeoUtils.formatDistance(dist);
    final walkTime = GeoUtils.formatWalkingTime(dist);
    final needsTreatment = point.calidad == WaterQuality.requiereTratamiento;

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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                      icon: const Icon(LucideIcons.x, color: AppColors.white, size: 20),
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
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin, color: Color(0xFFF87171), size: 13),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${point.ref} • ${point.sector}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.slate300,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _StatusBadge(point: point, isEmergency: isEmergency),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.slate800,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '📍 $formattedDist • $walkTime',
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
                  // Quality Warning / Safety banner
                  if (needsTreatment)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.softAmber,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderAmber),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(LucideIcons.alertTriangle, color: AppColors.warningAmber, size: 18),
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
                    )
                  else
                    Container(
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
                    ),

                  const SizedBox(height: 14),

                  // Technical Specs Grid (4 cards)
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.6,
                    children: [
                      _SpecCard(
                        icon: LucideIcons.clock,
                        iconColor: AppColors.slate700,
                        title: 'HORARIO',
                        value: point.horario,
                        subtitle: 'Turno de reparto',
                      ),
                      _SpecCard(
                        icon: LucideIcons.droplet,
                        iconColor: AppColors.accentBlue,
                        title: 'CAPACIDAD',
                        value: point.cap,
                        subtitle: 'Por viaje/ciclo',
                      ),
                      _SpecCard(
                        icon: LucideIcons.truck,
                        iconColor: AppColors.warningAmber,
                        title: 'FUENTE DE RECARGA',
                        value: point.recarga,
                        subtitle: 'Red troncal',
                      ),
                      _SpecCard(
                        icon: LucideIcons.users,
                        iconColor: AppColors.safeGreen,
                        title: 'POBLACIÓN ASIGNADA',
                        value: '${point.pobl} hab.',
                        subtitle: 'Radio de cobertura',
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Access and verification box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.slate200),
                    ),
                    child: Column(
                      children: [
                        _MetaRow(
                          label: 'Accesibilidad de Vía:',
                          value: '${point.acceso} (${point.pend})',
                        ),
                        const Divider(color: AppColors.slate100, height: 16),
                        _MetaRow(
                          label: 'Entidad Responsable:',
                          value: point.resp,
                        ),
                        const Divider(color: AppColors.slate100, height: 16),
                        _MetaRow(
                          label: 'Verificación en Campo:',
                          value: point.verMeses == 0
                              ? '${point.ver} (vigente)'
                              : '${point.ver} (hace ${point.verMeses} meses)',
                          valueColor: point.verMeses > 6 ? AppColors.darkAmber : AppColors.darkGreen,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Sphere standard quote
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.softBlue,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderBlue),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(LucideIcons.sparkles, color: AppColors.accentBlue, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Estándar Esfera: 15 L por persona/día. Para una familia de 4 son 60 L (3 bidones de 20L). Acude preferentemente al inicio del turno.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF1E3A8A),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                    icon: const Icon(LucideIcons.messageSquare, size: 15, color: AppColors.warningAmber),
                    label: const Text(
                      'Reportar Falla',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.slate800),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.slate300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: () => _sharePointInfo(context),
                  icon: const Icon(LucideIcons.share2, size: 18),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.navigation, size: 15),
                    label: const Text(
                      'Entendido',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          color: AppColors.softBlue,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderBlue),
        ),
        child: Text(
          point.estN,
          style: const TextStyle(
            color: Color(0xFF1E40AF),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    final isSafe = point.estE == EmergencyStatus.ok;
    final isWarn = point.estE == EmergencyStatus.warn;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isSafe
            ? AppColors.softGreen
            : isWarn
                ? AppColors.softAmber
                : AppColors.softRed,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSafe
              ? AppColors.borderGreen
              : isWarn
                  ? AppColors.borderAmber
                  : AppColors.borderRed,
        ),
      ),
      child: Text(
        point.estETxt,
        style: TextStyle(
          color: isSafe
              ? AppColors.darkGreen
              : isWarn
                  ? AppColors.darkAmber
                  : AppColors.darkRed,
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
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.slate500,
            ),
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

  const _MetaRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

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
