import React from 'react';
import { UserLocation, WaterPoint } from '../types';
import { USER_LOCATIONS } from '../data/waterPoints';
import { 
  Wifi, 
  WifiOff, 
  AlertTriangle, 
  ShieldCheck, 
  RotateCcw, 
  Sparkles, 
  CheckCircle2, 
  Truck, 
  Navigation, 
  Radio, 
  BellRing, 
  Layers, 
  Compass, 
  MapPin, 
  Smartphone,
  ExternalLink
} from 'lucide-react';

interface TestingConsoleProps {
  isEmergency: boolean;
  isOnline: boolean;
  userLocation: UserLocation;
  queuedReportsCount: number;
  onToggleEmergency: () => void;
  onToggleOnline: () => void;
  onLocationChange: (loc: UserLocation) => void;
  onSimulateCisternaArrival: () => void;
  onSimulateOutagePoint: () => void;
  onGenerateTestReport: () => void;
  onResetAll: () => void;
  onTriggerAudioAlert: () => void;
  points: WaterPoint[];
}

export const TestingConsole: React.FC<TestingConsoleProps> = ({
  isEmergency,
  isOnline,
  userLocation,
  queuedReportsCount,
  onToggleEmergency,
  onToggleOnline,
  onLocationChange,
  onSimulateCisternaArrival,
  onSimulateOutagePoint,
  onGenerateTestReport,
  onResetAll,
  onTriggerAudioAlert,
  points
}) => {
  return (
    <div className="space-y-6">
      
      {/* INSTITUTIONAL HEADER & STRATEGIC PITCH */}
      <div className="bg-white rounded-3xl p-6 border border-slate-200 shadow-sm relative overflow-hidden">
        <div className="absolute top-0 right-0 w-80 h-full bg-gradient-to-l from-red-50/70 via-emerald-50/40 to-transparent pointer-events-none"></div>
        
        <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <div className="flex flex-wrap items-center gap-2 mb-2">
              <span className="px-3 py-0.5 bg-red-50 text-red-700 border border-red-200 rounded-full text-[11px] font-bold tracking-wide uppercase flex items-center gap-1.5">
                <ShieldCheck className="w-3.5 h-3.5 text-red-600" /> GRD
              </span>
              <span className="px-3 py-0.5 bg-amber-50 text-amber-900 border border-amber-300 rounded-full text-[11px] font-bold tracking-wide uppercase flex items-center gap-1.5">
                <Sparkles className="w-3.5 h-3.5 text-amber-600" /> Estratégico
              </span>
              <span className="px-3 py-0.5 bg-emerald-50 text-emerald-900 border border-emerald-300 rounded-full text-[11px] font-bold tracking-wide uppercase flex items-center gap-1.5">
                <Radio className="w-3.5 h-3.5 text-emerald-600" /> 100% Offline
              </span>
            </div>

            <h2 className="text-2xl sm:text-3xl font-black tracking-tight text-slate-900">
              Agua<span className="text-transparent bg-clip-text bg-gradient-to-r from-red-600 via-rose-600 to-slate-900">CION</span>
            </h2>
            <p className="text-slate-600 mt-1 text-xs sm:text-sm max-w-xl leading-relaxed">
              Consola interactiva para <strong>probar todos los botones</strong> y simular la respuesta ciudadana en corte total de telecomunicaciones.
            </p>
          </div>

          {/* Quick-Win Badge */}
          <div className="bg-slate-50 p-3.5 rounded-2xl border border-slate-200/90 shrink-0 text-left md:text-right">
            <p className="text-xs font-black text-slate-900">De Regulador a Líder Humanitario</p>
            <span className="inline-flex items-center gap-1 text-[11px] bg-red-600 text-white font-semibold px-2.5 py-1 rounded-lg mt-1 shadow-xs">
              <Sparkles className="w-3 h-3 text-amber-300" /> Quick win validado
            </span>
          </div>
        </div>
      </div>

      {/* CORE TESTING PANEL: BUTTONS SUITE */}
      <div className="bg-white rounded-3xl p-6 border border-slate-200 shadow-sm space-y-5">
        <div className="flex items-center justify-between border-b border-slate-100 pb-3">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-xl bg-red-100 text-red-600 flex items-center justify-center font-bold">
              <Radio className="w-4 h-4" />
            </div>
            <div>
              <h3 className="text-base font-extrabold text-slate-900">
                Botonera de Control y Escenarios
              </h3>
              <p className="text-xs text-slate-500">
                Presiona los botones para verificar la reactividad inmediata del prototipo
              </p>
            </div>
          </div>

          <button
            id="btn-reset-test-state"
            onClick={onResetAll}
            className="px-3 py-1.5 rounded-xl border border-slate-200 bg-slate-50 hover:bg-slate-100 text-slate-700 text-xs font-bold flex items-center gap-1.5 transition-colors cursor-pointer"
            title="Restablecer todos los datos a valores iniciales"
          >
            <RotateCcw className="w-3.5 h-3.5" />
            Reiniciar Todo
          </button>
        </div>

        {/* Primary Toggle Switches */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
          
          {/* Switch 1: Internet Cut-off */}
          <div 
            id="test-btn-toggle-net"
            onClick={onToggleOnline}
            className={`p-4 rounded-2xl border-2 transition-all cursor-pointer flex items-center justify-between gap-3 ${
              !isOnline 
                ? 'bg-slate-900 text-white border-slate-950 shadow-md' 
                : 'bg-emerald-50/60 text-emerald-950 border-emerald-300 hover:bg-emerald-50'
            }`}
          >
            <div>
              <div className="flex items-center gap-1.5">
                {!isOnline ? <WifiOff className="w-4 h-4 text-red-400" /> : <Wifi className="w-4 h-4 text-emerald-600" />}
                <span className="text-xs font-extrabold">
                  {!isOnline ? 'Internet Cortado (Modo Offline)' : 'Internet Disponible (Online)'}
                </span>
              </div>
              <p className={`text-[11px] mt-1 ${!isOnline ? 'text-slate-300' : 'text-emerald-800'}`}>
                {!isOnline 
                  ? 'App operando 100% con GPS y mapa guardado.' 
                  : 'Sincronización directa con servidores EPS.'}
              </p>
            </div>

            {/* Visual toggle pill */}
            <div className={`w-11 h-6 rounded-full transition-colors relative shrink-0 ${!isOnline ? 'bg-red-600' : 'bg-slate-300'}`}>
              <div className={`w-4 h-4 rounded-full bg-white absolute top-1 transition-transform ${!isOnline ? 'left-6' : 'left-1'}`}></div>
            </div>
          </div>

          {/* Switch 2: Emergency / Earthquake Mode */}
          <div 
            id="test-btn-toggle-emg"
            onClick={onToggleEmergency}
            className={`p-4 rounded-2xl border-2 transition-all cursor-pointer flex items-center justify-between gap-3 ${
              isEmergency 
                ? 'bg-red-600 text-white border-red-700 shadow-md' 
                : 'bg-slate-50 text-slate-900 border-slate-200 hover:bg-slate-100'
            }`}
          >
            <div>
              <div className="flex items-center gap-1.5">
                <AlertTriangle className={`w-4 h-4 ${isEmergency ? 'text-amber-300 animate-bounce' : 'text-slate-500'}`} />
                <span className="text-xs font-extrabold">
                  {isEmergency ? 'Alerta Sísmica Activa (≥ 8.5 Mw)' : 'Modo Uso Habitual / Normal'}
                </span>
              </div>
              <p className={`text-[11px] mt-1 ${isEmergency ? 'text-red-100' : 'text-slate-500'}`}>
                {isEmergency 
                  ? 'Red de agua en crisis. Racionamiento y cisternas.' 
                  : 'Horarios regulares de abastecimiento diario.'}
              </p>
            </div>

            {/* Visual toggle pill */}
            <div className={`w-11 h-6 rounded-full transition-colors relative shrink-0 ${isEmergency ? 'bg-slate-950' : 'bg-slate-300'}`}>
              <div className={`w-4 h-4 rounded-full bg-white absolute top-1 transition-transform ${isEmergency ? 'left-6' : 'left-1'}`}></div>
            </div>
          </div>

        </div>

        {/* GPS Location Simulator Buttons */}
        <div>
          <label className="text-xs font-bold text-slate-800 uppercase tracking-wider block mb-2 flex items-center gap-1.5">
            <Compass className="w-3.5 h-3.5 text-blue-600" />
            Simular Ubicación GPS del Ciudadano:
          </label>
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
            {USER_LOCATIONS.map((loc) => {
              const isSelected = userLocation.sector === loc.sector;
              return (
                <button
                  key={loc.sector}
                  id={`btn-loc-${loc.sector.replace(/\s+/g, '-').toLowerCase()}`}
                  onClick={() => onLocationChange(loc)}
                  className={`p-2.5 rounded-xl text-left border transition-all cursor-pointer ${
                    isSelected 
                      ? 'bg-slate-900 text-white border-slate-900 shadow-xs' 
                      : 'bg-white text-slate-700 border-slate-200 hover:bg-slate-50'
                  }`}
                >
                  <p className="text-xs font-black truncate">{loc.nombre.split('—')[0]}</p>
                  <p className={`text-[10px] truncate ${isSelected ? 'text-slate-300' : 'text-slate-500'}`}>
                    {loc.sector}
                  </p>
                </button>
              );
            })}
          </div>
        </div>

        {/* Quick Scenario Triggers */}
        <div>
          <label className="text-xs font-bold text-slate-800 uppercase tracking-wider block mb-2 flex items-center gap-1.5">
            <Sparkles className="w-3.5 h-3.5 text-amber-600" />
            Prueba de Escenarios y Datos Dinámicos:
          </label>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-2.5">
            
            <button
              id="btn-test-cisterna"
              onClick={onSimulateCisternaArrival}
              className="p-3 bg-emerald-50 hover:bg-emerald-100 text-emerald-900 rounded-xl border border-emerald-200 text-xs font-bold flex items-center gap-2 transition-colors text-left cursor-pointer"
            >
              <Truck className="w-4 h-4 text-emerald-600 shrink-0" />
              <div>
                <span>Simular Cisterna</span>
                <p className="text-[10px] text-emerald-700 font-normal">Habilita Parque del Maestro</p>
              </div>
            </button>

            <button
              id="btn-test-falla"
              onClick={onSimulateOutagePoint}
              className="p-3 bg-amber-50 hover:bg-amber-100 text-amber-900 rounded-xl border border-amber-200 text-xs font-bold flex items-center gap-2 transition-colors text-left cursor-pointer"
            >
              <AlertTriangle className="w-4 h-4 text-amber-600 shrink-0" />
              <div>
                <span>Simular Falla</span>
                <p className="text-[10px] text-amber-700 font-normal">Corta agua en La Alameda</p>
              </div>
            </button>

            <button
              id="btn-test-report"
              onClick={onGenerateTestReport}
              className="p-3 bg-blue-50 hover:bg-blue-100 text-blue-900 rounded-xl border border-blue-200 text-xs font-bold flex items-center gap-2 transition-colors text-left cursor-pointer"
            >
              <Radio className="w-4 h-4 text-blue-600 shrink-0" />
              <div>
                <span>Encolar Reporte</span>
                <p className="text-[10px] text-blue-700 font-normal">Crea reporte offline de prueba</p>
              </div>
            </button>

          </div>
        </div>

      </div>

      {/* STRATEGIC VALUE HIGHLIGHTS: TANIA GRD PILLARS */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        
        <div className="bg-white p-5 rounded-3xl border-l-4 border-l-red-600 border border-slate-200 shadow-sm">
          <span className="text-[10px] font-bold uppercase tracking-wider text-red-700 bg-red-50 px-2.5 py-0.5 rounded-md">
            Amenaza Inminente
          </span>
          <div className="text-2xl font-black text-slate-900 mt-2 mb-1">≥ 8.5 Mw</div>
          <p className="text-xs text-slate-600 leading-relaxed">
            Caída total e inmediata de antenas celulares e internet por varios días tras el sismo.
          </p>
        </div>

        <div className="bg-white p-5 rounded-3xl border-l-4 border-l-amber-500 border border-slate-200 shadow-sm">
          <span className="text-[10px] font-bold uppercase tracking-wider text-amber-800 bg-amber-50 px-2.5 py-0.5 rounded-md">
            El Vacío Regulatorio
          </span>
          <div className="text-2xl font-black text-slate-900 mt-2 mb-1">Datos Inertes</div>
          <p className="text-xs text-slate-600 leading-relaxed">
            Los planes de contingencia EPS duermen en carpetas PDF que la población no puede consultar.
          </p>
        </div>

        <div className="bg-white p-5 rounded-3xl border-l-4 border-l-emerald-600 border border-slate-200 shadow-sm">
          <span className="text-[10px] font-bold uppercase tracking-wider text-emerald-800 bg-emerald-50 px-2.5 py-0.5 rounded-md">
            La Solución Validada
          </span>
          <div className="text-2xl font-black text-slate-900 mt-2 mb-1">100% Offline</div>
          <p className="text-xs text-slate-600 leading-relaxed">
            AguaCION procesa la cartografía de rescate en el chip GPS nativo sin requerir internet.
          </p>
        </div>

      </div>

      {/* STEP-BY-STEP USER JOURNEY */}
      <div className="bg-white rounded-3xl p-6 border border-slate-200 shadow-sm space-y-3">
        <h4 className="text-sm font-black text-slate-900 flex items-center gap-2">
          <Navigation className="w-4 h-4 text-red-600" />
          Experiencia Ciudadana en 3 Pasos
        </h4>
        
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 text-xs">
          <div className="p-3 bg-slate-50 rounded-2xl border border-slate-200">
            <span className="w-5 h-5 rounded-full bg-slate-900 text-white font-extrabold flex items-center justify-center text-[10px] mb-1.5">1</span>
            <strong className="text-slate-900 block font-bold">Descarga Preventiva</strong>
            <p className="text-[11px] text-slate-600 mt-1">
              Guarda el mapa vectorial de tu distrito (&lt; 15 MB) en la memoria del teléfono en tiempos de paz.
            </p>
          </div>

          <div className="p-3 bg-red-50/50 rounded-2xl border border-red-200">
            <span className="w-5 h-5 rounded-full bg-red-600 text-white font-extrabold flex items-center justify-center text-[10px] mb-1.5">2</span>
            <strong className="text-red-950 block font-bold">Caída de Redes</strong>
            <p className="text-[11px] text-slate-600 mt-1">
              Ocurre el sismo y se corta internet. La app se abre instantáneamente usando el sensor satelital.
            </p>
          </div>

          <div className="p-3 bg-emerald-50/50 rounded-2xl border border-emerald-200">
            <span className="w-5 h-5 rounded-full bg-emerald-700 text-white font-extrabold flex items-center justify-center text-[10px] mb-1.5">3</span>
            <strong className="text-emerald-950 block font-bold">Guía a Pie Segura</strong>
            <p className="text-[11px] text-slate-600 mt-1">
              Despliega la ruta más cercana a cisternas fijas, pozos con grupo electrógeno y horarios oficiales.
            </p>
          </div>
        </div>
      </div>

    </div>
  );
};
