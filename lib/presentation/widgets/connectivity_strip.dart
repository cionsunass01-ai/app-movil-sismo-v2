import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:lucide_icons_flutter/lucide_icons.dart";
import "../../core/constants/app_colors.dart";
import "../providers/app_state_provider.dart";

/// Read-only status strip reflecting the physical hardware network interface state.
///
/// Tap-to-toggle has been completely removed from the citizen flow.
class ConnectivityStrip extends StatelessWidget {
  const ConnectivityStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final isOnline = state.isOnline;
    final isSimulated = state.isConnectivitySimulationEnabled;
    final queuedCount = state.queuedReports.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFFF0FDF4) : const Color(0xFF0F172A),
        border: Border(
          bottom: BorderSide(
            color: isOnline ? const Color(0xFFBBF7D0) : const Color(0xFF1E293B),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  isOnline ? LucideIcons.wifi : LucideIcons.wifiOff,
                  size: 13,
                  color: isOnline
                      ? AppColors.darkGreen
                      : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isOnline
                        ? "Con conexión de red"
                        : "Sin conexión — Mapa local y cálculo de rutas disponibles en el dispositivo",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isOnline
                          ? const Color(0xFF166534)
                          : const Color(0xFFE2E8F0),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSimulated) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.softAmber,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.borderAmber),
                    ),
                    child: const Text(
                      "MANUAL",
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.darkAmber,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (queuedCount > 0)
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: AppColors.warningAmber,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "$queuedCount reportes pendientes",
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate950,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
