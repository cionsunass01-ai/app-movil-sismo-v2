import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:lucide_icons_flutter/lucide_icons.dart";
import "../../core/constants/app_colors.dart";
import "../providers/app_state_provider.dart";

class EmergencyBanner extends StatelessWidget {
  const EmergencyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    if (!state.isEmergency) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF7F1D1D),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFB91C1C), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "ALERTA",
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "RÉGIMEN DE CONTINGENCIA SÍSMICA",
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "Protocolo activo: confirmación física de puntos hasta 48 h post-sismo.",
                        style: TextStyle(
                          color: Color(0xFFFECACA),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.x, size: 14, color: AppColors.white),
            tooltip: "Cerrar aviso",
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () => state.toggleEmergency(),
          ),
        ],
      ),
    );
  }
}
