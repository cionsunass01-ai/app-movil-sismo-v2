import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/app_state_provider.dart';

class ReportTab extends StatefulWidget {
  const ReportTab({super.key});

  @override
  State<ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<ReportTab> {
  String? _selectedPointId;
  String _selectedIssue = 'El punto no tiene agua disponible';
  final TextEditingController _commentController = TextEditingController();

  final List<String> _issueOptions = [
    'El punto no tiene agua disponible',
    'La cisterna no llegó en el horario previsto',
    'El agua sale turbia o con olor anómalo',
    'Hay una fuga visible o rotura en la vía',
    'Acceso peatonal o vehicular bloqueado por escombros',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _handleSubmit(AppStateProvider state) {
    final points = state.points;
    final targetPoint = points.firstWhere(
      (p) => p.id == (_selectedPointId ?? points.first.id),
      orElse: () => points.first,
    );

    state.submitReport(
      puntoId: targetPoint.id,
      puntoNombre: targetPoint.n,
      tipoProblema: _selectedIssue,
      comentario: _commentController.text.trim(),
      sector: targetPoint.sector,
    );

    _commentController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final points = state.points;
    final queuedReports = state.queuedReports;
    final isOnline = state.isOnline;

    if (_selectedPointId == null && points.isNotEmpty) {
      _selectedPointId = points.first.id;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
      children: [
        // Queued Reports Sync Strip
        if (queuedReports.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.softAmber,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderAmber),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.hourglass, color: AppColors.warningAmber, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${queuedReports.length} ${queuedReports.length > 1 ? 'reportes guardados' : 'reporte guardado'} en memoria local',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkAmber,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Se sincronizarán automáticamente con SUNASS y el COE EPS apenas vuelva la señal.',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppColors.darkAmber,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOnline)
                  FilledButton(
                    onPressed: () => state.syncQueuedReports(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.warningAmber,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Sincronizar', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Main Report Form
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
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isOnline ? AppColors.softBlue : AppColors.softRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        LucideIcons.send,
                        size: 16,
                        color: isOnline ? AppColors.sunassBlue : AppColors.primaryRed,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alerta Ciudadana en Tiempo Real',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slate900,
                        ),
                      ),
                      Text(
                        'Reporta incidencias para redistribución del COE EPS',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Target Point Selector
              const Text(
                'PUNTO O ZONA AFECTADA:',
                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.slate600),
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
                  child: DropdownButton<String>(
                    value: _selectedPointId,
                    isExpanded: true,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.slate900),
                    items: points.map((p) {
                      return DropdownMenuItem(
                        value: p.id,
                        child: Text('${p.n} (${p.sector})', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedPointId = val);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Issue Type Selector
              const Text(
                'INCIDENCIA DETECTADA:',
                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.slate600),
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
                  child: DropdownButton<String>(
                    value: _selectedIssue,
                    isExpanded: true,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.slate900),
                    items: _issueOptions.map((issue) {
                      return DropdownMenuItem(
                        value: issue,
                        child: Text(issue, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedIssue = val);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Additional Comment Field
              const Text(
                'DETALLE ADICIONAL (OPCIONAL):',
                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.slate600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _commentController,
                maxLines: 3,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Ej: Colas de 50 personas, cisterna no aparece desde las 08:00...',
                  hintStyle: const TextStyle(fontSize: 11, color: AppColors.slate400),
                  filled: true,
                  fillColor: AppColors.slate50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.slate300),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),

              const SizedBox(height: 16),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _handleSubmit(state),
                  icon: const Icon(LucideIcons.send, size: 15),
                  label: Text(
                    isOnline
                        ? 'Transmitir reporte a SUNASS y EPS'
                        : 'Guardar reporte localmente (Sin internet)',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: isOnline ? AppColors.sunassBlue : AppColors.primaryRed,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Offline Guarantee Note
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.softBlue,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderBlue),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.shieldCheck, color: AppColors.sunassCyan, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Garantía de funcionamiento offline: El reporte se georreferencia con tu GPS nativo y queda almacenado de forma segura en tu teléfono hasta tener cobertura.',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF0369A1),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Queued Reports Local History
        if (queuedReports.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'REPORTES EN COLA DE SINCRONIZACIÓN (${queuedReports.length}):',
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: AppColors.slate500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          ...queuedReports.map((rep) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        rep.puntoNombre,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slate900,
                        ),
                      ),
                      Text(
                        rep.timestamp,
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rep.tipoProblema,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryRed,
                    ),
                  ),
                  if (rep.comentario.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      rep.comentario,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.slate600,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}
