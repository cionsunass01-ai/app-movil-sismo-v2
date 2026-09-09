import React, { useState, useMemo } from 'react';
import { 
  WaterPoint, 
  SectorData, 
  UserLocation, 
  CitizenReport, 
  TabView, 
  PointType 
} from '../types';
import { 
  calculateDistanceMeters, 
  formatDistance, 
  formatWalkingTime 
} from '../data/waterPoints';
import { 
  Droplet, 
  Map as MapIcon, 
  Clock, 
  ShieldCheck, 
  Send, 
  Wifi, 
  WifiOff, 
  AlertTriangle, 
  Search, 
  ChevronRight, 
  Filter, 
  Check, 
  Navigation, 
  LocateFixed, 
  Plus, 
  Minus, 
  Info, 
  Layers, 
  CheckCircle2, 
  Flame, 
  HelpCircle,
  FileCheck,
  Building2,
  RefreshCw,
  BellRing
} from 'lucide-react';

interface PhoneFrameProps {
  points: WaterPoint[];
  sectors: SectorData[];
  userLocation: UserLocation;
  isOnline: boolean;
  isEmergency: boolean;
  activeTab: TabView;
  selectedPointId: string | null;
  queuedReports: CitizenReport[];
  notificationMsg: string | null;
  onTabChange: (tab: TabView) => void;
  onSelectPoint: (point: WaterPoint) => void;
  onSubmitReport: (report: Omit<CitizenReport, 'id' | 'timestamp' | 'offline'>) => void;
  onSyncReports: () => void;
  onUserLocationChange: (loc: UserLocation) => void;
  onToggleEmergency: () => void;
  onToggleOnline: () => void;
}

