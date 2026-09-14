import "package:flutter/material.dart";
import "package:lucide_icons_flutter/lucide_icons.dart";
import "../../core/constants/app_colors.dart";

class OperationalStatusChip extends StatelessWidget {
  final String statusText;
  final bool isConfirmed;

  const OperationalStatusChip({
    super.key,
    this.statusText = "Estado no confirmado",
    this.isConfirmed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: isConfirmed ? AppColors.softGreen : AppColors.slate100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isConfirmed ? AppColors.borderGreen : AppColors.slate300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConfirmed ? LucideIcons.checkCircle : LucideIcons.helpCircle,
            size: 12,
            color: isConfirmed ? AppColors.darkGreen : AppColors.slate600,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: isConfirmed ? AppColors.darkGreen : AppColors.slate700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class SourceChip extends StatelessWidget {
  final String sourceLabel;

  const SourceChip({super.key, this.sourceLabel = "Catálogo local"});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderBlue),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.database,
            size: 11,
            color: AppColors.sunassBlue,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              sourceLabel,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.sunassNavy,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class FreshnessChip extends StatelessWidget {
  final String freshnessLabel;

  const FreshnessChip({
    super.key,
    this.freshnessLabel = "Sin reporte reciente",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.clock, size: 11, color: Color(0xFF92400E)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              freshnessLabel,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF92400E),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
