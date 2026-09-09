class UserLocation {
  final String nombre;
  final String sector;
  final double lat;
  final double lon;

  const UserLocation({
    required this.nombre,
    required this.sector,
    required this.lat,
    required this.lon,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'sector': sector,
      'lat': lat,
      'lon': lon,
    };
  }

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      nombre: json['nombre'] as String,
      sector: json['sector'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
    );
  }
}
