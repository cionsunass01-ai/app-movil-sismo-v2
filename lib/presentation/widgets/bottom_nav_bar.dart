import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:lucide_icons_flutter/lucide_icons.dart";
import "../../core/constants/app_colors.dart";
import "../providers/app_state_provider.dart";

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final activeTab = state.activeTab;
    final isEmergency = state.isEmergency;

    final Color activeColor = isEmergency
        ? AppColors.primaryRed
        : AppColors.sunassBlue;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.slate200)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: LucideIcons.home,
              label: "Inicio",
              isSelected: activeTab == AppTab.inicio,
              activeColor: activeColor,
              onTap: () => state.setActiveTab(AppTab.inicio),
            ),
            _NavItem(
              icon: LucideIcons.map,
              label: "Mapa",
              isSelected: activeTab == AppTab.mapa,
              activeColor: activeColor,
              onTap: () => state.setActiveTab(AppTab.mapa),
            ),
            _NavItem(
              icon: LucideIcons.droplet,
              label: "Puntos",
              isSelected: activeTab == AppTab.puntos,
              activeColor: activeColor,
              onTap: () => state.setActiveTab(AppTab.puntos),
            ),
            _NavItem(
              icon: LucideIcons.layoutGrid,
              label: "Más",
              isSelected:
                  activeTab == AppTab.mas ||
                  activeTab == AppTab.sector ||
                  activeTab == AppTab.agua ||
                  activeTab == AppTab.reportar,
              activeColor: activeColor,
              onTap: () => state.setActiveTab(AppTab.mas),
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
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color itemColor = isSelected ? activeColor : AppColors.slate500;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: itemColor, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: itemColor,
                fontSize: 11,
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
      ),
    );
  }
}
