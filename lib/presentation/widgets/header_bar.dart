import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../providers/app_state_provider.dart';
import '../../poc/offline_navigation/presentation/offline_navigation_poc_page.dart';

class HeaderBar extends StatelessWidget {
  const HeaderBar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: state.isEmergency
              ? [AppColors.slate950, AppColors.deepRed, AppColors.slate900]
              : [
                  AppColors.sunassDarkNavy,
                  AppColors.sunassNavy,
                  const Color(0xFF004B87),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        children: [
          // Top Row: Brand & Toggles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Brand Logo & Title
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.sunassCyan, AppColors.sunassBlue],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.sunassCyan.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        LucideIcons.droplet,
                        color: AppColors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Agua',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: AppColors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            TextSpan(
                              text: 'CION',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: state.isEmergency
                                    ? AppColors.primaryRed
                                    : AppColors.sunassCyan,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'SUNASS • Red de Agua Segura',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFBAE6FD),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Status Badges & Quick Action Buttons
              Row(
                children: [
                  // POC Offline Navigation launch badge
                  InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const OfflineNavigationPocPage(),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.amberAccent.withValues(alpha: 0.6),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.map,
                            color: Colors.amberAccent,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'POC OFFLINE',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // SUNASS regulatory official badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.sunassCyan.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.shieldCheck,
                          color: Color(0xFF38BDF8),
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'SUNASS',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // User Current Location & GPS bar
          GesturefulLocationPill(state: state),
        ],
      ),
    );
  }
}

class GesturefulLocationPill extends StatelessWidget {
  final AppStateProvider state;

  const GesturefulLocationPill({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  LucideIcons.locateFixed,
                  color: state.isEmergency
                      ? const Color(0xFFF87171)
                      : AppColors.sunassCyan,
                  size: 15,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cerca de: ${state.userLocation.nombre}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => state.requestLiveGps(),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
              decoration: BoxDecoration(
                color: state.isEmergency
                    ? AppColors.primaryRed.withValues(alpha: 0.35)
                    : AppColors.sunassCyan.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: state.isEmergency
                      ? AppColors.primaryRed.withValues(alpha: 0.5)
                      : AppColors.sunassCyan.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                state.isLiveGps ? 'GPS EN VIVO' : 'GPS OK',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: state.isEmergency
                      ? const Color(0xFFFCA5A5)
                      : const Color(0xFFE0F2FE),
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
