import React, { useState, useEffect } from 'react';
import { 
  WaterPoint, 
  UserLocation, 
  CitizenReport, 
  TabView 
} from './types';
import { 
  INITIAL_POINTS, 
  SECTORES_DATA, 
  USER_LOCATIONS 
} from './data/waterPoints';
import { PhoneFrame } from './components/PhoneFrame';
import { PointDetailModal } from './components/PointDetailModal';
import { TestingConsole } from './components/TestingConsole';
import { 
  Smartphone, 
  LayoutDashboard, 
  ShieldCheck, 
  Radio, 
  AlertTriangle, 
  CheckCircle2, 
  RefreshCw,
  BellRing
} from 'lucide-react';

export default function App() {
  // Primary application state
  const [points, setPoints] = useState<WaterPoint[]>(INITIAL_POINTS);
  const [userLocation, setUserLocation] = useState<UserLocation>(USER_LOCATIONS[0]);
  const [isOnline, setIsOnline] = useState<boolean>(true);
  const [isEmergency, setIsEmergency] = useState<boolean>(false);
  const [activeTab, setActiveTab] = useState<TabView>('puntos');
  const [selectedPoint, setSelectedPoint] = useState<WaterPoint | null>(null);
  const [queuedReports, setQueuedReports] = useState<CitizenReport[]>([]);
  const [notificationMsg, setNotificationMsg] = useState<string | null>(null);
  const [viewMode, setViewMode] = useState<'dual' | 'phone-only'>('dual');

  // Trigger brief alert sound simulation (gentle synthetic tone)
  const triggerAudioAlert = () => {
    try {
      const AudioCtx = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
      if (AudioCtx) {
        const ctx = new AudioCtx();
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(520, ctx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(880, ctx.currentTime + 0.18);
        gain.gain.setValueAtTime(0.12, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.35);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start();
        osc.stop(ctx.currentTime + 0.35);
      }
    } catch {
      // Audio context might be restricted before interaction; safe fallback
    }
  };

  // Toggle Emergency / Sismo mode
  const handleToggleEmergency = () => {
    const nextState = !isEmergency;
    setIsEmergency(nextState);
    triggerAudioAlert();
    setNotificationMsg(
      nextState 
        ? '⚠ Alerta sísmica activada: mostrando puntos prioritarios de emergencia y racionamiento' 
        : '✓ Modo regular restablecido: horarios habituales de suministro'
    );
  };

  // Toggle Online / Offline mode
  const handleToggleOnline = () => {
    const nextState = !isOnline;
    setIsOnline(nextState);
    
    // When returning online, flush queued reports
    if (nextState) {
      if (queuedReports.length > 0) {
        setNotificationMsg(
          `✓ Conexión recuperada: ${queuedReports.length} ${queuedReports.length > 1 ? 'reportes sincronizados' : 'reporte sincronizado'} con la EPS.`
        );
        setQueuedReports([]);
      } else {
        setNotificationMsg('✓ Conexión en línea restablecida');
      }
    } else {
      setNotificationMsg('📵 Modo 100% Offline activado: operando exclusivamente con mapa y GPS local');
    }
  };

  // Handle report creation (online vs offline)
  const handleSubmitReport = (newReportData: Omit<CitizenReport, 'id' | 'timestamp' | 'offline'>) => {
    const newReport: CitizenReport = {
      ...newReportData,
      id: `REP-${Date.now()}`,
      timestamp: new Date().toLocaleTimeString('es-PE', { hour: '2-digit', minute: '2-digit' }),
      offline: !isOnline
    };

    if (isOnline) {
      setNotificationMsg(`✓ Reporte enviado inmediatamente a COE EPS y fiscalizadores de SUNASS`);
    } else {
      setQueuedReports(prev => [newReport, ...prev]);
      setNotificationMsg(`✓ Sin señal: reporte guardado en el teléfono. Se sincronizará automáticamente.`);
    }
  };

  // Force sync reports
  const handleSyncReports = () => {
    if (queuedReports.length > 0) {
      setNotificationMsg(`✓ ${queuedReports.length} reportes sincronizados exitosamente`);
      setQueuedReports([]);
    }
  };

  // Simulation scenario: Cisterna arrival at Parque del Maestro
  const handleSimulateCisternaArrival = () => {
    setPoints(prev => prev.map(p => {
      if (p.id === 'MOQ-PE-002') {
        return {
          ...p,
          estE: 'ok',
          estETxt: 'Con agua ahora (Cisterna 02 descargando)'
        };
      }
      return p;
    }));
    triggerAudioAlert();
    setNotificationMsg('🚚 Cisterna 02 llegó a Parque del Maestro: estado actualizado a CON AGUA');
  };

  // Simulation scenario: Outage at La Alameda
  const handleSimulateOutagePoint = () => {
    setPoints(prev => prev.map(p => {
      if (p.id === 'MOQ-PE-004') {
        return {
          ...p,
          estE: 'bad',
          estETxt: 'Presión cero: corte temporal por rotura'
        };
      }
      return p;
    }));
    triggerAudioAlert();
    setNotificationMsg('⚠ Falla simulada en Parque La Alameda: presión de pileta en cero');
  };

  // Simulation scenario: Add test offline report
  const handleGenerateTestReport = () => {
    const randomPoint = points[Math.floor(Math.random() * points.length)];
    const testReport: CitizenReport = {
      id: `TEST-${Date.now().toString().slice(-4)}`,
      puntoId: randomPoint.id,
      puntoNombre: randomPoint.n,
      tipoProblema: 'Cola extensa sin resguardo policial',
      comentario: 'Más de 80 vecinos esperando con baldes, reportado desde la aplicación offline.',
      timestamp: new Date().toLocaleTimeString('es-PE', { hour: '2-digit', minute: '2-digit' }),
      offline: !isOnline,
      sector: randomPoint.sector
    };
    setQueuedReports(prev => [testReport, ...prev]);
    setNotificationMsg(`✓ Reporte de prueba generado y almacenado en memoria local`);
  };

  // Reset all to initial state
  const handleResetAll = () => {
    setPoints(INITIAL_POINTS);
    setUserLocation(USER_LOCATIONS[0]);
    setIsOnline(true);
    setIsEmergency(false);
    setActiveTab('puntos');
    setSelectedPoint(null);
    setQueuedReports([]);
    setNotificationMsg('✓ Prototipo restablecido a valores iniciales');
  };

  // Clear toast notification after timeout
  useEffect(() => {
    if (notificationMsg) {
      const timer = setTimeout(() => {
        setNotificationMsg(null);
      }, 4500);
      return () => clearTimeout(timer);
    }
  }, [notificationMsg]);

  return (
    <div className="min-h-screen bg-slate-900 text-slate-100 flex flex-col selection:bg-red-600 selection:text-white">
      
      {/* TOP NAVIGATION / CONTROL BAR */}
      <header className="bg-slate-950 border-b border-slate-800 px-4 sm:px-8 py-3.5 sticky top-0 z-40">
        <div className="max-w-7xl mx-auto flex flex-wrap items-center justify-between gap-3">
          
          {/* Logo & Brand */}
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-2xl bg-gradient-to-tr from-red-600 to-rose-500 text-white flex items-center justify-center font-black text-lg shadow-lg shadow-red-600/30">
              A
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="text-base sm:text-lg font-black text-white tracking-tight">
                  Agua<span className="text-red-500">CION</span>
                </span>
                <span className="text-[10px] bg-red-950 text-red-300 font-bold px-2 py-0.5 rounded-full border border-red-800/80">
                  100% OFFLINE
                </span>
              </div>
              <p className="text-[11px] text-slate-400 font-medium hidden sm:block">
                Prototipo Funcional de Validación y Prueba de Botones
              </p>
            </div>
          </div>

          {/* Real-time Status Badges & Layout Toggle */}
          <div className="flex items-center gap-2 sm:gap-3">
            
            {/* Online/Offline status button */}
            <button
              id="top-btn-network"
              onClick={handleToggleOnline}
              className={`px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition-all cursor-pointer border ${
                isOnline 
                  ? 'bg-emerald-950/80 text-emerald-300 border-emerald-700/60 hover:bg-emerald-900/60' 
                  : 'bg-red-950 text-red-300 border-red-700 hover:bg-red-900 animate-pulse'
              }`}
              title="Click para alternar corte de internet"
            >
              <Radio className="w-3.5 h-3.5" />
              <span>{isOnline ? 'Online' : 'Offline'}</span>
            </button>

            {/* Emergency mode button */}
            <button
              id="top-btn-emergency"
              onClick={handleToggleEmergency}
              className={`px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition-all cursor-pointer border ${
                isEmergency 
                  ? 'bg-red-600 text-white border-red-500 shadow-md shadow-red-600/30' 
                  : 'bg-slate-800 text-slate-300 border-slate-700 hover:bg-slate-700'
              }`}
              title="Click para alternar alerta de sismo"
            >
              <AlertTriangle className="w-3.5 h-3.5" />
              <span>{isEmergency ? 'Sismo Activo' : 'Normal'}</span>
            </button>

            {/* Layout switch for mobile testing focus */}
            <div className="hidden lg:flex items-center bg-slate-900 p-1 rounded-xl border border-slate-800">
              <button
                id="btn-layout-dual"
                onClick={() => setViewMode('dual')}
                className={`px-2.5 py-1 rounded-lg text-xs font-semibold flex items-center gap-1 transition-all cursor-pointer ${
                  viewMode === 'dual' ? 'bg-slate-700 text-white shadow-xs' : 'text-slate-400 hover:text-white'
                }`}
              >
                <LayoutDashboard className="w-3.5 h-3.5" />
                Dual
              </button>
              <button
                id="btn-layout-phone"
                onClick={() => setViewMode('phone-only')}
                className={`px-2.5 py-1 rounded-lg text-xs font-semibold flex items-center gap-1 transition-all cursor-pointer ${
                  viewMode === 'phone-only' ? 'bg-slate-700 text-white shadow-xs' : 'text-slate-400 hover:text-white'
                }`}
              >
                <Smartphone className="w-3.5 h-3.5" />
                Móvil
              </button>
            </div>

          </div>

        </div>
      </header>

      {/* MAIN CONTENT AREA */}
      <main className="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-8 py-6 sm:py-8">
        <div className={`grid grid-cols-1 ${viewMode === 'dual' ? 'lg:grid-cols-12' : 'max-w-md mx-auto'} gap-8 items-start`}>
          
          {/* STRATEGIC CONSOLE & TEST BOARD (Visible in Dual mode) */}
          {viewMode === 'dual' && (
            <div className="lg:col-span-7 space-y-6 order-2 lg:order-1">
              <TestingConsole
                isEmergency={isEmergency}
                isOnline={isOnline}
                userLocation={userLocation}
                queuedReportsCount={queuedReports.length}
                onToggleEmergency={handleToggleEmergency}
                onToggleOnline={handleToggleOnline}
                onLocationChange={(loc) => {
                  setUserLocation(loc);
                  setNotificationMsg(`📍 Ubicación simulada cambiada a: ${loc.nombre}`);
                }}
                onSimulateCisternaArrival={handleSimulateCisternaArrival}
                onSimulateOutagePoint={handleSimulateOutagePoint}
                onGenerateTestReport={handleGenerateTestReport}
                onResetAll={handleResetAll}
                onTriggerAudioAlert={triggerAudioAlert}
                points={points}
              />
            </div>
          )}

          {/* INTERACTIVE PHONE FRAME PROTOTYPE */}
          <div className={`${viewMode === 'dual' ? 'lg:col-span-5' : 'w-full'} flex flex-col items-center order-1 lg:order-2 sticky top-20`}>
            <PhoneFrame
              points={points}
              sectors={SECTORES_DATA}
              userLocation={userLocation}
              isOnline={isOnline}
              isEmergency={isEmergency}
              activeTab={activeTab}
              selectedPointId={selectedPoint?.id || null}
              queuedReports={queuedReports}
              notificationMsg={notificationMsg}
              onTabChange={(tab) => {
                setActiveTab(tab);
                triggerAudioAlert();
              }}
              onSelectPoint={(point) => setSelectedPoint(point)}
              onSubmitReport={handleSubmitReport}
              onSyncReports={handleSyncReports}
              onUserLocationChange={setUserLocation}
              onToggleEmergency={handleToggleEmergency}
              onToggleOnline={handleToggleOnline}
            />

            <p className="text-xs text-slate-400 text-center mt-3 max-w-xs font-medium">
              <Smartphone className="w-3.5 h-3.5 inline mr-1 text-red-500" />
              Interactúa directamente con la pantalla: cambia de pestañas, toca los puntos, usa las calculadoras y envía reportes.
            </p>
          </div>

        </div>
      </main>

      {/* DETAIL MODAL (Opens when clicking any water point card or map pin) */}
      {selectedPoint && (
        <PointDetailModal
          point={selectedPoint}
          userLat={userLocation.lat}
          userLon={userLocation.lon}
          emergencyMode={isEmergency}
          onClose={() => setSelectedPoint(null)}
          onNavigateToReport={(pointId) => {
            setSelectedPoint(null);
            setActiveTab('reportar');
          }}
        />
      )}

      {/* FOOTER */}
      <footer className="bg-slate-950 border-t border-slate-800 text-slate-400 py-5 px-4 sm:px-8 mt-12 text-xs">
        <div className="max-w-7xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-3 text-center sm:text-left">
          <div className="flex items-center gap-2">
            <span className="font-extrabold text-white">AguaCION</span>
            <span>•</span>
            <span>Red Preventiva de Agua Segura 100% Offline</span>
          </div>
          <p className="text-slate-400">
            Diseño optimizado para SUNASS y EPS • Basado en el marco de Gestión del Riesgo de Desastres
          </p>
        </div>
      </footer>

    </div>
  );
}
