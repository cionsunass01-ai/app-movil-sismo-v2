export type PointType = 'Punto de cisterna' | 'Pileta pública' | 'Surtidor fijo' | 'Pozo de emergencia';

export type WaterQuality = 'Apta para consumo' | 'Requiere tratamiento previo';

export type EmergencyStatus = 'ok' | 'warn' | 'bad';

export interface WaterPoint {
  id: string;
  n: string;
  ref: string;
  lat: number;
  lon: number;
  tipo: PointType;
  sector: string;
  pobl: number;
  cap: string;
  recarga: string;
  horario: string;
  calidad: WaterQuality;
  acceso: string;
  pend: string;
  resp: string;
  ver: string;
  verMeses: number;
  estE: EmergencyStatus;
  estETxt: string;
  estN: string;
  distMeters?: number;
}

export interface SectorData {
  n: string;
  con: number;
  rac: number;
  hor: string;
  res: string;
  puntosCount: number;
}

export interface CitizenReport {
  id: string;
  puntoId: string;
  puntoNombre: string;
  tipoProblema: string;
  comentario: string;
  timestamp: string;
  offline: boolean;
  sector: string;
}

export type TabView = 'puntos' | 'mapa' | 'sector' | 'agua' | 'reportar';

export interface UserLocation {
  nombre: string;
  sector: string;
  lat: number;
  lon: number;
}
