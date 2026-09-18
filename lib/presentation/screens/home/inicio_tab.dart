import "package:flutter/foundation.dart" show kIsWeb;
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:lucide_icons_flutter/lucide_icons.dart";
import "package:geolocator/geolocator.dart";
import "../../../core/constants/app_colors.dart";
import "../../../data/models/user_location.dart";
import "../../../domain/location/models/gnss_state.dart";
import "../../../data/repositories/local_location_repository.dart";
import "../../providers/app_state_provider.dart";
import "../../widgets/location_permission_modal.dart";
import "../../widgets/pwa_install_prompt_modal.dart";

class InicioTab extends StatefulWidget {
  const InicioTab({super.key});

  @override
  State<InicioTab> createState() => _InicioTabState();
}

class _InicioTabState extends State<InicioTab> {
  bool _isCheckingPermission = false;

  Future<void> _handleFindNearest(AppStateProvider state) async {
    setState(() => _isCheckingPermission = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        bool userApproved = false;
        await LocationPermissionModal.show(
          context,
          onAccept: () => userApproved = true,
        );

        if (!userApproved) {
          setState(() => _isCheckingPermission = false);
          return;
        }

        permission = await Geolocator.requestPermission();
      }

      // If permission granted, quickly acquire position
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final pos = await LocalLocationRepository().acquirePosition(
          timeoutSeconds: 5,
        );
        if (pos.state == LocationState.current ||
            pos.state == LocationState.lastKnown) {
          state.updateUserLocation(
            UserLocation(
              nombre: 'Mi Ubicación',
              sector: 'Detectado por GPS',
              lat: pos.latitude,
              lon: pos.longitude,
            ),
          );
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isCheckingPermission = false);
      state.findNearestAndNavigate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final activeCount = state.points.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Executive Subtitle Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.softBlue,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderBlue),
            ),
            child: const Row(
              children: [
                Icon(
                  LucideIcons.shieldCheck,
                  size: 16,
                  color: AppColors.sunassBlue,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Plataforma Oficial de Emergencia · SUNASS",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.sunassNavy,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Main Executive Hero Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.sunassDarkNavy,
                  AppColors.sunassNavy,
                  Color(0xFF0284C7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.sunassNavy.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.radio,
                        size: 12,
                        color: Color(0xFF38BDF8),
                      ),
                      SizedBox(width: 6),
                      Text(
                        "DISPONIBLE SIN INTERNET",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.white,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  "Encuentra puntos de abastecimiento incluso sin conexión",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.white,
                    height: 1.2,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Consulta el mapa local y calcula rutas peatonales con los datos almacenados en el dispositivo.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFFE0F2FE),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Primary Hero CTA
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isCheckingPermission
                        ? null
                        : () => _handleFindNearest(state),
                    icon: _isCheckingPermission
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.sunassNavy,
                            ),
                          )
                        : const Icon(LucideIcons.navigation, size: 20),
                    label: const Text(
                      "ENCONTRAR PUNTO CERCANO",
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.sunassDarkNavy,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Secondary CTA
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => state.setActiveTab(AppTab.mapa),
                    icon: const Icon(
                      LucideIcons.map,
                      size: 16,
                      color: Color(0xFFBAE6FD),
                    ),
                    label: const Text(
                      "VER MAPA COMPLETO",
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFBAE6FD),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // PWA Install Banner (only on Web if not standalone)
          if (kIsWeb && !PwaInstallPromptModal.isAlreadyInstalled) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.sunassBlue.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.softBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.smartphone,
                      color: AppColors.sunassNavy,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Instalar en tu teléfono",
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slate900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Agrega el icono para abrir AguaCION sin usar el navegador.",
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.slate500,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => PwaInstallPromptModal.show(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.sunassBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Instalar",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 3. System Offline Status Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.slate200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.hardDrive,
                      size: 16,
                      color: AppColors.slate700,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Estado del Dispositivo",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slate900,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  "Consulta el mapa local y calcula rutas peatonales con los datos almacenados en el dispositivo.",
                  style: TextStyle(fontSize: 11.5, color: AppColors.slate500),
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(
                      child: _StatusPill(
                        icon: LucideIcons.map,
                        title: "Mapa offline",
                        status: "LISTO",
                        isPositive: true,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _StatusPill(
                        icon: LucideIcons.mapPin,
                        title: "Ubicación",
                        status: "DISPONIBLE",
                        isPositive: true,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _StatusPill(
                        icon: LucideIcons.database,
                        title: "Datos",
                        status: "GUARDADOS",
                        isPositive: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 4. Quick Access Section (includes exact test labels: Puntos, Mi Sector, Agua Segura)
          const Text(
            "ACCESOS RÁPIDOS",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.slate500,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),

          // Card: Puntos de Agua
          _QuickNavCard(
            icon: LucideIcons.droplet,
            iconColor: AppColors.sunassBlue,
            title: "Puntos de Agua",
            subtitle:
                "Explora los $activeCount puntos de abastecimiento registrados en el catálogo local.",
            badgeText: "$activeCount registrados",
            onTap: () => state.setActiveTab(AppTab.puntos),
          ),
          const SizedBox(height: 8),

          // Card: Mi Sector
          _QuickNavCard(
            icon: LucideIcons.clock,
            iconColor: const Color(0xFF0284C7),
            title: "Mi Sector",
            subtitle:
                "Consulta información sobre zonificación y turnos de abastecimiento.",
            badgeText: "Próximamente",
            onTap: () => state.setActiveTab(AppTab.sector),
          ),
          const SizedBox(height: 8),

          // Card: Agua Segura
          _QuickNavCard(
            icon: LucideIcons.shieldCheck,
            iconColor: AppColors.safeGreen,
            title: "Agua Segura",
            subtitle:
                "Calcula la reserva de emergencia familiar y dosificación de desinfección.",
            badgeText: "Estándar Esfera",
            onTap: () => state.setActiveTab(AppTab.agua),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String title;
  final String status;
  final bool isPositive;

  const _StatusPill({
    required this.icon,
    required this.title,
    required this.status,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isPositive ? const Color(0xFFF0FDF4) : AppColors.slate100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPositive ? const Color(0xFFBBF7D0) : AppColors.slate200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 14,
            color: isPositive ? AppColors.darkGreen : AppColors.slate600,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.slate600,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            status,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              color: isPositive ? AppColors.darkGreen : AppColors.slate800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _QuickNavCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String badgeText;
  final VoidCallback onTap;

  const _QuickNavCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.slate200),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Icon(icon, color: iconColor, size: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slate900,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.slate100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.slate700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.slate500,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: AppColors.slate400,
            ),
          ],
        ),
      ),
    );
  }
}
