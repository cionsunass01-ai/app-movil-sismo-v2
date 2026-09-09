import React from 'react';
import { WaterPoint, EmergencyStatus } from '../types';
import { formatDistance, formatWalkingTime } from '../data/waterPoints';
import { 
  X, 
  MapPin, 
  Clock, 
  Droplet, 
  ShieldCheck, 
  AlertTriangle, 
  Truck, 
  Users, 
  CheckCircle2, 
  Navigation, 
  Share2, 
  MessageSquareWarning, 
  Sparkles
} from 'lucide-react';

interface PointDetailModalProps {
  point: WaterPoint;
  userLat: number;
  userLon: number;
  emergencyMode: boolean;
  onClose: () => void;
  onNavigateToReport: (pointId: string) => void;
}

export const PointDetailModal: React.FC<PointDetailModalProps> = ({
  point,
  userLat,
  userLon,
  emergencyMode,
  onClose,
  onNavigateToReport
}) => {
  const distance = point.distMeters ?? 0;
  const walkTime = formatWalkingTime(distance);
  const formattedDist = formatDistance(distance);
  const needsTreatment = point.calidad.includes('Requiere tratamiento');

  const getStatusBadge = (status: EmergencyStatus) => {
    if (!emergencyMode) {
      return (
        <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-blue-50 text-blue-800 border border-blue-200">
          <CheckCircle2 className="w-3.5 h-3.5 text-blue-600" />
          {point.estN}
        </span>
      );
    }
    if (status === 'ok') {
      return (
        <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-emerald-50 text-emerald-800 border border-emerald-200">
          <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
          {point.estETxt}
        </span>
      );
    }
    if (status === 'warn') {
      return (
        <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-amber-50 text-amber-800 border border-amber-200">
          <AlertTriangle className="w-3.5 h-3.5 text-amber-600" />
          {point.estETxt}
        </span>
      );
    }
    return (
      <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-red-50 text-red-800 border border-red-200">
        <AlertTriangle className="w-3.5 h-3.5 text-red-600" />
        {point.estETxt}
      </span>
    );
  };

  const [copied, setCopied] = React.useState(false);
  const handleCopyInfo = () => {
    const text = `Punto de Agua AguaCION: ${point.n} (${point.sector})\nUbicación: ${point.ref}\nHorario: ${point.horario}\nCapacidad: ${point.cap}\nCalidad: ${point.calidad}\nDistancia estimada: ${formattedDist}`;
    navigator.clipboard?.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-3 bg-slate-950/70 backdrop-blur-xs animate-in fade-in duration-150">
      <div 
        id="modal-point-detail"
        className="bg-white w-full max-w-lg rounded-3xl shadow-2xl border border-slate-200 overflow-hidden flex flex-col max-h-[90vh] animate-in zoom-in-95 duration-200"
      >
        {/* Header */}
        <div className="bg-gradient-to-r from-slate-900 via-slate-800 to-slate-950 text-white p-5 relative">
          <button 
            onClick={onClose}
            aria-label="Cerrar modal"
            className="absolute top-4 right-4 w-9 h-9 rounded-full bg-white/10 hover:bg-white/20 text-white flex items-center justify-center transition-colors cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>

          <div className="flex items-center gap-2 mb-1.5">
            <span className="text-[10px] font-mono tracking-wider uppercase font-bold bg-red-600/90 text-white px-2 py-0.5 rounded">
              {point.id}
            </span>
            <span className="text-xs text-slate-300 font-medium">
              {point.tipo}
            </span>
          </div>

          <h2 className="text-xl font-black text-white leading-snug pe-8">
            {point.n}
          </h2>
          <p className="text-xs text-slate-300 mt-1 flex items-center gap-1.5">
            <MapPin className="w-3.5 h-3.5 text-red-400 shrink-0" />
            {point.ref} • <strong className="text-white">{point.sector}</strong>
          </p>

          <div className="mt-3 flex flex-wrap items-center gap-2">
            {getStatusBadge(point.estE)}
            <span className="text-[11px] bg-slate-800 text-slate-200 px-2.5 py-1 rounded-full font-mono font-semibold border border-slate-700">
              📍 {formattedDist} • {walkTime}
            </span>
          </div>
        </div>

        {/* Scrollable Content */}
        <div className="p-5 overflow-y-auto space-y-4 custom-scrollbar flex-1 bg-slate-50/50">
          
          {/* Quality Alert Banner */}
          {needsTreatment ? (
            <div className="p-3.5 rounded-2xl bg-amber-50 border border-amber-200 text-amber-900 flex items-start gap-3">
              <AlertTriangle className="w-5 h-5 text-amber-600 shrink-0 mt-0.5" />
              <div className="text-xs leading-relaxed">
                <strong className="font-bold text-amber-950 block mb-0.5">Agua requiere tratamiento obligatorio</strong>
                Hierve el agua a borbotones durante al menos 1 minuto o utiliza la calculadora de cloro en la pestaña <strong>Agua segura</strong> antes de beber.
              </div>
            </div>
          ) : (
            <div className="p-3 rounded-2xl bg-emerald-50 border border-emerald-200 text-emerald-900 flex items-start gap-3">
              <ShieldCheck className="w-5 h-5 text-emerald-600 shrink-0 mt-0.5" />
              <div className="text-xs leading-relaxed">
                <strong className="font-bold text-emerald-950 block mb-0.5">Agua apta para consumo humano directo</strong>
                Punto fiscalizado con control de cloro residual y turbidez bajo estándares sanitarios de SUNASS.
              </div>
            </div>
          )}

          {/* Technical Specs Grid */}
          <div className="grid grid-cols-2 gap-2.5">
            <div className="bg-white p-3 rounded-2xl border border-slate-200 shadow-xs">
              <span className="text-[10px] font-bold text-slate-600 uppercase tracking-wider block flex items-center gap-1">
                <Clock className="w-3 h-3 text-slate-600" /> Horario de Atención
              </span>
              <p className="text-sm font-black text-slate-900 mt-1">{point.horario}</p>
              <p className="text-[10px] text-slate-600">Turno de contingencia</p>
            </div>

            <div className="bg-white p-3 rounded-2xl border border-slate-200 shadow-xs">
              <span className="text-[10px] font-bold text-slate-600 uppercase tracking-wider block flex items-center gap-1">
                <Droplet className="w-3 h-3 text-blue-600" /> Capacidad / Caudal
              </span>
              <p className="text-xs font-black text-slate-900 mt-1 truncate">{point.cap}</p>
              <p className="text-[10px] text-slate-600">Por ciclo de recarga</p>
            </div>

            <div className="bg-white p-3 rounded-2xl border border-slate-200 shadow-xs">
              <span className="text-[10px] font-bold text-slate-600 uppercase tracking-wider block flex items-center gap-1">
                <Truck className="w-3 h-3 text-amber-600" /> Fuente de Abastecimiento
              </span>
              <p className="text-xs font-bold text-slate-900 mt-1 truncate">{point.recarga}</p>
              <p className="text-[10px] text-slate-600">Red troncal certificada</p>
            </div>

            <div className="bg-white p-3 rounded-2xl border border-slate-200 shadow-xs">
              <span className="text-[10px] font-bold text-slate-600 uppercase tracking-wider block flex items-center gap-1">
                <Users className="w-3 h-3 text-emerald-600" /> Población Asignada
              </span>
              <p className="text-sm font-black text-slate-900 mt-1">{point.pobl.toLocaleString('es-PE')} personas</p>
              <p className="text-[10px] text-slate-600">Radio de cobertura directo</p>
            </div>
          </div>

          {/* Access & Verification Info */}
          <div className="bg-white p-3.5 rounded-2xl border border-slate-200 text-xs space-y-2">
            <div className="flex justify-between items-center pb-2 border-b border-slate-100">
              <span className="text-slate-500 font-medium">Accesibilidad de Vía:</span>
              <span className="font-bold text-slate-800 text-right">{point.acceso} ({point.pend})</span>
            </div>
            <div className="flex justify-between items-center pb-2 border-b border-slate-100">
              <span className="text-slate-500 font-medium">Entidad Responsable:</span>
              <span className="font-bold text-slate-800 text-right">{point.resp}</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-slate-500 font-medium">Verificación en Campo:</span>
              <span className={`font-bold ${point.verMeses > 6 ? 'text-amber-700' : 'text-emerald-700'} text-right`}>
                {point.ver} {point.verMeses === 0 ? '(vigente)' : `(hace ${point.verMeses} meses)`}
              </span>
            </div>
          </div>

          {/* Recommended Quota Note */}
          <div className="p-3 bg-blue-50/70 border border-blue-200 rounded-2xl text-xs text-blue-950 flex items-start gap-2.5">
            <Sparkles className="w-4 h-4 text-blue-600 shrink-0 mt-0.5" />
            <div>
              <strong>Recomendación humanitaria (Estándar Esfera):</strong> 15 litros por persona/día. Para una familia de 4 son 60 litros (3 bidones de 20L). Acude preferentemente en las primeras horas del turno.
            </div>
          </div>
        </div>

        {/* Footer Actions with Buttons to Test */}
        <div className="p-4 bg-white border-t border-slate-200 flex flex-wrap sm:flex-nowrap gap-2.5">
          <button
            id="btn-report-point"
            onClick={() => {
              onNavigateToReport(point.id);
              onClose();
            }}
            className="flex-1 py-3 px-3 rounded-2xl font-bold text-xs bg-slate-100 hover:bg-slate-200 text-slate-800 border border-slate-300 flex items-center justify-center gap-1.5 transition-all cursor-pointer"
          >
            <MessageSquareWarning className="w-4 h-4 text-amber-600" />
            Reportar Falla o Fuga
          </button>

          <button
            id="btn-copy-point"
            onClick={handleCopyInfo}
            className="py-3 px-3 rounded-2xl font-bold text-xs bg-slate-100 hover:bg-slate-200 text-slate-700 border border-slate-300 flex items-center justify-center gap-1.5 transition-all cursor-pointer"
            title="Copiar datos al portapapeles"
          >
            <Share2 className="w-4 h-4 text-slate-600" />
            {copied ? '¡Copiado!' : 'Compartir'}
          </button>

          <button
            id="btn-close-modal"
            onClick={onClose}
            className="py-3 px-5 rounded-2xl font-bold text-xs bg-red-600 hover:bg-red-700 text-white shadow-md shadow-red-600/20 flex items-center justify-center gap-1.5 transition-all cursor-pointer"
          >
            <Navigation className="w-4 h-4 text-white" />
            Entendido
          </button>
        </div>
      </div>
    </div>
  );
};
