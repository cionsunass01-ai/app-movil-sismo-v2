import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';

class SectorTab extends StatelessWidget {
  const SectorTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        // Main Integration Notice Card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.slate200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.softAmber,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderAmber),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.clock,
                      size: 13,
                      color: AppColors.darkAmber,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'FUNCIÓN EN DESARROLLO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.darkAmber,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Icon(
                LucideIcons.mapPinOff,
                size: 44,
                color: AppColors.slate400,
              ),
              const SizedBox(height: 12),
              const Text(
                'Información de sector pendiente de integración',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate900,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'La delimitación territorial de sectores de distribución y los cronogramas horarios de reparto por contingencia están en proceso de articulación técnica con la entidad prestadora (EPS / SEDAPAL).',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.slate600,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Objective of Sectorization
        const Text(
          'OBJETIVO DEL MÓDULO',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.slate500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),

        _InfoSectionCard(
          icon: LucideIcons.layers,
          iconColor: AppColors.sunassBlue,
          title: 'Sectorización oficial por distritos',
          description:
              'Mapeo de las subestaciones y zonas de presión hidráulica para identificar de forma precisa el régimen de abastecimiento de cada vecino.',
        ),
        const SizedBox(height: 10),

        _InfoSectionCard(
          icon: LucideIcons.calendarClock,
          iconColor: const Color(0xFF0284C7),
          title: 'Horarios de distribución por camión cisterna',
          description:
              'Programación horaria validada institucionalmente en caso de racionamiento severo o rotura de matrices por sismo mayor.',
        ),
        const SizedBox(height: 10),

        _InfoSectionCard(
          icon: LucideIcons.bellRing,
          iconColor: AppColors.safeGreen,
          title: 'Alertas locales de contingencia',
          description:
              'Notificaciones territoriales sobre arribo de cisternas y habilitación de nuevos puntos fijos de distribución.',
        ),
      ],
    );
  }
}

class _InfoSectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _InfoSectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.slate600,
                    height: 1.35,
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
