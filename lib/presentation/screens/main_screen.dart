import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "../../core/constants/app_colors.dart";
import "../providers/app_state_provider.dart";
import "../widgets/header_bar.dart";
import "../widgets/emergency_banner.dart";
import "../widgets/connectivity_strip.dart";
import "../widgets/toast_banner.dart";
import "../widgets/bottom_nav_bar.dart";
import "home/inicio_tab.dart";
import "map/map_tab.dart";
import "points/points_tab.dart";
import "more/more_tab.dart";
import "sector/sector_tab.dart";
import "safe_water/safe_water_tab.dart";
import "report/report_tab.dart";

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final activeTab = state.activeTab;

    Widget bodyContent;
    switch (activeTab) {
      case AppTab.inicio:
        bodyContent = const InicioTab();
        break;
      case AppTab.mapa:
        bodyContent = const MapTab();
        break;
      case AppTab.puntos:
        bodyContent = const PointsTab();
        break;
      case AppTab.mas:
        bodyContent = const MoreTab();
        break;
      case AppTab.sector:
        bodyContent = const SectorTab();
        break;
      case AppTab.agua:
        bodyContent = const SafeWaterTab();
        break;
      case AppTab.reportar:
        bodyContent = const ReportTab();
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.slate100,
      body: SafeArea(
        child: Column(
          children: [
            const HeaderBar(),
            const EmergencyBanner(),
            const ConnectivityStrip(),
            const ToastBanner(),
            Expanded(child: bodyContent),
            const BottomNavBar(),
          ],
        ),
      ),
    );
  }
}
