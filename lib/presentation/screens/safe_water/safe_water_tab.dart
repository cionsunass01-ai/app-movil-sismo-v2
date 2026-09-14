import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/audio_haptic_service.dart';

class SafeWaterTab extends StatefulWidget {
  const SafeWaterTab({super.key});

  @override
  State<SafeWaterTab> createState() => _SafeWaterTabState();
}

class _SafeWaterTabState extends State<SafeWaterTab> {
  // Reserve Calculator State
  int _persons = 4;
  int _days = 3;
  bool _isSphereMode = true; // true = 15L, false = 7.5L

  // Bleach Disinfection Calculator State
  double _volumeLiters = 20.0;
  int _bleachConcPercent = 5; // 5%
  bool _isCopied = false;

  void _copyDisinfectionProtocol() {
    final double bleachMl =
        (_volumeLiters * AppConstants.targetFreeChlorineMgL) / (_bleachConcPercent * 10);
    final int drops = (bleachMl * AppConstants.dropsPerMl).round();

    final text =
        'Protocolo AguaCION:\n'
        'Para ${_volumeLiters.toInt()} litros de agua, agregar ${bleachMl.toStringAsFixed(1)} mL '
        '(aprox. $drops gotas) de lejía al $_bleachConcPercent%.\n'
        'Instrucciones:\n'
        '1. Si el agua está turbia, fíltrela con paño limpio.\n'
        '2. Agregue la dosis, mezcle vigorosamente y tape el envase.\n'
        '3. Espere 30 minutos de reposo obligatorio antes de beber.';

    Clipboard.setData(ClipboardData(text: text));
    AudioHapticService.triggerSuccess();

    setState(() => _isCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Volume calculations
    final double quotaPerDay = _isSphereMode
        ? AppConstants.sphereStandardLitersPerDay
        : AppConstants.survivalMinimumLitersPerDay;
    final double totalWaterNeeded = _persons * _days * quotaPerDay;
    final int jugs20L = (totalWaterNeeded / AppConstants.standardJugCapacityLiters).ceil();

    // Bleach calculations
    final double bleachMl =
        (_volumeLiters * AppConstants.targetFreeChlorineMgL) / (_bleachConcPercent * 10);
    final int bleachDrops = (bleachMl * AppConstants.dropsPerMl).round();

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
      children: [
        // ================= SECTION 0: INSTITUTIONAL GUIDANCE BANNER =================
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.softBlue,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderBlue),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.shieldAlert, color: AppColors.sunassNavy, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Recomendaciones para el uso y desinfección del agua',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.sunassNavy,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Text(
                'Consulta indicaciones oficiales vigentes de MINSA/DIGESA.',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate700,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Los cálculos de esta sección son estimaciones referenciales de emergencia (estándar Esfera). Ante cualquier duda, priorice las indicaciones de las autoridades sanitarias.',
                style: TextStyle(fontSize: 10.5, color: AppColors.slate600),
              ),
            ],
          ),
        ),

        // ================= SECTION 1: FAMILY RESERVE CALCULATOR =================
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(LucideIcons.droplet, color: AppColors.accentBlue, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Calculadora de Reserva Familiar',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slate900,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.softBlue,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Estándar Esfera',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentBlue,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Persons Stepper
              _StepperRow(
                title: 'Personas en tu hogar',
                subtitle: 'Integrantes de la familia',
                value: _persons,
                onDecrement: () {
                  if (_persons > 1) {
                    setState(() => _persons--);
                    AudioHapticService.triggerClick();
                  }
                },
                onIncrement: () {
                  setState(() => _persons++);
                  AudioHapticService.triggerClick();
                },
              ),

              const SizedBox(height: 10),

              // Days Stepper
              _StepperRow(
                title: 'Días a cubrir',
                subtitle: 'Tiempo de autonomía',
                value: _days,
                onDecrement: () {
                  if (_days > 1) {
                    setState(() => _days--);
                    AudioHapticService.triggerClick();
                  }
                },
                onIncrement: () {
                  setState(() => _days++);
                  AudioHapticService.triggerClick();
                },
              ),

              const SizedBox(height: 12),

              // Standard Toggle (15L vs 7.5L)
              Row(
                children: [
                  Expanded(
                    child: _QuotaButton(
                      title: '15 L / día',
                      subtitle: 'Recomendado OMS',
                      isSelected: _isSphereMode,
                      activeColor: AppColors.accentBlue,
                      onTap: () {
                        setState(() => _isSphereMode = true);
                        AudioHapticService.triggerClick();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuotaButton(
                      title: '7.5 L / día',
                      subtitle: 'Mínimo Vital',
                      isSelected: !_isSphereMode,
                      activeColor: AppColors.warningAmber,
                      onTap: () {
                        setState(() => _isSphereMode = false);
                        AudioHapticService.triggerClick();
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Reserve Result Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.slate900,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${totalWaterNeeded.toInt()} L',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.white,
                            fontFamily: 'monospace',
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Text(
                          'Volumen total requerido',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: AppColors.slate400,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$jugs20L ${jugs20L > 1 ? 'bidones' : 'bidón'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFDE047),
                            fontFamily: 'monospace',
                          ),
                        ),
                        const Text(
                          'De 20 litros cada uno',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.slate400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // ================= SECTION 2: CHLORINE DISINFECTION CALCULATOR =================
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(LucideIcons.shieldCheck, color: AppColors.safeGreen, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Desinfección Segura con Lejía',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slate900,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.softGreen,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Dosis 2 mg/L',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.safeGreen,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Volume Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Volumen del recipiente:',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.slate800),
                  ),
                  Text(
                    '${_volumeLiters.toInt()} Litros',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accentBlue,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              Slider(
                value: _volumeLiters,
                min: 1,
                max: 100,
                divisions: 99,
                activeColor: AppColors.accentBlue,
                inactiveColor: AppColors.slate200,
                onChanged: (val) => setState(() => _volumeLiters = val),
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('1 L', style: TextStyle(fontSize: 9, color: AppColors.slate500)),
                  Text('10 L', style: TextStyle(fontSize: 9, color: AppColors.slate500)),
                  Text('20 L (Bidón)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.accentBlue)),
                  Text('50 L', style: TextStyle(fontSize: 9, color: AppColors.slate500)),
                  Text('100 L', style: TextStyle(fontSize: 9, color: AppColors.slate500)),
                ],
              ),

              const SizedBox(height: 14),

              // Concentration Dropdown
              const Text(
                'Concentración de la lejía comercial:',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.slate800),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.slate300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _bleachConcPercent,
                    isExpanded: true,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate900,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 5,
                        child: Text('Lejía doméstica común al 5% (Recomendada)'),
                      ),
                      DropdownMenuItem(
                        value: 4,
                        child: Text('Lejía doméstica al 4%'),
                      ),
                      DropdownMenuItem(
                        value: 8,
                        child: Text('Hipoclorito de sodio al 8%'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _bleachConcPercent = val);
                        AudioHapticService.triggerClick();
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Result Box with Copy button
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.deepGreen,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.darkGreen),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${bleachMl.toStringAsFixed(1).replaceAll('.', ',')} mL',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppColors.white,
                                fontFamily: 'monospace',
                              ),
                            ),
                            RichText(
                              text: TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'Aproximadamente ',
                                    style: TextStyle(fontSize: 11, color: Color(0xFFA7F3D0)),
                                  ),
                                  TextSpan(
                                    text: '$bleachDrops gotas',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFFDE047),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: _copyDisinfectionProtocol,
                          icon: Icon(
                            _isCopied ? LucideIcons.check : LucideIcons.copy,
                            size: 13,
                          ),
                          label: Text(
                            _isCopied ? '¡Copiado!' : 'Copiar',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.safeGreen,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.darkGreen, height: 16),
                    const Text(
                      '1. Si el agua está turbia, fíltrela con un paño limpio.\n'
                      '2. Agregue la dosis, mezcle vigorosamente y tape el envase.\n'
                      '3. Espere 30 minutos de reposo obligatorio antes de beber.',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFFA7F3D0),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepperRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _StepperRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate800,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 9.5,
                  color: AppColors.slate500,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: onDecrement,
                icon: const Icon(LucideIcons.minus, size: 14),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(6),
                  backgroundColor: AppColors.white,
                  side: const BorderSide(color: AppColors.slate300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              Container(
                width: 32,
                alignment: Alignment.center,
                child: Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                    color: AppColors.slate900,
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: onIncrement,
                icon: const Icon(LucideIcons.plus, size: 14),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(6),
                  backgroundColor: AppColors.white,
                  side: const BorderSide(color: AppColors.slate300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuotaButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _QuotaButton({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.slate300,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: isSelected ? AppColors.white : AppColors.slate800,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9.5,
                color: isSelected ? AppColors.white.withValues(alpha: 0.8) : AppColors.slate500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
