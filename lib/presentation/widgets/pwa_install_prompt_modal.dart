import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_colors.dart';

// Conditionally import dart:js_interop or stub
// In flutter web we can use js eval or dart:js_interop
import 'dart:js_interop' as js;

@js.JS('promptPwaInstall')
external js.JSPromise<js.JSString> _promptPwaInstall();

@js.JS('isPwaStandalone')
external js.JSBoolean _isPwaStandalone();

class PwaInstallPromptModal extends StatelessWidget {
  const PwaInstallPromptModal({super.key});

  static bool get isAlreadyInstalled {
    if (!kIsWeb) return true;
    try {
      return _isPwaStandalone().toDart;
    } catch (_) {
      return false;
    }
  }

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PwaInstallPromptModal(),
    );
  }

  static Future<void> triggerInstall(BuildContext context) async {
    if (!kIsWeb) return;
    try {
      final promise = _promptPwaInstall();
      final result = await promise.toDart;
      final outcome = result.toDart;
      if (outcome == 'accepted') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡AguaCION se ha instalado correctamente!'),
              backgroundColor: AppColors.sunassNavy,
            ),
          );
        }
      } else if (outcome == 'not_supported') {
        if (context.mounted) {
          show(context);
        }
      }
    } catch (_) {
      if (context.mounted) {
        show(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Indicator
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.slate300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.softBlue,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.sunassBlue.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                LucideIcons.smartphone,
                size: 30,
                color: AppColors.sunassNavy,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'Instalar AguaCION en tu celular',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.slate900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),

            const Text(
              'Ten acceso directo a los puntos de agua potable en tu pantalla de inicio, incluso sin internet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.slate600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Steps container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Column(
                children: isIOS
                    ? const [
                        _InstructionStep(
                          number: '1',
                          icon: LucideIcons.share2,
                          title: 'Toca el botón Compartir',
                          description:
                              'En la barra inferior de Safari, pulsa el icono del cuadrado con la flecha hacia arriba.',
                        ),
                        SizedBox(height: 14),
                        _InstructionStep(
                          number: '2',
                          icon: LucideIcons.plusSquare,
                          title: 'Selecciona "Agregar a inicio"',
                          description:
                              'Desliza las opciones y pulsa "Agregar a pantalla de inicio".',
                        ),
                      ]
                    : const [
                        _InstructionStep(
                          number: '1',
                          icon: LucideIcons.download,
                          title: 'Instalación directa',
                          description:
                              'Pulsa el botón azul "Instalar aplicación" para agregar AguaCION a tus apps.',
                        ),
                        SizedBox(height: 14),
                        _InstructionStep(
                          number: '2',
                          icon: LucideIcons.layers,
                          title: 'Icono en pantalla de inicio',
                          description:
                              'Se creará un icono oficial de SUNASS con apertura a pantalla completa.',
                        ),
                      ],
              ),
            ),
            const SizedBox(height: 22),

            // Action button (if Android / Chrome)
            if (!isIOS) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    triggerInstall(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sunassBlue,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(LucideIcons.download, size: 18),
                  label: const Text(
                    'Instalar aplicación',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Entendido',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String description;

  const _InstructionStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.sunassBlue,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 15, color: AppColors.slate700),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.slate600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
