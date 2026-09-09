class CitizenReport {
  final String id;
  final String puntoId;
  final String puntoNombre;
  final String tipoProblema;
  final String comentario;
  final String timestamp;
  final bool offline;
  final String sector;

  const CitizenReport({
    required this.id,
    required this.puntoId,
    required this.puntoNombre,
    required this.tipoProblema,
    required this.comentario,
    required this.timestamp,
    required this.offline,
    required this.sector,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'puntoId': puntoId,
      'puntoNombre': puntoNombre,
      'tipoProblema': tipoProblema,
      'comentario': comentario,
      'timestamp': timestamp,
      'offline': offline,
      'sector': sector,
    };
  }

  factory CitizenReport.fromJson(Map<String, dynamic> json) {
    return CitizenReport(
      id: json['id'] as String,
      puntoId: json['puntoId'] as String,
      puntoNombre: json['puntoNombre'] as String,
      tipoProblema: json['tipoProblema'] as String,
      comentario: json['comentario'] as String,
      timestamp: json['timestamp'] as String,
      offline: json['offline'] as bool,
      sector: json['sector'] as String,
    );
  }
}
