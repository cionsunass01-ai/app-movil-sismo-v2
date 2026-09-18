import "package:flutter/foundation.dart" show kIsWeb;
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:lucide_icons_flutter/lucide_icons.dart";
import "../../../core/constants/app_colors.dart";
import "../../providers/app_state_provider.dart";
import "../../widgets/pwa_install_prompt_modal.dart";

class MoreTab extends StatelessWidget {
  const MoreTab({super.key});

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(LucideIcons.info, color: AppColors.sunassBlue, size: 20),
            SizedBox(width: 8),
            Text(
              "Acerca de AguaCION",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "AguaCION v2.0",
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
            ),
            SizedBox(height: 6),
            Text(
              "Herramienta móvil para contingencias sísmicas y emergencias de abastecimiento con mapa y cálculo de rutas disponibles sin conexión.",
              style: TextStyle(fontSize: 12.5, color: AppColors.slate700),
            ),
            SizedBox(height: 12),
            Text(
              "Contexto institucional: SUNASS",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppColors.sunassNavy,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "Desarrollo orientado a la Gestión del Riesgo de Desastres en el marco institucional de SUNASS, para asegurar la orientación a la ciudadanía sobre fuentes de agua potable en situaciones de emergencia.",
              style: TextStyle(fontSize: 11, color: AppColors.slate500),
            ),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.sunassNavy,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Entendido"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "SERVICIOS Y CONSULTAS",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.slate500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          // 1. Preparación de agua
          _OptionCard(
            icon: LucideIcons.shieldCheck,
            iconColor: AppColors.safeGreen,
            title: "Preparación de Agua",
            subtitle:
                "Recomendaciones para el uso y desinfección del agua. Consulta indicaciones oficiales vigentes de MINSA/DIGESA.",
            onTap: () => state.setActiveTab(AppTab.agua),
          ),
          const SizedBox(height: 10),

          // 2. Mi sector
          _OptionCard(
            icon: LucideIcons.clock,
            iconColor: const Color(0xFF0284C7),
            title: "Mi Sector",
            subtitle: "Consulta información y horarios de rotación de tu zona.",
            onTap: () => state.setActiveTab(AppTab.sector),
          ),
          const SizedBox(height: 10),

          // 3. Reportar incidencia
          _OptionCard(
            icon: LucideIcons.send,
            iconColor: AppColors.sunassBlue,
            title: "Reportar Incidencia",
            subtitle:
                "Registra incidencias de abastecimiento en tu zona para ser enviadas a los equipos técnicos en cuanto recuperes conexión.",
            onTap: () => state.setActiveTab(AppTab.reportar),
          ),

          const SizedBox(height: 24),
          const Text(
            "INFORMACIÓN INSTITUCIONAL Y TÉCNICA",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.slate500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          // Instalar Aplicación (PWA en Web)
          if (kIsWeb) ...[
            _OptionCard(
              icon: LucideIcons.smartphone,
              iconColor: AppColors.sunassBlue,
              title: "Instalar Aplicación en tu Celular",
              subtitle:
                  "Agrega AguaCION a tu pantalla de inicio para abrirla como aplicación móvil.",
              onTap: () => PwaInstallPromptModal.show(context),
            ),
            const SizedBox(height: 10),
          ],

          // 4. Acerca de
          _OptionCard(
            icon: LucideIcons.info,
            iconColor: AppColors.slate700,
            title: "Acerca de AguaCION",
            subtitle: "Información institucional y objetivos del aplicativo.",
            onTap: () => _showAboutDialog(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.slate200),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Icon(icon, color: iconColor, size: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate900,
                    ),
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