export const PhoneFrame: React.FC<PhoneFrameProps> = ({
  points,
  sectors,
  userLocation,
  isOnline,
  isEmergency,
  activeTab,
  selectedPointId,
  queuedReports,
  notificationMsg,
  onTabChange,
  onSelectPoint,
  onSubmitReport,
  onSyncReports,
  onUserLocationChange,
  onToggleEmergency,
  onToggleOnline
}) => {
  // Filters & State
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedTypeFilter, setSelectedTypeFilter] = useState<'all' | PointType | 'conAgua'>('all');
  const [showRouteOnMap, setShowRouteOnMap] = useState(true);
  const [activeMapPinId, setActiveMapPinId] = useState<string | null>(selectedPointId || points[0]?.id || null);

  // Calculator states
  const [calcPersons, setCalcPersons] = useState(4);
  const [calcDays, setCalcDays] = useState(3);
  const [calcMode, setCalcMode] = useState<'esfera' | 'supervivencia'>('esfera'); // 15L vs 7.5L
  const [bleachVolume, setBleachVolume] = useState(20);
  const [bleachConcentration, setBleachConcentration] = useState(5); // 5%
  const [copiedDosage, setCopiedDosage] = useState(false);

  // Report Form state
  const [reportPointId, setReportPointId] = useState<string>(points[0]?.id || '');
  const [reportType, setReportType] = useState('El punto no tiene agua disponible');
  const [reportComment, setReportComment] = useState('');

  // Calculate dynamic distances from current user location
  const pointsWithDistance = useMemo(() => {
    return points.map(p => {
      const dist = calculateDistanceMeters(userLocation.lat, userLocation.lon, p.lat, p.lon);
      return { ...p, distMeters: dist };
    }).sort((a, b) => (a.distMeters ?? 0) - (b.distMeters ?? 0));
  }, [points, userLocation]);

  // Filtered points
  const filteredPoints = useMemo(() => {
    return pointsWithDistance.filter(p => {
      const matchesSearch = 
        p.n.toLowerCase().includes(searchTerm.toLowerCase()) ||
        p.sector.toLowerCase().includes(searchTerm.toLowerCase()) ||
        p.ref.toLowerCase().includes(searchTerm.toLowerCase()) ||
        p.tipo.toLowerCase().includes(searchTerm.toLowerCase());

      if (!matchesSearch) return false;

      if (selectedTypeFilter === 'all') return true;
      if (selectedTypeFilter === 'conAgua') {
        return isEmergency ? p.estE === 'ok' : true;
      }
      return p.tipo === selectedTypeFilter;
    });
  }, [pointsWithDistance, searchTerm, selectedTypeFilter, isEmergency]);

  // Stats
  const activePointsCount = pointsWithDistance.filter(p => isEmergency ? p.estE === 'ok' : true).length;
  const currentSectorData = sectors.find(s => s.n === userLocation.sector) || sectors[0];
  const nearestPoint = pointsWithDistance[0];

  // Water calculations
  const quotaPerPersonPerDay = calcMode === 'esfera' ? 15 : 7.5;
  const totalWaterNeeded = calcPersons * calcDays * quotaPerPersonPerDay;
  const jugsOf20L = Math.ceil(totalWaterNeeded / 20);

  // Bleach calculations: target ~2 mg/L free chlorine
  // Formula: mL = (liters * 2 mg/L) / (concentration% * 10)
  const bleachMl = (bleachVolume * 2) / (bleachConcentration * 10);
  const bleachDrops = Math.round(bleachMl * 20); // 1 mL ~ 20 drops

  const handleCopyDosage = () => {
    const text = `Protocolo AguaCION: Para ${bleachVolume} litros de agua, agregar ${bleachMl.toFixed(1)} mL (aprox. ${bleachDrops} gotas) de lejía al ${bleachConcentration}%. Mezclar, tapar y reposar 30 minutos antes de beber.`;
    navigator.clipboard?.writeText(text);
    setCopiedDosage(true);
    setTimeout(() => setCopiedDosage(false), 2200);
  };

  const handleReportSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const targetPoint = points.find(p => p.id === reportPointId);
    onSubmitReport({
      puntoId: reportPointId,
      puntoNombre: targetPoint ? targetPoint.n : 'Punto no especificado',
      tipoProblema: reportType,
      comentario: reportComment,
      sector: targetPoint?.sector || userLocation.sector
    });
    setReportComment('');
  };

  return (
    <div className="w-full max-w-[420px] bg-slate-900 rounded-[48px] p-2.5 shadow-[0_25px_70px_rgba(0,0,0,0.6)] border-[4px] border-slate-700/80 relative flex flex-col mx-auto select-none">
      
      {/* Side Hardware Buttons visual decoration */}
      <div className="hidden sm:block absolute -left-[7px] top-24 w-[3px] h-8 bg-slate-600 rounded-l-sm"></div>
      <div className="hidden sm:block absolute -left-[7px] top-36 w-[3px] h-12 bg-slate-600 rounded-l-sm"></div>
      <div className="hidden sm:block absolute -right-[7px] top-28 w-[3px] h-16 bg-slate-600 rounded-r-sm"></div>

      {/* Phone Screen Container */}
      <div className="bg-slate-50 rounded-[38px] overflow-hidden flex flex-col h-[780px] relative border border-slate-200">
        
        {/* TOP SYSTEM STATUS BAR */}
        <div className="bg-slate-950 text-white px-5 pt-3 pb-2 shrink-0">
          <div className="flex justify-between items-center text-[11px] font-semibold tracking-tight">
            <span className="font-mono text-slate-200">13:14</span>
            
            {/* Notch / Dynamic Island */}
            <div className="w-24 h-4 bg-black rounded-full flex items-center justify-between px-2 gap-1.5 shadow-sm border border-slate-800">
              <div className="w-1.5 h-1.5 rounded-full bg-slate-700"></div>
              <span className="text-[8px] font-mono text-slate-400">GPS</span>
              <div className={`w-1.5 h-1.5 rounded-full ${isEmergency ? 'bg-red-500 animate-pulse' : 'bg-emerald-500'}`}></div>
            </div>

            {/* Offline / Online Status Badge with interactive toggle hint */}
            <button 
              onClick={onToggleOnline}
              title="Click para cambiar modo de conexión"
              className="flex items-center gap-1 cursor-pointer hover:opacity-80 transition-opacity"
            >
              {isOnline ? (
                <span className="bg-emerald-600 text-white font-bold px-1.5 py-0.5 rounded text-[9px] flex items-center gap-1">
                  <Wifi className="w-2.5 h-2.5" /> ONLINE
                </span>
              ) : (
                <span className="bg-red-600 text-white font-extrabold px-1.5 py-0.5 rounded text-[9px] flex items-center gap-1 animate-pulse">
                  <WifiOff className="w-2.5 h-2.5" /> 100% OFFLINE
                </span>
              )}
            </button>
          </div>
        </div>

        {/* CONNECTIVITY STRIP */}
        <div className={`px-4 py-1.5 text-[11px] font-semibold flex items-center justify-between transition-colors shrink-0 ${
          isOnline ? 'bg-emerald-50 text-emerald-900 border-b border-emerald-200' : 'bg-slate-900 text-slate-100 border-b border-slate-800'
        }`}>
          <div className="flex items-center gap-1.5 truncate">
            <span className={`w-2 h-2 rounded-full shrink-0 ${isOnline ? 'bg-emerald-500' : 'bg-amber-400'}`}></span>
            <span className="truncate">
              {isOnline 
                ? 'Conectado — Datos de campo actualizados hoy' 
                : 'Sin señal celular — Navegación vectorial 100% offline'}
            </span>
          </div>
          {queuedReports.length > 0 && (
            <span className="bg-amber-500 text-slate-950 font-black text-[9px] px-1.5 py-0.2 rounded-full shrink-0">
              {queuedReports.length} en cola
            </span>
          )}
        </div>

        {/* EMERGENCY BANNER (Active when Earthquake/Emergency) */}
        {isEmergency && (
          <div 
            onClick={onToggleEmergency}
            className="bg-red-600 text-white px-4 py-2 text-xs flex items-center justify-between cursor-pointer hover:bg-red-700 transition-colors shrink-0 shadow-md"
            title="Toca para cambiar estado de emergencia"
          >
            <div className="flex items-center gap-2">
              <div className="w-5 h-5 rounded-full bg-white text-red-600 flex items-center justify-center font-black text-xs shrink-0 animate-bounce">
                !
              </div>
              <div>
                <p className="font-extrabold text-[11px] leading-tight">EMERGENCIA ACTIVA — SISMO ≥ 8.5 Mw</p>
                <p className="text-[10px] text-red-100 leading-tight">Red colapsada. Reparto prioritario en parques y cisternas.</p>
              </div>
            </div>
            <span className="text-[10px] bg-red-800/80 px-2 py-0.5 rounded font-mono font-bold">ALERTA</span>
          </div>
        )}

        {/* NOTIFICATION TOAST (when report sent or synced) */}
        {notificationMsg && (
          <div className="bg-emerald-600 text-white px-4 py-2 text-xs font-bold flex items-center gap-2 shrink-0 animate-in slide-in-from-top duration-200 shadow-lg">
            <Check className="w-4 h-4 shrink-0" />
            <span className="flex-1">{notificationMsg}</span>
          </div>
        )}

        {/* APP HEADER */}
        <div className="bg-gradient-to-r from-slate-950 via-slate-900 to-red-950 px-4 py-3 text-white shrink-0 shadow-sm">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-xl bg-red-600 flex items-center justify-center text-white font-black text-xs shadow-md shadow-red-600/30">
                <Droplet className="w-4 h-4 text-white" />
              </div>
              <div>
                <h1 className="text-base font-black tracking-tight leading-none text-white flex items-center gap-1.5">
                  Agua<span className="text-red-500 font-extrabold">CION</span>
                </h1>
                <p className="text-[9px] text-slate-300 font-medium">
                  Red Cartográfica de Agua Segura • Moquegua
                </p>
              </div>
            </div>

            <div className="text-right">
              <span className="text-[9px] bg-white/10 text-slate-200 border border-white/20 font-bold px-2 py-0.5 rounded-full flex items-center gap-1">
                <ShieldCheck className="w-2.5 h-2.5 text-emerald-400" />
                SUNASS
              </span>
            </div>
          </div>

          {/* Current Location Pill with Switcher */}
          <div className="mt-2.5 bg-white/10 backdrop-blur-xs rounded-xl p-2 flex items-center justify-between border border-white/10 text-[11px]">
            <div className="flex items-center gap-1.5 text-slate-200 truncate">
              <LocateFixed className="w-3.5 h-3.5 text-red-400 shrink-0 animate-pulse" />
              <span className="truncate">
                Cerca de: <strong className="text-white">{userLocation.nombre}</strong>
              </span>
            </div>
            
            {/* Quick Sector indicator */}
            <span className="text-[9px] bg-red-500/20 text-red-300 px-1.5 py-0.5 rounded font-mono shrink-0">
              GPS OK
            </span>
          </div>
        </div>

        {/* DYNAMIC SCROLLABLE BODY VIEW */}
        <div className="flex-1 overflow-y-auto custom-scrollbar bg-slate-100 flex flex-col">
          
          {/* TAB 1: PUNTOS (List View) */}
          {activeTab === 'puntos' && (
            <div className="p-3.5 space-y-3">
              
              {/* Emergency Stat Card */}
              {isEmergency && (
                <div className="bg-white p-3.5 rounded-2xl border border-slate-200 shadow-xs flex items-center justify-between">
                  <div>
                    <span className="text-2xl font-black text-slate-900 leading-none">
                      {activePointsCount} <span className="text-xs font-semibold text-slate-500">de {points.length}</span>
                    </span>
                    <p className="text-[11px] text-slate-600 font-medium mt-0.5">
                      Puntos con agua activa ahora mismo en la ciudad
                    </p>
                  </div>
                  <div className="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-700 flex items-center justify-center font-bold">
                    <Droplet className="w-5 h-5 text-emerald-600" />
                  </div>
                </div>
              )}

              {/* Search & Filter Bar */}
              <div className="space-y-2">
                <div className="relative">
                  <Search className="w-4 h-4 text-slate-600 absolute left-3 top-2.5" />
                  <input
                    id="search-points"
                    type="text"
                    placeholder="Buscar parque, sector, cisterna..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="w-full pl-9 pr-3 py-2 bg-white rounded-xl border border-slate-200 text-xs font-medium text-slate-800 placeholder:text-slate-600 focus:outline-none focus:border-red-500"
                  />
                  {searchTerm && (
                    <button
                      onClick={() => setSearchTerm('')}
                      className="absolute right-2.5 top-2 text-slate-600 hover:text-slate-800 text-xs font-bold"
                    >
                      ×
                    </button>
                  )}
                </div>

                {/* Filter Chips - Button Testing */}
                <div className="flex items-center gap-1.5 overflow-x-auto pb-1 text-[11px] custom-scrollbar">
                  <button
                    id="btn-filter-all"
                    onClick={() => setSelectedTypeFilter('all')}
                    className={`px-2.5 py-1 rounded-full font-bold whitespace-nowrap cursor-pointer transition-all ${
                      selectedTypeFilter === 'all' 
                        ? 'bg-slate-900 text-white shadow-xs' 
                        : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-50'
                    }`}
                  >
                    Todos ({points.length})
                  </button>

                  <button
                    id="btn-filter-conagua"
                    onClick={() => setSelectedTypeFilter('conAgua')}
                    className={`px-2.5 py-1 rounded-full font-bold whitespace-nowrap cursor-pointer transition-all flex items-center gap-1 ${
                      selectedTypeFilter === 'conAgua' 
                        ? 'bg-emerald-600 text-white shadow-xs' 
                        : 'bg-white text-emerald-800 border border-emerald-200 hover:bg-emerald-50'
                    }`}
                  >
                    <span className="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                    Con agua ({activePointsCount})
                  </button>

                  <button
                    id="btn-filter-cisterna"
                    onClick={() => setSelectedTypeFilter('Punto de cisterna')}
                    className={`px-2.5 py-1 rounded-full font-bold whitespace-nowrap cursor-pointer transition-all ${
                      selectedTypeFilter === 'Punto de cisterna' 
                        ? 'bg-blue-600 text-white shadow-xs' 
                        : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-50'
                    }`}
                  >
                    Cisternas
                  </button>

                  <button
                    id="btn-filter-pileta"
                    onClick={() => setSelectedTypeFilter('Pileta pública')}
                    className={`px-2.5 py-1 rounded-full font-bold whitespace-nowrap cursor-pointer transition-all ${
                      selectedTypeFilter === 'Pileta pública' 
                        ? 'bg-blue-600 text-white shadow-xs' 
                        : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-50'
                    }`}
                  >
                    Piletas
                  </button>

                  <button
                    id="btn-filter-surtidor"
                    onClick={() => setSelectedTypeFilter('Surtidor fijo')}
                    className={`px-2.5 py-1 rounded-full font-bold whitespace-nowrap cursor-pointer transition-all ${
                      selectedTypeFilter === 'Surtidor fijo' 
                        ? 'bg-blue-600 text-white shadow-xs' 
                        : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-50'
                    }`}
                  >
                    Pozos / PTAP
                  </button>
                </div>
              </div>

              {/* Point Cards List */}
              <div className="space-y-2.5">
                <p className="text-[10px] font-bold text-slate-600 uppercase tracking-wider flex items-center justify-between">
                  <span>Ordenados por cercanía a tu ubicación actual</span>
                  <span>{filteredPoints.length} resultados</span>
                </p>

                {filteredPoints.map((point) => {
                  const dist = point.distMeters ?? 0;
                  const isSafe = point.estE === 'ok';
                  const isWarn = point.estE === 'warn';

                  return (
                    <div
                      key={point.id}
                      id={`card-point-${point.id}`}
                      onClick={() => onSelectPoint(point)}
                      className="bg-white rounded-2xl p-3.5 border border-slate-200 hover:border-slate-300 shadow-xs hover:shadow-md transition-all cursor-pointer group relative"
                    >
                      <div className="flex justify-between items-start gap-2">
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-1.5 mb-1">
                            <span className="text-[9px] font-bold text-slate-700 uppercase bg-slate-100 px-1.5 py-0.5 rounded">
                              {point.tipo}
                            </span>
                            <span className="text-[10px] text-slate-600 font-medium truncate">
                              {point.sector}
                            </span>
                          </div>

                          <h2 className="text-sm font-bold text-slate-900 leading-tight group-hover:text-red-700 transition-colors truncate">
                            {point.n}
                          </h2>
                          <p className="text-[11px] text-slate-600 truncate mt-0.5">
                            {point.ref}
                          </p>
                        </div>

                        {/* Distance & Walking Time */}
                        <div className="text-right shrink-0 bg-slate-50 px-2.5 py-1.5 rounded-xl border border-slate-100">
                          <span className="text-sm font-black text-slate-900 block leading-tight">
                            {formatDistance(dist)}
                          </span>
                          <span className="text-[9px] font-semibold text-slate-600 uppercase block">
                            {formatWalkingTime(dist)}
                          </span>
                        </div>
                      </div>

                      {/* Status and Verification strip */}
                      <div className="mt-2.5 pt-2 border-t border-slate-100 flex items-center justify-between gap-2">
                        <div>
                          {isEmergency ? (
                            isSafe ? (
                              <span className="inline-flex items-center gap-1 text-[10px] font-bold text-emerald-800 bg-emerald-50 px-2 py-0.5 rounded-md border border-emerald-200">
                                <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></span>
                                {point.estETxt}
                              </span>
                            ) : isWarn ? (
                              <span className="inline-flex items-center gap-1 text-[10px] font-bold text-amber-800 bg-amber-50 px-2 py-0.5 rounded-md border border-amber-200">
                                <AlertTriangle className="w-2.5 h-2.5 text-amber-600" />
                                {point.estETxt}
                              </span>
                            ) : (
                              <span className="inline-flex items-center gap-1 text-[10px] font-bold text-red-800 bg-red-50 px-2 py-0.5 rounded-md border border-red-200">
                                <AlertTriangle className="w-2.5 h-2.5 text-red-600" />
                                {point.estETxt}
                              </span>
                            )
                          ) : (
                            <span className="inline-flex items-center gap-1 text-[10px] font-bold text-blue-800 bg-blue-50 px-2 py-0.5 rounded-md border border-blue-200">
                              <CheckCircle2 className="w-2.5 h-2.5 text-blue-600" />
                              {point.estN}
                            </span>
                          )}
                        </div>

                        <span className="text-[10px] text-slate-600 flex items-center gap-1">
                          Verificado: <strong className={point.verMeses > 6 ? 'text-amber-700' : 'text-slate-700'}>{point.ver}</strong>
                          <ChevronRight className="w-3 h-3 text-slate-600" />
                        </span>
                      </div>
                    </div>
                  );
                })}
              </div>

            </div>
          )}

          {/* TAB 2: MAPA (Interactive Offline Vector Cartography) */}
          {activeTab === 'mapa' && (
            <div className="flex-1 flex flex-col relative h-full">
              
              {/* Map Info Bar */}
              <div className="bg-white/95 px-3.5 py-2 border-b border-slate-200 flex items-center justify-between text-xs z-10 shrink-0">
                <span className="text-[11px] font-bold text-slate-800 flex items-center gap-1.5">
                  <MapIcon className="w-3.5 h-3.5 text-red-600" />
                  Cartografía Vectorial Offline
                </span>
                <button
                  id="btn-toggle-route"
                  onClick={() => setShowRouteOnMap(!showRouteOnMap)}
                  className={`text-[10px] font-bold px-2 py-1 rounded-lg border cursor-pointer transition-colors ${
                    showRouteOnMap 
                      ? 'bg-emerald-50 text-emerald-800 border-emerald-200' 
                      : 'bg-slate-100 text-slate-600 border-slate-200'
                  }`}
                >
                  {showRouteOnMap ? '✓ Ruta segura visible' : 'Mostrar ruta a pie'}
                </button>
              </div>

              {/* Realistic Interactive SVG Vector Map */}
              <div className="relative flex-1 bg-[#eae6dc] overflow-hidden min-h-[360px]">
                <svg
                  className="w-full h-full cursor-grab active:cursor-grabbing"
                  viewBox="0 0 400 380"
                  preserveAspectRatio="xMidYMid slice"
                >
                  <defs>
                    <pattern id="urbanGrid" width="20" height="20" patternUnits="userSpaceOnUse">
                      <path d="M 20 0 L 0 0 0 20" fill="none" stroke="#ded8cc" strokeWidth="0.8" />
                    </pattern>
                  </defs>
                  
                  {/* Background Grid */}
                  <rect width="100%" height="100%" fill="url(#urbanGrid)" />

                  {/* Urban Blocks Background */}
                  <rect x="20" y="20" width="75" height="65" rx="6" fill="#ded7ca" stroke="#cfc7b8" strokeWidth="1.5" />
                  <rect x="110" y="20" width="95" height="65" rx="6" fill="#ded7ca" stroke="#cfc7b8" strokeWidth="1.5" />
                  <rect x="220" y="20" width="160" height="50" rx="6" fill="#ded7ca" stroke="#cfc7b8" strokeWidth="1.5" />

                  {/* Rio Moquegua (River Channel across city) */}
                  <path 
                    d="M -10 170 C 80 160, 160 210, 240 240 S 330 280, 420 290" 
                    stroke="#b6d8e8" 
                    strokeWidth="20" 
                    fill="none" 
                    strokeLinecap="round" 
                  />
                  <path 
                    d="M -10 170 C 80 160, 160 210, 240 240 S 330 280, 420 290" 
                    stroke="#8dbed8" 
                    strokeWidth="2" 
                    fill="none" 
                    strokeDasharray="6 4" 
                  />
                  <text x="310" y="275" fontSize="8" fill="#5089a8" fontWeight="800">RÍO MOQUEGUA</text>

                  {/* Green Park Areas (Safe Gathering Hubs) */}
                  {/* Alameda & Plaza Area */}
                  <rect x="120" y="100" width="130" height="90" rx="10" fill="#c4e2bd" stroke="#9bc791" strokeWidth="2" />
                  <circle cx="145" cy="125" r="8" fill="#8cb981" opacity="0.8" />
                  <circle cx="225" cy="160" r="10" fill="#8cb981" opacity="0.8" />
                  <text x="135" y="145" fontSize="8" fill="#205c21" fontWeight="800">PARQUE LA ALAMEDA</text>

                  {/* Chen Chen Park Area */}
                  <rect x="240" y="80" width="140" height="80" rx="10" fill="#c4e2bd" stroke="#9bc791" strokeWidth="2" />
                  <text x="255" y="125" fontSize="8" fill="#205c21" fontWeight="800">PARQUE CHEN CHEN</text>

                  {/* Main Avenues / Roads */}
                  <line x1="105" y1="0" x2="105" y2="380" stroke="#ffffff" strokeWidth="12" />
                  <line x1="105" y1="0" x2="105" y2="380" stroke="#cfc7b8" strokeWidth="1" strokeDasharray="5,5" />
                  
                  <line x1="225" y1="0" x2="225" y2="380" stroke="#ffffff" strokeWidth="12" />
                  <line x1="225" y1="0" x2="225" y2="380" stroke="#cfc7b8" strokeWidth="1" strokeDasharray="5,5" />

                  <line x1="0" y1="92" x2="400" y2="92" stroke="#ffffff" strokeWidth="10" />
                  <line x1="0" y1="200" x2="400" y2="200" stroke="#ffffff" strokeWidth="10" />
                  <line x1="0" y1="310" x2="400" y2="310" stroke="#ffffff" strokeWidth="10" />

                  {/* Safe Pedestrian Route Line to Closest Point */}
                  {showRouteOnMap && (
                    <g>
                      <path 
                        d="M 60 250 L 105 250 L 105 145 L 175 145" 
                        stroke="#059669" 
                        strokeWidth="5" 
                        strokeLinecap="round" 
                        strokeLinejoin="round" 
                        fill="none" 
                      />
                      <path 
                        d="M 60 250 L 105 250 L 105 145 L 175 145" 
                        stroke="#ffffff" 
                        strokeWidth="2" 
                        strokeLinecap="round" 
                        strokeDasharray="4,4" 
                        fill="none" 
                      />
                    </g>
                  )}

                  {/* User GPS Location Marker with Pulse Radar */}
                  <g transform="translate(60, 250)">
                    <circle cx="0" cy="0" r="14" fill="#ef4444" opacity="0.2" className="animate-ping" />
                    <circle cx="0" cy="0" r="9" fill="#0f172a" stroke="#ffffff" strokeWidth="2.5" />
                    <circle cx="0" cy="0" r="3.5" fill="#38bdf8" />
                    <rect x="-24" y="12" width="48" height="15" rx="4" fill="#0f172a" opacity="0.9" />
                    <text x="0" y="23" fontSize="8" fill="#ffffff" fontWeight="700" textAnchor="middle">TÚ AQUÍ</text>
                  </g>

                  {/* Interactive Water Distribution Points on Map */}
                  {/* Point 1: Parque Mariscal Nieto (Closest - Cisterna) */}
                  <g 
                    id="marker-MOQ-PE-003"
                    className="cursor-pointer transition-transform hover:scale-110"
                    transform="translate(175, 145)"
                    onClick={() => {
                      setActiveMapPinId('MOQ-PE-003');
                      const pt = points.find(p => p.id === 'MOQ-PE-003');
                      if (pt) onSelectPoint(pt);
                    }}
                  >
                    <circle cx="0" cy="0" r="16" fill="#10b981" opacity="0.25" className="animate-pulse" />
                    <circle cx="0" cy="0" r="12" fill="#10b981" stroke="#ffffff" strokeWidth="2.5" />
                    <circle cx="0" cy="0" r="4.5" fill="#ffffff" />
                    <rect x="-42" y="-28" width="84" height="16" rx="4" fill="#064e3b" stroke="#34d399" strokeWidth="1" />
                    <text x="0" y="-17" fontSize="8" fill="#ffffff" fontWeight="700" textAnchor="middle">Mariscal Nieto (180m)</text>
                  </g>

                  {/* Point 2: Parque La Alameda (Pileta) */}
                  <g 
                    id="marker-MOQ-PE-004"
                    className="cursor-pointer transition-transform hover:scale-110"
                    transform="translate(145, 175)"
                    onClick={() => {
                      setActiveMapPinId('MOQ-PE-004');
                      const pt = points.find(p => p.id === 'MOQ-PE-004');
                      if (pt) onSelectPoint(pt);
                    }}
                  >
                    <circle cx="0" cy="0" r="11" fill="#0284c7" stroke="#ffffff" strokeWidth="2.5" />
                    <circle cx="0" cy="0" r="4" fill="#ffffff" />
                    <rect x="-36" y="-24" width="72" height="15" rx="4" fill="#0c4a6e" stroke="#38bdf8" strokeWidth="1" />
                    <text x="0" y="-14" fontSize="7.5" fill="#ffffff" fontWeight="700" textAnchor="middle">La Alameda (290m)</text>
                  </g>

                  {/* Point 3: PTAP Surtidor Chen Chen */}
                  <g 
                    id="marker-MOQ-PE-008"
                    className="cursor-pointer transition-transform hover:scale-110"
                    transform="translate(310, 65)"
                    onClick={() => {
                      setActiveMapPinId('MOQ-PE-008');
                      const pt = points.find(p => p.id === 'MOQ-PE-008');
                      if (pt) onSelectPoint(pt);
                    }}
                  >
                    <circle cx="0" cy="0" r="13" fill="#10b981" stroke="#ffffff" strokeWidth="2.5" />
                    <circle cx="0" cy="0" r="5" fill="#ffffff" />
                    <rect x="-45" y="-25" width="90" height="15" rx="4" fill="#064e3b" stroke="#34d399" strokeWidth="1" />
                    <text x="0" y="-15" fontSize="7.5" fill="#ffffff" fontWeight="700" textAnchor="middle">Surtidor Chen Chen (24h)</text>
                  </g>

                  {/* Point 4: Óvalo Simón Bolívar (Warn/Delay) */}
                  <g 
                    id="marker-MOQ-PE-001"
                    className="cursor-pointer transition-transform hover:scale-110"
                    transform="translate(70, 310)"
                    onClick={() => {
                      setActiveMapPinId('MOQ-PE-001');
                      const pt = points.find(p => p.id === 'MOQ-PE-001');
                      if (pt) onSelectPoint(pt);
                    }}
                  >
                    <circle cx="0" cy="0" r="10" fill="#ef4444" stroke="#ffffff" strokeWidth="2" />
                    <circle cx="0" cy="0" r="3.5" fill="#ffffff" />
                    <rect x="-35" y="-23" width="70" height="14" rx="4" fill="#7f1d1d" stroke="#f87171" strokeWidth="1" />
                    <text x="0" y="-13" fontSize="7" fill="#ffffff" fontWeight="700" textAnchor="middle">Óvalo Bolívar (Sin agua)</text>
                  </g>

                  {/* Point 5: Plaza San Antonio */}
                  <g 
                    id="marker-MOQ-PE-006"
                    className="cursor-pointer transition-transform hover:scale-110"
                    transform="translate(320, 330)"
                    onClick={() => {
                      setActiveMapPinId('MOQ-PE-006');
                      const pt = points.find(p => p.id === 'MOQ-PE-006');
                      if (pt) onSelectPoint(pt);
                    }}
                  >
                    <circle cx="0" cy="0" r="10" fill="#10b981" stroke="#ffffff" strokeWidth="2" />
                    <circle cx="0" cy="0" r="3.5" fill="#ffffff" />
                    <rect x="-35" y="-23" width="70" height="14" rx="4" fill="#064e3b" stroke="#34d399" strokeWidth="1" />
                    <text x="0" y="-13" fontSize="7" fill="#ffffff" fontWeight="700" textAnchor="middle">San Antonio (1.4 km)</text>
                  </g>
                </svg>

                {/* Floating Bottom Card: Quick Point Focus */}
                {nearestPoint && (
                  <div className="absolute bottom-3 left-3 right-3 bg-white/95 backdrop-blur-md rounded-2xl p-3 border border-slate-300 shadow-xl z-20">
                    <div className="flex items-center justify-between">
                      <span className="text-[11px] font-black text-slate-900 flex items-center gap-1.5 truncate">
                        <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
                        {nearestPoint.n}
                      </span>
                      <span className="text-[10px] font-mono font-bold bg-emerald-100 text-emerald-900 px-2 py-0.5 rounded">
                        {formatDistance(nearestPoint.distMeters ?? 0)} • {formatWalkingTime(nearestPoint.distMeters ?? 0)}
                      </span>
                    </div>
                    <p className="text-[10px] text-slate-600 mt-1 truncate">
                      {nearestPoint.ref} • {nearestPoint.tipo} ({nearestPoint.horario})
                    </p>
                    <div className="mt-2 pt-2 border-t border-slate-100 flex items-center justify-between">
                      <button
                        id="btn-quick-detail"
                        onClick={() => onSelectPoint(nearestPoint)}
                        className="text-[10px] font-bold text-red-600 hover:text-red-700 flex items-center gap-1 cursor-pointer"
                      >
                        Abrir ficha técnica completa <ChevronRight className="w-3 h-3" />
                      </button>
                      <span className="text-[9px] text-slate-600 font-semibold">
                        Cruce seguro CENEPRED
                      </span>
                    </div>
                  </div>
                )}
              </div>

              {/* Map Legend */}
              <div className="bg-white p-2.5 border-t border-slate-200 flex items-center justify-between text-[10px] text-slate-600 shrink-0">
                <span className="flex items-center gap-1"><i className="w-2.5 h-2.5 rounded-full bg-emerald-600 inline-block"></i> Con agua</span>
                <span className="flex items-center gap-1"><i className="w-2.5 h-2.5 rounded-full bg-blue-600 inline-block"></i> Pileta fija</span>
                <span className="flex items-center gap-1"><i className="w-2.5 h-2.5 rounded-full bg-red-600 inline-block"></i> Sin agua / Falla</span>
                <span className="flex items-center gap-1"><i className="w-2.5 h-2.5 rounded-full bg-slate-900 inline-block"></i> Tu ubicación</span>
              </div>
            </div>
          )}

          {/* TAB 3: MI SECTOR (Rationing & Continuity Schedule) */}
          {activeTab === 'sector' && (
            <div className="p-3.5 space-y-3">
              
              {/* Main Sector Card */}
              <div className="bg-white rounded-2xl p-4 border border-slate-200 shadow-xs text-center relative overflow-hidden">
                <div className="absolute top-0 right-0 w-24 h-24 bg-red-50 rounded-full blur-xl pointer-events-none"></div>
                
                <span className="text-[10px] font-extrabold uppercase tracking-wider text-red-600 bg-red-50 px-2.5 py-0.5 rounded-full border border-red-200">
                  Sector Asignado por EPS
                </span>
                
                <h2 className="text-xl font-black text-slate-900 mt-2">
                  {currentSectorData.n}
                </h2>

                <div className="my-3 flex justify-center items-baseline gap-1.5">
                  <span className="text-4xl font-black text-slate-900 tracking-tight">
                    {isEmergency ? `${currentSectorData.rac}h` : `${currentSectorData.con}h`}
                  </span>
                  <span className="text-xs font-semibold text-slate-500">
                    de agua al día ({isEmergency ? 'Racionamiento por sismo' : 'Continuidad normal'})
                  </span>
                </div>

                <div className="p-2.5 rounded-xl bg-slate-50 border border-slate-200 text-xs flex items-center justify-between text-slate-700">
                  <span>Horario de turno:</span>
                  <strong className="text-slate-900 font-bold">{currentSectorData.hor}</strong>
                </div>

                <p className="text-[10px] text-slate-600 mt-2">
                  Abastecido directamente por el reservorio <strong>{currentSectorData.res}</strong>
                </p>
              </div>

              {/* Quick Sector Switcher (Button Testing) */}
              <div>
                <p className="text-[10px] font-bold text-slate-600 uppercase tracking-wider mb-1.5">
                  Simular consulta de otros sectores de Moquegua:
                </p>
                <div className="flex flex-wrap gap-1.5">
                  {sectors.map(sec => (
                    <button
                      key={sec.n}
                      id={`btn-sec-${sec.n.replace(/\s+/g, '-').toLowerCase()}`}
                      onClick={() => onUserLocationChange({
                        ...userLocation,
                        sector: sec.n,
                        nombre: `${sec.n} (Simulado)`
                      })}
                      className={`text-[11px] font-bold px-2.5 py-1 rounded-xl transition-all cursor-pointer ${
                        sec.n === userLocation.sector
                          ? 'bg-red-600 text-white shadow-xs'
                          : 'bg-white text-slate-700 border border-slate-200 hover:bg-slate-50'
                      }`}
                    >
                      {sec.n}
                    </button>
                  ))}
                </div>
              </div>

              {/* Full Sector Comparison Table */}
              <div className="bg-white rounded-2xl border border-slate-200 overflow-hidden shadow-xs">
                <div className="p-3 bg-slate-900 text-white flex justify-between items-center">
                  <span className="text-xs font-bold">Plan de Contingencia y Racionamiento</span>
                  <span className="text-[9px] font-mono bg-red-600 px-2 py-0.5 rounded text-white">OFICIAL EPS</span>
                </div>

                <div className="overflow-x-auto">
                  <table className="w-full text-left text-xs border-collapse">
                    <thead>
                      <tr className="bg-slate-50 border-b border-slate-200 text-[10px] font-extrabold text-slate-600 uppercase">
                        <th className="p-2.5">Sector</th>
                        <th className="p-2.5 text-center">Normal</th>
                        <th className="p-2.5 text-center text-red-600">Sismo</th>
                        <th className="p-2.5">Horario</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                      {sectors.map(sec => {
                        const isSelected = sec.n === userLocation.sector;
                        return (
                          <tr 
                            key={sec.n} 
                            className={isSelected ? 'bg-red-50/70 font-bold text-red-950' : 'hover:bg-slate-50 text-slate-700'}
                          >
                            <td className="p-2.5 text-xs font-semibold">
                              {isSelected ? `📍 ${sec.n}` : sec.n}
                            </td>
                            <td className="p-2.5 text-center text-slate-600">{sec.con}h</td>
                            <td className="p-2.5 text-center font-bold text-red-700">{sec.rac}h</td>
                            <td className="p-2.5 text-[11px]">{sec.hor}</td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              </div>

              {/* Strategic Context Note from Tania GRD / Yaku Nan */}
              <div className="p-3.5 bg-amber-50 border border-amber-200 rounded-2xl text-xs text-amber-900 space-y-1.5 leading-relaxed">
                <div className="flex items-center gap-1.5 font-bold text-amber-950">
                  <Info className="w-4 h-4 text-amber-600 shrink-0" />
                  El Valor Preventivo de Esta Tabla
                </div>
                <p className="text-[11px]">
                  En el Plan de Operaciones de Emergencia (POE) aprobado de muchas EPS, esta tabla existe pero <strong>las columnas de horarios y racionamiento suelen estar en blanco</strong>. AguaCION exige que cada sector tenga asignado su horario verificable, evitando colapsos y angustia ciudadana el día del desastre.
                </p>
              </div>

            </div>
          )}

          {/* TAB 4: AGUA SEGURA (Domestic Reserve & Chlorine Calculators) */}
          {activeTab === 'agua' && (
            <div className="p-3.5 space-y-4">
              
              {/* Section 1: Water Needs Calculator */}
              <div className="bg-white rounded-2xl p-4 border border-slate-200 shadow-xs space-y-3">
                <div className="flex items-center justify-between border-b border-slate-100 pb-2">
                  <span className="text-xs font-bold text-slate-900 flex items-center gap-1.5">
                    <Droplet className="w-4 h-4 text-blue-600" />
                    Calculadora de Reserva Familiar
                  </span>
                  <span className="text-[10px] bg-blue-50 text-blue-800 font-bold px-2 py-0.5 rounded">
                    Estándar Esfera
                  </span>
                </div>

                {/* Persons Counter */}
                <div className="flex items-center justify-between bg-slate-50 p-2.5 rounded-xl border border-slate-200">
                  <div>
                    <span className="text-xs font-bold text-slate-800 block">Personas en tu hogar</span>
                    <span className="text-[10px] text-slate-600">Integrantes de la familia</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <button
                      id="btn-sub-person"
                      onClick={() => setCalcPersons(Math.max(1, calcPersons - 1))}
                      className="w-8 h-8 rounded-lg bg-white border border-slate-300 flex items-center justify-center font-bold text-slate-700 hover:bg-slate-100 cursor-pointer"
                    >
                      <Minus className="w-3.5 h-3.5" />
                    </button>
                    <span className="text-sm font-black text-slate-900 w-6 text-center font-mono">
                      {calcPersons}
                    </span>
                    <button
                      id="btn-add-person"
                      onClick={() => setCalcPersons(calcPersons + 1)}
                      className="w-8 h-8 rounded-lg bg-white border border-slate-300 flex items-center justify-center font-bold text-slate-700 hover:bg-slate-100 cursor-pointer"
                    >
                      <Plus className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>

                {/* Days Counter */}
                <div className="flex items-center justify-between bg-slate-50 p-2.5 rounded-xl border border-slate-200">
                  <div>
                    <span className="text-xs font-bold text-slate-800 block">Días a cubrir</span>
                    <span className="text-[10px] text-slate-600">Tiempo de autonomía</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <button
                      id="btn-sub-days"
                      onClick={() => setCalcDays(Math.max(1, calcDays - 1))}
                      className="w-8 h-8 rounded-lg bg-white border border-slate-300 flex items-center justify-center font-bold text-slate-700 hover:bg-slate-100 cursor-pointer"
                    >
                      <Minus className="w-3.5 h-3.5" />
                    </button>
                    <span className="text-sm font-black text-slate-900 w-6 text-center font-mono">
                      {calcDays}
                    </span>
                    <button
                      id="btn-add-days"
                      onClick={() => setCalcDays(calcDays + 1)}
                      className="w-8 h-8 rounded-lg bg-white border border-slate-300 flex items-center justify-center font-bold text-slate-700 hover:bg-slate-100 cursor-pointer"
                    >
                      <Plus className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>

                {/* Standard Toggle (15L vs 7.5L) */}
                <div className="grid grid-cols-2 gap-2 text-xs">
                  <button
                    id="btn-quota-15"
                    onClick={() => setCalcMode('esfera')}
                    className={`p-2 rounded-xl border font-bold text-left transition-all cursor-pointer ${
                      calcMode === 'esfera'
                        ? 'bg-blue-600 text-white border-blue-600 shadow-xs'
                        : 'bg-white text-slate-700 border-slate-200 hover:bg-slate-50'
                    }`}
                  >
                    <span className="block text-[11px]">15 L / día</span>
                    <span className="text-[9px] opacity-80">Recomendado OMS</span>
                  </button>

                  <button
                    id="btn-quota-75"
                    onClick={() => setCalcMode('supervivencia')}
                    className={`p-2 rounded-xl border font-bold text-left transition-all cursor-pointer ${
                      calcMode === 'supervivencia'
                        ? 'bg-amber-600 text-white border-amber-600 shadow-xs'
                        : 'bg-white text-slate-700 border-slate-200 hover:bg-slate-50'
                    }`}
                  >
                    <span className="block text-[11px]">7.5 L / día</span>
                    <span className="text-[9px] opacity-80">Mínimo Vital</span>
                  </button>
                </div>

                {/* Result Card */}
                <div className="bg-slate-900 text-white p-3.5 rounded-2xl">
                  <div className="flex items-baseline justify-between">
                    <div>
                      <span className="text-3xl font-black tracking-tight text-white font-mono">
                        {totalWaterNeeded.toLocaleString('es-PE')} L
                      </span>
                      <span className="text-xs text-slate-400 block mt-0.5">
                        Volumen total requerido
                      </span>
                    </div>
                    <div className="text-right">
                      <span className="text-xl font-black text-amber-300 font-mono">
                        {jugsOf20L} {jugsOf20L > 1 ? 'bidones' : 'bidón'}
                      </span>
                      <span className="text-[10px] text-slate-400 block">
                        De 20 litros cada uno
                      </span>
                    </div>
                  </div>
                </div>
              </div>

              {/* Section 2: Chlorine Disinfection Calculator */}
              <div className="bg-white rounded-2xl p-4 border border-slate-200 shadow-xs space-y-3">
                <div className="flex items-center justify-between border-b border-slate-100 pb-2">
                  <span className="text-xs font-bold text-slate-900 flex items-center gap-1.5">
                    <ShieldCheck className="w-4 h-4 text-emerald-600" />
                    Desinfección Segura con Lejía
                  </span>
                  <span className="text-[10px] bg-emerald-50 text-emerald-800 font-bold px-2 py-0.5 rounded">
                    Dosis 2 mg/L
                  </span>
                </div>

                {/* Volume of Container */}
                <div>
                  <label htmlFor="input-vol-container" className="text-xs font-bold text-slate-800 block mb-1">
                    Volumen del recipiente: <strong className="text-blue-700">{bleachVolume} Litros</strong>
                  </label>
                  <input
                    id="input-vol-container"
                    type="range"
                    min="1"
                    max="100"
                    step="1"
                    value={bleachVolume}
                    onChange={(e) => setBleachVolume(+e.target.value)}
                    className="w-full accent-blue-600 cursor-pointer"
                  />
                  <div className="flex justify-between text-[9px] text-slate-600 font-mono mt-0.5">
                    <span>1 L</span>
                    <span>10 L</span>
                    <span>20 L (Bidón estándar)</span>
                    <span>50 L</span>
                    <span>100 L</span>
                  </div>
                </div>

                {/* Concentration Selector */}
                <div>
                  <label htmlFor="select-bleach-conc" className="text-xs font-bold text-slate-800 block mb-1">
                    Concentración de la lejía comercial:
                  </label>
                  <select
                    id="select-bleach-conc"
                    value={bleachConcentration}
                    onChange={(e) => setBleachConcentration(+e.target.value)}
                    className="w-full p-2.5 bg-slate-50 border border-slate-300 rounded-xl text-xs font-semibold text-slate-800 focus:outline-none focus:border-emerald-500"
                  >
                    <option value={5}>Lejía doméstica común al 5% (Recomendada)</option>
                    <option value={4}>Lejía doméstica al 4%</option>
                    <option value={8}>Hipoclorito de sodio al 8%</option>
                  </select>
                </div>

                {/* Disinfection Result Card */}
                <div className="bg-emerald-950 text-emerald-100 p-3.5 rounded-2xl border border-emerald-800">
                  <div className="flex items-center justify-between">
                    <div>
                      <span className="text-2xl font-black text-white font-mono">
                        {bleachMl.toFixed(1).replace('.', ',')} mL
                      </span>
                      <span className="text-xs text-emerald-300 font-bold block mt-0.5">
                        Aproximadamente <span className="text-amber-300 text-sm">{bleachDrops} gotas</span>
                      </span>
                    </div>

                    <button
                      id="btn-copy-dosage"
                      onClick={handleCopyDosage}
                      className="px-3 py-1.5 bg-emerald-700 hover:bg-emerald-600 text-white rounded-xl text-[11px] font-bold cursor-pointer transition-colors"
                    >
                      {copiedDosage ? '✓ Copiado' : 'Copiar'}
                    </button>
                  </div>
                  
                  <div className="mt-2 pt-2 border-t border-emerald-800/80 text-[10px] text-emerald-200 leading-relaxed">
                    1. Si el agua está turbia, fíltrela con paño limpio.<br/>
                    2. Agregue la dosis, mezcle vigorosamente y tape el envase.<br/>
                    3. <strong>Espere 30 minutos de reposo antes de beber.</strong>
                  </div>
                </div>
              </div>

            </div>
          )}

          {/* TAB 5: REPORTAR (Offline-First Citizen Reporting) */}
          {activeTab === 'reportar' && (
            <div className="p-3.5 space-y-3.5">
              
              {/* Queued Reports Alert if offline */}
              {queuedReports.length > 0 && (
                <div className="bg-amber-50 border border-amber-300 rounded-2xl p-3 text-amber-900 text-xs flex items-start justify-between gap-2 shadow-xs">
                  <div>
                    <span className="font-extrabold text-amber-950 block">
                      ⏳ {queuedReports.length} {queuedReports.length > 1 ? 'reportes guardados' : 'reporte guardado'} en memoria
                    </span>
                    <p className="text-[11px] text-amber-800 mt-0.5">
                      Se sincronizarán automáticamente con la central de SUNASS y EPS apenas vuelva la señal.
                    </p>
                  </div>
                  {isOnline && (
                    <button
                      id="btn-force-sync"
                      onClick={onSyncReports}
                      className="px-2.5 py-1 bg-amber-600 hover:bg-amber-700 text-white font-bold rounded-lg text-[10px] shrink-0 cursor-pointer"
                    >
                      Sincronizar
                    </button>
                  )}
                </div>
              )}

              {/* Form */}
              <div className="bg-white rounded-2xl p-4 border border-slate-200 shadow-xs">
                <h2 className="text-sm font-black text-slate-900 mb-1 flex items-center gap-1.5">
                  <Send className="w-4 h-4 text-red-600" />
                  Alerta Ciudadana en Tiempo Real
                </h2>
                <p className="text-[11px] text-slate-600 mb-3">
                  Reporta fallas, cisternas retrasadas o fugas para que el COE EPS redistribuya camiones.
                </p>

                <form onSubmit={handleReportSubmit} className="space-y-3">
                  <div>
                    <label htmlFor="select-report-point" className="text-xs font-bold text-slate-800 block mb-1">
                      Punto o zona afectada:
                    </label>
                    <select
                      id="select-report-point"
                      value={reportPointId}
                      onChange={(e) => setReportPointId(e.target.value)}
                      className="w-full p-2.5 bg-slate-50 border border-slate-300 rounded-xl text-xs font-semibold text-slate-900 focus:outline-none focus:border-red-500"
                    >
                      {points.map(p => (
                        <option key={p.id} value={p.id}>
                          {p.n} ({p.sector})
                        </option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label htmlFor="select-report-issue" className="text-xs font-bold text-slate-800 block mb-1">
                      Incidencia detectada:
                    </label>
                    <select
                      id="select-report-issue"
                      value={reportType}
                      onChange={(e) => setReportType(e.target.value)}
                      className="w-full p-2.5 bg-slate-50 border border-slate-300 rounded-xl text-xs font-semibold text-slate-900 focus:outline-none focus:border-red-500"
                    >
                      <option>El punto no tiene agua disponible</option>
                      <option>La cisterna no llegó en el horario previsto</option>
                      <option>El agua sale turbia o con olor anómalo</option>
                      <option>Hay una fuga visible o rotura en la vía</option>
                      <option>Acceso peatonal o vehicular bloqueado por escombros</option>
                    </select>
                  </div>

                  <div>
                    <label htmlFor="input-report-comment" className="text-xs font-bold text-slate-800 block mb-1">
                      Detalle adicional (opcional):
                    </label>
                    <textarea
                      id="input-report-comment"
                      rows={2}
                      placeholder="Ej: Colas de 50 personas, cisterna no aparece desde las 08:00..."
                      value={reportComment}
                      onChange={(e) => setReportComment(e.target.value)}
                      className="w-full p-2.5 bg-slate-50 border border-slate-300 rounded-xl text-xs text-slate-900 placeholder:text-slate-600 focus:outline-none focus:border-red-500 resize-none"
                    ></textarea>
                  </div>

                  <button
                    id="btn-submit-report"
                    type="submit"
                    className="w-full py-3 px-4 bg-red-600 hover:bg-red-700 text-white font-bold text-xs rounded-xl shadow-md shadow-red-600/20 flex items-center justify-center gap-1.5 transition-all cursor-pointer"
                  >
                    <Send className="w-3.5 h-3.5" />
                    {isOnline ? 'Transmitir reporte a SUNASS y EPS' : 'Guardar reporte localmente (Sin internet)'}
                  </button>
                </form>

                <div className="mt-3 pt-3 border-t border-slate-100 flex items-start gap-2 text-[10px] text-slate-600">
                  <ShieldCheck className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                  <span>
                    <strong>Garantía de funcionamiento offline:</strong> Cada reporte se georreferencia con tu GPS nativo y queda almacenado de forma segura en tu teléfono hasta tener señal.
                  </span>
                </div>
              </div>

              {/* Recent local history */}
              {queuedReports.length > 0 && (
                <div className="bg-slate-50 rounded-2xl p-3 border border-slate-200 space-y-2">
                  <span className="text-[10px] font-bold text-slate-600 uppercase tracking-wider block">
                    Reportes en cola de sincronización ({queuedReports.length}):
                  </span>
                  {queuedReports.map(rep => (
                    <div key={rep.id} className="bg-white p-2.5 rounded-xl border border-slate-200 text-xs">
                      <div className="flex justify-between items-center text-[10px]">
                        <strong className="text-slate-900">{rep.puntoNombre}</strong>
                        <span className="text-slate-600 font-mono">{rep.timestamp}</span>
                      </div>
                      <p className="text-[11px] text-red-700 font-medium mt-0.5">{rep.tipoProblema}</p>
                    </div>
                  ))}
                </div>
              )}

            </div>
          )}

        </div>

        {/* BOTTOM SMARTPHONE NAVIGATION BAR */}
        <nav 
          id="phone-nav-bar"
          className="bg-white border-t border-slate-200 px-2 py-1.5 flex items-center justify-around shrink-0 shadow-lg"
        >
          <button
            id="nav-tab-puntos"
            onClick={() => onTabChange('puntos')}
            className={`flex-1 flex flex-col items-center py-1 transition-colors cursor-pointer ${
              activeTab === 'puntos' ? 'text-red-600 font-extrabold' : 'text-slate-600 hover:text-slate-800'
            }`}
          >
            <Droplet className="w-4 h-4" />
            <span className="text-[10px] mt-0.5">Puntos</span>
            {activeTab === 'puntos' && <span className="w-1 h-1 rounded-full bg-red-600 mt-0.5"></span>}
          </button>

          <button
            id="nav-tab-mapa"
            onClick={() => onTabChange('mapa')}
            className={`flex-1 flex flex-col items-center py-1 transition-colors cursor-pointer ${
              activeTab === 'mapa' ? 'text-red-600 font-extrabold' : 'text-slate-600 hover:text-slate-800'
            }`}
          >
            <MapIcon className="w-4 h-4" />
            <span className="text-[10px] mt-0.5">Mapa</span>
            {activeTab === 'mapa' && <span className="w-1 h-1 rounded-full bg-red-600 mt-0.5"></span>}
          </button>

          <button
            id="nav-tab-sector"
            onClick={() => onTabChange('sector')}
            className={`flex-1 flex flex-col items-center py-1 transition-colors cursor-pointer ${
              activeTab === 'sector' ? 'text-red-600 font-extrabold' : 'text-slate-600 hover:text-slate-800'
            }`}
          >
            <Clock className="w-4 h-4" />
            <span className="text-[10px] mt-0.5">Mi Sector</span>
            {activeTab === 'sector' && <span className="w-1 h-1 rounded-full bg-red-600 mt-0.5"></span>}
          </button>

          <button
            id="nav-tab-agua"
            onClick={() => onTabChange('agua')}
            className={`flex-1 flex flex-col items-center py-1 transition-colors cursor-pointer ${
              activeTab === 'agua' ? 'text-red-600 font-extrabold' : 'text-slate-600 hover:text-slate-800'
            }`}
          >
            <ShieldCheck className="w-4 h-4" />
            <span className="text-[10px] mt-0.5">Agua Segura</span>
            {activeTab === 'agua' && <span className="w-1 h-1 rounded-full bg-red-600 mt-0.5"></span>}
          </button>

          <button
            id="nav-tab-reportar"
            onClick={() => onTabChange('reportar')}
            className={`flex-1 flex flex-col items-center py-1 transition-colors cursor-pointer relative ${
              activeTab === 'reportar' ? 'text-red-600 font-extrabold' : 'text-slate-600 hover:text-slate-800'
            }`}
          >
            <Send className="w-4 h-4" />
            <span className="text-[10px] mt-0.5">Reportar</span>
            {queuedReports.length > 0 && (
              <span className="absolute top-0 right-3 w-3.5 h-3.5 bg-amber-500 text-slate-950 text-[9px] font-black rounded-full flex items-center justify-center">
                {queuedReports.length}
              </span>
            )}
            {activeTab === 'reportar' && <span className="w-1 h-1 rounded-full bg-red-600 mt-0.5"></span>}
          </button>
        </nav>

        {/* Home Screen Indicator */}
        <div className="bg-white pb-1 pt-0.5 text-center">
          <div className="w-24 h-1 bg-slate-300 rounded-full mx-auto"></div>
        </div>

      </div>
    </div>
  );
};
