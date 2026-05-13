class SocioModel {
  final String? id;
  final String nombre;
  final String telefono;
  final String email;
  final String? qrToken;
  final String estado; 
  final String rol;
  final String fotoUrl; 
  final int diasRestantes; 

  SocioModel({
    this.id,
    required this.nombre,
    required this.telefono,
    required this.email,
    this.qrToken,
    this.estado = 'activo', 
    this.rol = 'socio',
    this.fotoUrl = '', 
    this.diasRestantes = 0,
  });

  factory SocioModel.fromJson(Map<String, dynamic> json) {
    return SocioModel(
      id: json['id']?.toString(),
      nombre: json['nombre'] ?? '',
      telefono: json['telefono'] ?? '',
      email: json['email'] ?? '',
      qrToken: json['qrToken']?.toString(),
      estado: (json['estado'] ?? 'activo').toString().toLowerCase(), 
      rol: (json['rol'] ?? 'socio').toString().toLowerCase(),
      fotoUrl: json['fotoUrl'] ?? '',
      diasRestantes: json['diasRestantes'] != null ? (json['diasRestantes'] as num).toInt() : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'telefono': telefono,
      'email': email,
      'qrToken': qrToken,
      'estado': estado,
      'rol': rol,
      'fotoUrl': fotoUrl,
    };
  }
}