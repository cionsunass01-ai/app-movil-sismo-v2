import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../providers/app_state_provider.dart';

class ConnectivityStrip extends StatelessWidget {
  const ConnectivityStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final isOnline = state.isOnline;
    final queuedCount = state.queuedReports.length;

    return InkWell(
      onTap: () => state.toggleOnline(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isOnline ? AppColors.softGreen : AppColors.slate900,
          border: Border(
            bottom: BorderSide(
              color: isOnline ? AppColors.borderGreen : AppColors.slate800,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isOnline ? AppColors.safeGreen : AppColors.warningAmber,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isOnline
                          ? 'Conectado — Datos de campo actualizados hoy (Toca para Offline)'
                          : 'Sin señal celular — Navegación 100% offline (Toca para Online)',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isOnline ? AppColors.darkGreen : AppColors.slate200,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
                  '$queuedCount en cola',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: AppColors.slate950,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
