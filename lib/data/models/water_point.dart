enum PointType {
  cisterna('Punto de cisterna'),
  pileta('Pileta pública'),
  surtidor('Surtidor fijo'),
  pozo('Pozo de emergencia');

  final String label;
  const PointType(this.label);

  static PointType fromString(String value) {
    return PointType.values.firstWhere(
      (e) => e.label == value,
      orElse: () => PointType.cisterna,
    );
  }
}

enum WaterQuality {
  apta('Apta para consumo'),
  requiereTratamiento('Requiere tratamiento previo');

  final String label;
  const WaterQuality(this.label);

  static WaterQuality fromString(String value) {
    return WaterQuality.values.firstWhere(
      (e) => e.label == value,
      orElse: () => WaterQuality.apta,
    );
  }
}

enum EmergencyStatus {
  ok,
  warn,
  bad;

  static EmergencyStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'ok':
        return EmergencyStatus.ok;
      case 'warn':
        return EmergencyStatus.warn;
      case 'bad':
        return EmergencyStatus.bad;
      default:
        return EmergencyStatus.ok;
    }
  }
}

class WaterPoint {
  final String id;
  final String n; // Name
  final String ref; // Address reference
  final double lat;
  final double lon;
  final PointType tipo;
  final String sector;
  final int pobl; // Assigned population
  final String cap; // Capacity description
  final String recarga; // Supply source
  final String horario; // Schedule
  final WaterQuality calidad;
  final String acceso; // Road accessibility
  final String pend; // Slope / terrain
  final String resp; // Responsible entity
  final String ver; // Verification date string
  final int verMeses; // Months since verification
  final EmergencyStatus estE; // Emergency status (ok, warn, bad)
  final String estETxt; // Emergency status text
  final String estN; // Normal status text
  final int? distMeters; // Calculated distance in meters
  final bool isDistanceApproximate; // True when distance is straight-line Haversine

  const WaterPoint({
    required this.id,
    required this.n,
    required this.ref,
    required this.lat,
    required this.lon,
    required this.tipo,
    required this.sector,
    required this.pobl,
    required this.cap,
    required this.recarga,
    required this.horario,
    required this.calidad,
    required this.acceso,
    required this.pend,
    required this.resp,
    required this.ver,
    required this.verMeses,
    required this.estE,
    required this.estETxt,
    required this.estN,
    this.distMeters,
    this.isDistanceApproximate = true,
  });

  WaterPoint copyWith({
    String? id,
    String? n,
    String? ref,
    double? lat,
    double? lon,
    PointType? tipo,
    String? sector,
    int? pobl,
    String? cap,
    String? recarga,
    String? horario,
    WaterQuality? calidad,
    String? acceso,
    String? pend,
    String? resp,
    String? ver,
    int? verMeses,
    EmergencyStatus? estE,
    String? estETxt,
    String? estN,
    int? distMeters,
    bool? isDistanceApproximate,
  }) {
    return WaterPoint(
      id: id ?? this.id,
      n: n ?? this.n,
      ref: ref ?? this.ref,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      tipo: tipo ?? this.tipo,
      sector: sector ?? this.sector,
      pobl: pobl ?? this.pobl,
      cap: cap ?? this.cap,
      recarga: recarga ?? this.recarga,
      horario: horario ?? this.horario,
      calidad: calidad ?? this.calidad,
      acceso: acceso ?? this.acceso,
      pend: pend ?? this.pend,
      resp: resp ?? this.resp,
      ver: ver ?? this.ver,
      verMeses: verMeses ?? this.verMeses,
      estE: estE ?? this.estE,
      estETxt: estETxt ?? this.estETxt,
      estN: estN ?? this.estN,
      distMeters: distMeters ?? this.distMeters,
      isDistanceApproximate: isDistanceApproximate ?? this.isDistanceApproximate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'n': n,
      'ref': ref,
      'lat': lat,
      'lon': lon,
      'tipo': tipo.label,
      'sector': sector,
      'pobl': pobl,
      'cap': cap,
      'recarga': recarga,
      'horario': horario,
      'calidad': calidad.label,
      'acceso': acceso,
      'pend': pend,
      'resp': resp,
      'ver': ver,
      'verMeses': verMeses,
      'estE': estE.name,
      'estETxt': estETxt,
      'estN': estN,
      'distMeters': distMeters,
      'isDistanceApproximate': isDistanceApproximate,
    };
  }

  factory WaterPoint.fromJson(Map<String, dynamic> json) {
    return WaterPoint(
      id: json['id'] as String,
      n: json['n'] as String,
      ref: json['ref'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      tipo: PointType.fromString(json['tipo'] as String),
      sector: json['sector'] as String,
      pobl: (json['pobl'] as num).toInt(),
      cap: json['cap'] as String,
      recarga: json['recarga'] as String,
      horario: json['horario'] as String,
      calidad: WaterQuality.fromString(json['calidad'] as String),
      acceso: json['acceso'] as String,
      pend: json['pend'] as String,
      resp: json['resp'] as String,
      ver: json['ver'] as String,
      verMeses: (json['verMeses'] as num).toInt(),
      estE: EmergencyStatus.fromString(json['estE'] as String),
      estETxt: json['estETxt'] as String,
      estN: json['estN'] as String,
      distMeters: json['distMeters'] != null ? (json['distMeters'] as num).toInt() : null,
      isDistanceApproximate: json['isDistanceApproximate'] as bool? ?? true,
    );
  }

  /// Constructs a domain WaterPoint directly from a record in `water_points_normalized.json`
  factory WaterPoint.fromNormalizedJson(Map<String, dynamic> json) {
    final rawType = (json['component_type_normalized'] ?? json['component_type_raw'] ?? '')
        .toString()
        .toUpperCase();
    final PointType type = switch (rawType) {
      'POZO' => PointType.pozo,
      'CISTERNA' => PointType.cisterna,
      'PILETA' => PointType.pileta,
      'SURTIDOR' => PointType.surtidor,
      _ => PointType.cisterna,
    };

    final String district = json['district']?.toString() ?? 'LIMA';
    final String locationDesc = json['location_description']?.toString() ?? '';
    final String officialCode = json['official_code']?.toString() ?? '';
    final String pointId = json['water_point_id']?.toString() ?? '';

    final String displayName = locationDesc.isNotEmpty
        ? locationDesc
        : (officialCode.isNotEmpty ? 'Punto $officialCode' : 'Punto $pointId');

    final String reference = officialCode.isNotEmpty
        ? 'Código: $officialCode · ${json['eomr'] ?? ''}'
        : (json['eomr']?.toString() ?? '');

    final dynamic capVal = json['capacity'];
    final String capStr = capVal != null ? '$capVal m³' : 'Capacidad referencial';

    return WaterPoint(
      id: pointId,
      n: displayName,
      ref: reference,
      lat: (json['latitude'] as num).toDouble(),
      lon: (json['longitude'] as num).toDouble(),
      tipo: type,
      sector: district,
      pobl: 0,
      cap: capStr,
      recarga: json['eomr']?.toString() ?? 'SEDAPAL',
      horario: 'Sujeto a programación de contingencia',
      calidad: WaterQuality.apta,
      acceso: 'Vía peatonal / vehicular',
      pend: 'Normal',
      resp: json['source_authority']?.toString() ?? 'SEDAPAL',
      ver: json['valid_from']?.toString() ?? '2026-08-19',
      verMeses: 1,
      estE: EmergencyStatus.ok,
      estETxt: 'Estado no confirmado',
      estN: 'Catálogo local',
      isDistanceApproximate: true,
    );
  }
}
