import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:lucide_icons_flutter/lucide_icons.dart";
import "../../core/constants/app_colors.dart";
import "../providers/app_state_provider.dart";

class DemoToolsModal extends StatefulWidget {
  final VoidCallback? onRunBenchmark;
  final VoidCallback? onRunStressTest;
  final VoidCallback? onSimulateEdgeBlock;

  const DemoToolsModal({
    super.key,
    this.onRunBenchmark,
    this.onRunStressTest,
    this.onSimulateEdgeBlock,
  });

  static void show(
    BuildContext context, {
    VoidCallback? onRunBenchmark,
    VoidCallback? onRunStressTest,
    VoidCallback? onSimulateEdgeBlock,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DemoToolsModal(
        onRunBenchmark: onRunBenchmark,
        onRunStressTest: onRunStressTest,
        onSimulateEdgeBlock: onSimulateEdgeBlock,
      ),
    );
  }

  @override
  State<DemoToolsModal> createState() => _DemoToolsModalState();
}

class _DemoToolsModalState extends State<DemoToolsModal> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.slate300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        LucideIcons.wrench,
                        size: 20,
                        color: AppColors.sunassNavy,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Herramientas de Demostración",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slate900,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.softBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "DEMO ONLY",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.sunassBlue,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                "Controles técnicos para presentaciones ejecutivas y validación de escenarios.",
                style: TextStyle(fontSize: 12, color: AppColors.slate500),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 10),

              // 1. Simulación de Emergencia
              const Text(
                "SIMULACIÓN DE ESCENARIO",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: SwitchListTile.adaptive(
                  title: const Text(
                    "Simulación de Emergencia Sísmica",
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text(
                    "Activa racionamiento por rotura masiva y priorización de puntos.",
                    style: TextStyle(fontSize: 11.5, color: AppColors.slate600),
                  ),
                  value: state.isEmergency,
                  activeTrackColor: AppColors.primaryRed,
                  onChanged: (_) => state.toggleEmergency(),
                ),
              ),
              const SizedBox(height: 8),

              // 2. Simulación de Conectividad
              Container(
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: state.isConnectivitySimulationEnabled
                        ? AppColors.borderAmber
                        : AppColors.slate200,
                  ),
                ),
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      title: const Text(
                        "Sobreescribir conectividad (Simulación)",
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        state.isConnectivitySimulationEnabled
                            ? "Simulación activa: se anula la lectura de la red física"
                            : "Desactivada: la app refleja la red física real (Wi-Fi / Datos)",
                        style: TextStyle(
                          fontSize: 11.5,
                          color: state.isConnectivitySimulationEnabled
                              ? AppColors.darkAmber
                              : AppColors.slate600,
                        ),
                      ),
                      value: state.isConnectivitySimulationEnabled,
                      activeTrackColor: AppColors.warningAmber,
                      onChanged: (val) =>
                          state.setConnectivitySimulationEnabled(val),
                    ),
                    if (state.isConnectivitySimulationEnabled) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Estado simulado:",
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.slate700,
                              ),
                            ),
                            Row(
                              children: [
                                ChoiceChip(
                                  label: const Text(
                                    "Con conexión",
                                    style: TextStyle(fontSize: 11.5),
                                  ),
                                  selected: state.isOnline,
                                  onSelected: (selected) {
                                    if (selected) {
                                      state.setSimulatedConnectivity(
                                        NetworkState.connected,
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: const Text(
                                    "Sin conexión",
                                    style: TextStyle(fontSize: 11.5),
                                  ),
                                  selected: !state.isOnline,
                                  onSelected: (selected) {
                                    if (selected) {
                                      state.setSimulatedConnectivity(
                                        NetworkState.disconnected,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 10),

              // 3. Benchmarks y pruebas de motor
              const Text(
                "PRUEBAS DE RENDIMIENTO Y MOTOR",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onRunBenchmark?.call();
                      },
                      icon: const Icon(LucideIcons.gauge, size: 16),
                      label: const Text(
                        "Benchmark 30 Rutas",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onRunStressTest?.call();
                      },
                      icon: const Icon(LucideIcons.activity, size: 16),
                      label: const Text(
                        "Stress Test",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (widget.onSimulateEdgeBlock != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onSimulateEdgeBlock?.call();
                    },
                    icon: const Icon(
                      LucideIcons.ban,
                      size: 16,
                      color: AppColors.primaryRed,
                    ),
                    label: const Text(
                      "Simular Bloqueo de Vía (Rerouting)",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryRed,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryRed),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 10),

              // 4. Diagnóstico del dispositivo
              const Text(
                "ESTADO TÉCNICO VERIFICADO",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Column(
                  children: [
                    _DiagRow(
                      label: "Grafo peatonal CSR",
                      value: "855,857 nodos · 1,990,320 aristas",
                    ),
                    SizedBox(height: 6),
                    _DiagRow(
                      label: "Tamaño grafo (asset)",
                      value: "32.2 MB (binario desempacado)",
                    ),
                    SizedBox(height: 6),
                    _DiagRow(
                      label: "PMTiles Lima + Callao",
                      value: "10.2 MB (z0-z14 local)",
                    ),
                    SizedBox(height: 6),
                    _DiagRow(
                      label: "Umbral de snapping",
                      value: "50 metros (conservador)",
                    ),
                    SizedBox(height: 6),
                    _DiagRow(
                      label: "Motor cartográfico",
                      value: "MapLibre Native (pmtiles://)",
                    ),
                    SizedBox(height: 6),
                    _DiagRow(
                      label: "Benchmark iPhone (30 rutas)",
                      value: "mean 3.78 ms · p95 15.36 ms",
                    ),
                    SizedBox(height: 6),
                    _DiagRow(
                      label: "Puntos en catálogo",
                      value: "433 puntos registrados",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiagRow extends StatelessWidget {
  final String label;
  final String value;
  const _DiagRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, color: AppColors.slate600),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.slate900,
          ),
        ),
      ],
    );
  }
}
