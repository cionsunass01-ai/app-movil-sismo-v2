class SectorData {
  final String n; // Sector name
  final int con; // Continuity hours normal
  final int rac; // Rationing hours in emergency
  final String hor; // Service hours schedule
  final String res; // Supplying reservoir
  final int puntosCount; // Water points count

  const SectorData({
    required this.n,
    required this.con,
    required this.rac,
    required this.hor,
    required this.res,
    required this.puntosCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'n': n,
      'con': con,
      'rac': rac,
      'hor': hor,
      'res': res,
      'puntosCount': puntosCount,
    };
  }

  factory SectorData.fromJson(Map<String, dynamic> json) {
    return SectorData(
      n: json['n'] as String,
      con: (json['con'] as num).toInt(),
      rac: (json['rac'] as num).toInt(),
      hor: json['hor'] as String,
      res: json['res'] as String,
      puntosCount: (json['puntosCount'] as num).toInt(),
    );
  }
}
