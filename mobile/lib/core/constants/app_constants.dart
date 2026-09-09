class AppConstants {
  static const String appName = 'AguaCION';
  static const String appSubtitle = 'Red Cartográfica de Agua Segura';
  static const String appRegion = 'Moquegua';
  static const String appTagline = '100% OFFLINE';

  // Humanitarian standards
  static const double sphereStandardLitersPerDay = 15.0; // Litros recomendados OMS/Esfera
  static const double survivalMinimumLitersPerDay = 7.5; // Litros mínimo vital
  static const int standardJugCapacityLiters = 20; // Capacidad bidón estándar
  
  // Chlorine disinfection standard
  static const double targetFreeChlorineMgL = 2.0; // 2 mg/L para agua de emergencia
  static const int dropsPerMl = 20; // 1 mL ~ 20 gotas
  static const int waitMinutesAfterChlorination = 30; // Minutos de reposo

  // Speed estimation
  static const double disasterWalkingSpeedKmH = 4.0; // ~67 metros por minuto
}
