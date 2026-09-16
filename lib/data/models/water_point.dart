enum PointType {
  cisterna('Punto de cisterna'),
  pileta('Pileta pública'),
  surtidor('Surtidor fijo'),
  pozo('Pozo de emergencia'),
  noEspecificado('No especificado');

  final String label;
  const PointType(this.label);

  static PointType fromString(String? value) {
    if (value == null || value.isEmpty) return PointType.noEspecificado;
    return PointType.values.firstWhere(
      (e) =>
          e.label.toLowerCase() == value.toLowerCase() ||
          e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PointType.noEspecificado,
    );
  }
}

enum WaterQuality {
  apta('Apta para consumo'),
  requiereTratamiento('Requiere tratamiento previo'),
  sinInformacion('Sin información actual');

  final String label;
  const WaterQuality(this.label);

  static WaterQuality? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    return WaterQuality.values.firstWhere(
      (e) =>
          e.label.toLowerCase() == value.toLowerCase() ||
          e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => WaterQuality.sinInformacion,
    );
  }
}

enum EmergencyStatus {
  ok,
  warn,
  bad,
  unknown;

  static EmergencyStatus fromString(String? value) {
    if (value == null || value.isEmpty) return EmergencyStatus.unknown;
    switch (value.toLowerCase()) {
      case 'ok':
        return EmergencyStatus.ok;
      case 'warn':
        return EmergencyStatus.warn;
      case 'bad':
        return EmergencyStatus.bad;
      case 'unknown':
      case 'noconfirmado':
      case 'no_confirmado':
      default:
        return EmergencyStatus.unknown;
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
  final String? componentTypeRaw;
  final String sector;
  final int? pobl; // Assigned population (nullable when unverified)
  final String? cap; // Capacity description (nullable without false units)
  final double? capacityRaw; // Raw numeric capacity if provided
  final String? capacityUnit; // Explicit unit if provided by source
  final String? recarga; // Supply source (nullable when unverified)
  final String? horario; // Schedule (nullable when unverified)
  final WaterQuality? calidad; // Water quality (nullable when unverified)
  final String? acceso; // Road accessibility (nullable when unverified)
  final String? pend; // Slope / terrain (nullable when unverified)
  final String? resp; // Responsible entity (nullable when unverified)
  final String?
  ver; // Field verification date string (nullable when unverified)
  final int?
  verMeses; // Months since field verification (nullable when unverified)
  final String? validFrom; // Dataset source publication or cutoff date
  final EmergencyStatus estE; // Emergency status (ok, warn, bad, unknown)
  final String estETxt; // Emergency status text
  final String estN; // Normal status text
  final int? distMeters; // Calculated distance in meters
  final bool
  isDistanceApproximate; // True when distance is straight-line Haversine

  const WaterPoint({
    required this.id,
    required this.n,
    required this.ref,
    required this.lat,
    required this.lon,
    required this.tipo,
    this.componentTypeRaw,
    required this.sector,
    this.pobl,
    this.cap,
    this.capacityRaw,
    this.capacityUnit,
    this.recarga,
    this.horario,
    this.calidad,
    this.acceso,
    this.pend,
    this.resp,
    this.ver,
    this.verMeses,
    this.validFrom,
    this.estE = EmergencyStatus.unknown,
    this.estETxt = 'Estado no confirmado',
    this.estN = 'Catálogo local',
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
    String? componentTypeRaw,
    String? sector,
    int? pobl,
    String? cap,
    double? capacityRaw,
    String? capacityUnit,
    String? recarga,
    String? horario,
    WaterQuality? calidad,
    String? acceso,
    String? pend,
    String? resp,
    String? ver,
    int? verMeses,
    String? validFrom,
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
      componentTypeRaw: componentTypeRaw ?? this.componentTypeRaw,
      sector: sector ?? this.sector,
      pobl: pobl ?? this.pobl,
      cap: cap ?? this.cap,
      capacityRaw: capacityRaw ?? this.capacityRaw,
      capacityUnit: capacityUnit ?? this.capacityUnit,
      recarga: recarga ?? this.recarga,
      horario: horario ?? this.horario,
      calidad: calidad ?? this.calidad,
      acceso: acceso ?? this.acceso,
      pend: pend ?? this.pend,
      resp: resp ?? this.resp,
      ver: ver ?? this.ver,
      verMeses: verMeses ?? this.verMeses,
      validFrom: validFrom ?? this.validFrom,
      estE: estE ?? this.estE,
      estETxt: estETxt ?? this.estETxt,
      estN: estN ?? this.estN,
      distMeters: distMeters ?? this.distMeters,
      isDistanceApproximate:
          isDistanceApproximate ?? this.isDistanceApproximate,
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
      if (componentTypeRaw != null) 'component_type_raw': componentTypeRaw,
      'sector': sector,
      if (pobl != null) 'pobl': pobl,
      if (cap != null) 'cap': cap,
      if (capacityRaw != null) 'capacity_raw': capacityRaw,
      if (capacityUnit != null) 'capacity_unit': capacityUnit,
      if (recarga != null) 'recarga': recarga,
      if (horario != null) 'horario': horario,
      if (calidad != null) 'calidad': calidad!.label,
      if (acceso != null) 'acceso': acceso,
      if (pend != null) 'pend': pend,
      if (resp != null) 'resp': resp,
      if (ver != null) 'ver': ver,
      if (verMeses != null) 'verMeses': verMeses,
      if (validFrom != null) 'valid_from': validFrom,
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
      ref: json['ref'] as String? ?? '',
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      tipo: PointType.fromString(json['tipo'] as String?),
      componentTypeRaw: json['component_type_raw'] as String?,
      sector: json['sector'] as String? ?? '',
      pobl: json['pobl'] != null ? (json['pobl'] as num).toInt() : null,
      cap: json['cap'] as String?,
      capacityRaw: json['capacity_raw'] != null
          ? (json['capacity_raw'] as num).toDouble()
          : null,
      capacityUnit: json['capacity_unit'] as String?,
      recarga: json['recarga'] as String?,
      horario: json['horario'] as String?,
      calidad: json['calidad'] != null
          ? WaterQuality.fromString(json['calidad'] as String)
          : null,
      acceso: json['acceso'] as String?,
      pend: json['pend'] as String?,
      resp: json['resp'] as String?,
      ver: json['ver'] as String?,
      verMeses: json['verMeses'] != null
          ? (json['verMeses'] as num).toInt()
          : null,
      validFrom: json['valid_from'] as String?,
      estE: EmergencyStatus.fromString(json['estE'] as String?),
      estETxt: json['estETxt'] as String? ?? 'Estado no confirmado',
      estN: json['estN'] as String? ?? 'Catálogo local',
      distMeters: json['distMeters'] != null
          ? (json['distMeters'] as num).toInt()
          : null,
      isDistanceApproximate: json['isDistanceApproximate'] as bool? ?? true,
    );
  }

  /// Constructs a domain WaterPoint directly from a record in `water_points_normalized.json`.
  ///
  /// STRICT DATA HONESTY:
  /// - Absent coordinates throw ArgumentError and are NEVER converted to 0.0, 0.0.
  /// - Unknown component types are marked [PointType.noEspecificado], never forced to cisterna.
  /// - Capacity never has 'm³' appended unless explicitly provided by source.
  /// - Unverified operational data (quality, schedule, recharge, population, access, field verification)
  ///   remains null instead of fabricating optimistic defaults.
  factory WaterPoint.fromNormalizedJson(Map<String, dynamic> json) {
    final latRaw = json['latitude'];
    final lonRaw = json['longitude'];
    if (latRaw == null || lonRaw == null || latRaw is! num || lonRaw is! num) {
      throw ArgumentError(
        'WaterPoint requires valid numeric latitude and longitude. Missing or null coordinates cannot be defaulted to (0.0, 0.0).',
      );
    }

    final rawType =
        (json['component_type_normalized'] ?? json['component_type_raw'] ?? '')
            .toString()
            .trim()
            .toUpperCase();
    final PointType type = switch (rawType) {
      'POZO' => PointType.pozo,
      'CISTERNA' => PointType.cisterna,
      'PILETA' => PointType.pileta,
      'SURTIDOR' => PointType.surtidor,
      _ => PointType.noEspecificado,
    };

    final String district = json['district']?.toString() ?? 'LIMA';
    final String locationDesc = json['location_description']?.toString() ?? '';
    final String officialCode = json['official_code']?.toString() ?? '';
    final String pointId = json['water_point_id']?.toString() ?? '';

    final String displayName = locationDesc.isNotEmpty
        ? locationDesc
        : (officialCode.isNotEmpty ? 'Punto $officialCode' : 'Punto $pointId');

    final String reference = officialCode.isNotEmpty
        ? (json['eomr'] != null && json['eomr'].toString().isNotEmpty
              ? 'Código: $officialCode · ${json['eomr']}'
              : 'Código: $officialCode')
        : (json['eomr']?.toString() ?? '');

    // Capacity & unit: NEVER append m³ if unit is missing or UNKNOWN
    final dynamic capVal = json['capacity'];
    final double? parsedCap = capVal is num
        ? capVal.toDouble()
        : (capVal != null ? double.tryParse(capVal.toString()) : null);
    final String? capUnit = json['capacity_unit']?.toString();
    final bool hasValidUnit =
        capUnit != null &&
        capUnit.isNotEmpty &&
        capUnit.toUpperCase() != 'UNKNOWN' &&
        capUnit.toUpperCase() != 'NULL';

    final String? capStr;
    if (parsedCap != null) {
      final formattedNum = parsedCap % 1 == 0
          ? parsedCap.toInt().toString()
          : parsedCap.toString();
      capStr = hasValidUnit ? '$formattedNum $capUnit' : formattedNum;
    } else if (json['cap'] != null) {
      capStr = json['cap'].toString();
    } else {
      capStr = null;
    }

    final String? calidadRaw =
        json['calidad']?.toString() ?? json['water_quality']?.toString();
    final WaterQuality? calidad = calidadRaw != null
        ? WaterQuality.fromString(calidadRaw)
        : null;

    final String? horario =
        json['horario']?.toString() ?? json['schedule']?.toString();
    final String? recarga =
        json['recarga']?.toString() ?? json['supply_source']?.toString();
    final dynamic poblRaw = json['pobl'] ?? json['population'];
    final int? pobl = poblRaw is num
        ? poblRaw.toInt()
        : (poblRaw != null ? int.tryParse(poblRaw.toString()) : null);
    final String? acceso =
        json['acceso']?.toString() ?? json['road_access']?.toString();
    final String? pend = json['pend']?.toString() ?? json['slope']?.toString();
    final String? resp =
        json['source_authority']?.toString() ?? json['source_name']?.toString();
    final String? fieldVer = json['field_verification_date']?.toString();
    final dynamic verMesesRaw = json['verification_months_ago'];
    final int? verMeses = verMesesRaw is num ? verMesesRaw.toInt() : null;
    final String? validFrom = json['valid_from']?.toString();

    return WaterPoint(
      id: pointId,
      n: displayName,
      ref: reference,
      lat: latRaw.toDouble(),
      lon: lonRaw.toDouble(),
      tipo: type,
      componentTypeRaw: json['component_type_raw']?.toString(),
      sector: district,
      pobl: pobl,
      cap: capStr,
      capacityRaw: parsedCap,
      capacityUnit: hasValidUnit ? capUnit : null,
      recarga: recarga,
      horario: horario,
      calidad: calidad,
      acceso: acceso,
      pend: pend,
      resp: resp,
      ver: fieldVer,
      verMeses: verMeses,
      validFrom: validFrom,
      estE: EmergencyStatus.unknown,
      estETxt: 'Estado no confirmado',
      estN: 'Catálogo local',
      isDistanceApproximate: true,
    );
  }
}
