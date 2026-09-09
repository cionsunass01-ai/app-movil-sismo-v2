import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../providers/app_state_provider.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final activeTab = state.activeTab;
    final queuedCount = state.queuedReports.length;
    final isEmergency = state.isEmergency;

    final Color activeColor = isEmergency ? AppColors.primaryRed : AppColors.sunassBlue;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.slate200),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: LucideIcons.droplet,
              label: 'Puntos',
              isSelected: activeTab == AppTab.puntos,
              activeColor: activeColor,
              onTap: () => state.setActiveTab(AppTab.puntos),
            ),
            _NavItem(
              icon: LucideIcons.map,
              label: 'Mapa',
              isSelected: activeTab == AppTab.mapa,
              activeColor: activeColor,
              onTap: () => state.setActiveTab(AppTab.mapa),
            ),
            _NavItem(
              icon: LucideIcons.clock,
              label: 'Mi Sector',
              isSelected: activeTab == AppTab.sector,
              activeColor: activeColor,
              onTap: () => state.setActiveTab(AppTab.sector),
            ),
            _NavItem(
              icon: LucideIcons.shieldCheck,
              label: 'Agua Segura',
              isSelected: activeTab == AppTab.agua,
              activeColor: activeColor,
              onTap: () => state.setActiveTab(AppTab.agua),
            ),
            _NavItem(
              icon: LucideIcons.send,
              label: 'Reportar',
              isSelected: activeTab == AppTab.reportar,
              activeColor: activeColor,
              badgeCount: queuedCount > 0 ? queuedCount : null,
              onTap: () => state.setActiveTab(AppTab.reportar),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color activeColor;
  final int? badgeCount;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.activeColor,
    this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color itemColor = isSelected ? activeColor : AppColors.slate500;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: itemColor, size: 20),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: itemColor,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isSelected ? activeColor : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            if (badgeCount != null)
              Positioned(
                top: -2,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.all(3.5),
                  decoration: const BoxDecoration(
                    color: AppColors.warningAmber,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: AppColors.slate950,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
