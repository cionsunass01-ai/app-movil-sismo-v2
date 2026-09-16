import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../providers/app_state_provider.dart';

class ToastBanner extends StatelessWidget {
  const ToastBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final message = state.notificationMessage;

    if (message == null) return const SizedBox.shrink();

    final isErrorOrAlert = message.startsWith('⚠') || message.startsWith('🚚');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: isErrorOrAlert ? AppColors.darkRed : AppColors.safeGreen,
      child: Row(
        children: [
          Icon(
            isErrorOrAlert ? LucideIcons.alertTriangle : LucideIcons.check,
            color: AppColors.white,
            size: 15,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          InkWell(
            onTap: () => state.clearNotification(),
            child: const Icon(LucideIcons.x, color: AppColors.white, size: 14),
          ),
        ],
      ),
    );
  }
}
