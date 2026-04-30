class Socio {
  final String? id;
  final String nombre;
  final String telefono;
  final String email;
  final String? qrToken;
  final String estado; 
  final String rol;

  Socio({
    this.id,
    required this.nombre,
    required this.telefono,
    required this.email,
    this.qrToken,
    // valores por defecto en minisculas[cite: 16]
    this.estado = 'pendiente', 
    this.rol = 'socio',
  });

  factory Socio.fromJson(Map<String, dynamic> json) {
    return Socio(
      id: json['id']?.toString(),
      nombre: json['nombre'] ?? '',
      telefono: json['telefono'] ?? '',
      email: json['email'] ?? '',
      qrToken: json['qrToken']?.toString(),
      // forzamos minisculas para que la comparacion sea exacta[cite: 16]
      estado: (json['estado'] ?? 'pendiente').toString().toLowerCase(), 
      rol: (json['rol'] ?? 'socio').toString().toLowerCase(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'telefono': telefono,
      'email': email,
      'estado': estado.toLowerCase(), 
      'rol': rol.toLowerCase(),
    };
  }
}