import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_colors.dart';

class LocationPermissionModal extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback? onCancel;

  const LocationPermissionModal({
    super.key,
    required this.onAccept,
    this.onCancel,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onAccept,
    VoidCallback? onCancel,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LocationPermissionModal(
        onAccept: () {
          Navigator.pop(context);
          onAccept();
        },
        onCancel: () {
          Navigator.pop(context);
          onCancel?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Drag indicator
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.slate300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Icon with glowing circular badge
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.softBlue,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.sunassBlue.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                LucideIcons.mapPin,
                size: 32,
                color: AppColors.sunassNavy,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'Encuentra agua cerca de ti',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.slate900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),

            // Friendly message
            const Text(
              'Para guiarte al punto de distribución más cercano y trazar la ruta peatonal ante sismos o cortes, AguaCION necesita acceder a tu ubicación.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.slate600,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),

            // Benefit cards
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.slate200),
              ),
              child: const Column(
                children: [
                  _BenefitRow(
                    icon: LucideIcons.footprints,
                    title: 'Ruta a pie más corta',
                    description:
                        'Calcula la distancia y tiempo estimado de caminata.',
                  ),
                  SizedBox(height: 12),
                  _BenefitRow(
                    icon: LucideIcons.shieldCheck,
                    title: '100% Privado y Local',
                    description:
                        'Tu posición se procesa en el celular; nunca se envía a servidores.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Action button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sunassBlue,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(LucideIcons.locateFixed, size: 18),
                label: const Text(
                  'Compartir mi ubicación',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Secondary button
            TextButton(
              onPressed: onCancel ?? () => Navigator.pop(context),
              child: const Text(
                'En otro momento',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Icon(icon, size: 16, color: AppColors.sunassBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.slate500,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
