import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_location.dart';
import '../../providers/app_state_provider.dart';

class SectorTab extends StatelessWidget {
  const SectorTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final currentSector = state.currentSectorData;
    final sectors = state.sectors;
    final isEmergency = state.isEmergency;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      children: [
        // Main Sector Highlight Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.slate200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.softRed,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderRed),
                ),
                child: const Text(
                  'SECTOR ASIGNADO POR EPS',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryRed,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                currentSector.n,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.slate900,
                  letterSpacing: -0.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    isEmergency ? '${currentSector.rac}h' : '${currentSector.con}h',
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: AppColors.slate900,
                      fontFamily: 'monospace',
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'de agua al día\n(${isEmergency ? 'Racionamiento por sismo' : 'Continuidad normal'})',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate500,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Horario de turno:',
                      style: TextStyle(fontSize: 11.5, color: AppColors.slate600),
                    ),
                    Text(
                      currentSector.hor,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.slate900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Abastecido por el reservorio ${currentSector.res}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.slate500,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Quick Sector Switcher
        const Text(
          'SIMULAR CONSULTA DE OTROS SECTORES DE MOQUEGUA:',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: AppColors.slate500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: sectors.map((sec) {
            final isSelected = sec.n == state.userLocation.sector;
            return InkWell(
              onTap: () {
                state.setUserLocation(
                  UserLocation(
                    nombre: '${sec.n} (Simulado)',
                    sector: sec.n,
                    lat: state.userLocation.lat,
                    lon: state.userLocation.lon,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryRed : AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryRed : AppColors.slate200,
                  ),
                ),
                child: Text(
                  sec.n,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? AppColors.white : AppColors.slate700,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Full Sector Comparison Table
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate200),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: AppColors.slate950,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Plan de Contingencia y Racionamiento',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'OFICIAL EPS',
                      style: TextStyle(
                        color: Color(0xFFFCA5A5),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(2.2),
                  1: FlexColumnWidth(1.0),
                  2: FlexColumnWidth(1.0),
                  3: FlexColumnWidth(2.0),
                },
                children: [
                  TableRow(
                    decoration: const BoxDecoration(
                      color: AppColors.slate50,
                      border: Border(bottom: BorderSide(color: AppColors.slate200)),
                    ),
                    children: [
                      _headerCell('SECTOR'),
                      _headerCell('NORMAL', align: TextAlign.center),
                      _headerCell('SISMO', align: TextAlign.center, isAlert: true),
                      _headerCell('HORARIO'),
                    ],
                  ),
                  ...sectors.map((sec) {
                    final isSelected = sec.n == state.userLocation.sector;
                    return TableRow(
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.softRed.withValues(alpha: 0.7) : AppColors.white,
                        border: const Border(bottom: BorderSide(color: AppColors.slate100)),
                      ),
                      children: [
                        _dataCell(
                          isSelected ? '📍 ${sec.n}' : sec.n,
                          isBold: isSelected,
                          color: isSelected ? AppColors.deepRed : AppColors.slate800,
                        ),
                        _dataCell('${sec.con}h', align: TextAlign.center),
                        _dataCell(
                          '${sec.rac}h',
                          align: TextAlign.center,
                          isBold: true,
                          color: AppColors.primaryRed,
                        ),
                        _dataCell(sec.hor, fontSize: 10),
                      ],
                    );
                  }),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Strategic Context Note
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.softAmber,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderAmber),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.info, color: AppColors.warningAmber, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'El Valor Preventivo de Esta Información',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkAmber,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Text(
                'En los Planes de Emergencia de muchas EPS, los horarios de racionamiento suelen no estar claros para el vecino. AguaCION asigna horarios verificables a cada sector, evitando incertidumbre y colapsos el día del desastre.',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.darkAmber,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _headerCell(String title, {TextAlign align = TextAlign.left, bool isAlert = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        title,
        textAlign: align,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: isAlert ? AppColors.primaryRed : AppColors.slate500,
        ),
      ),
    );
  }

  Widget _dataCell(
    String content, {
    TextAlign align = TextAlign.left,
    bool isBold = false,
    Color? color,
    double fontSize = 11,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        content,
        textAlign: align,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
          color: color ?? AppColors.slate700,
        ),
      ),
    );
  }
}
