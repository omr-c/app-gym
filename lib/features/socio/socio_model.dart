class Socio {
  final String? id;
  final String nombre;
  final String telefono;
  final String email;
  final String? qrToken;
  final String estado; 
  final String rol;
  final int diasRestantes; // Nuevo campo calculado

  Socio({
    this.id,
    required this.nombre,
    required this.telefono,
    required this.email,
    this.qrToken,
    this.estado = 'pendiente', 
    this.rol = 'socio',
    this.diasRestantes = 0, // Por defecto 0
  });

  factory Socio.fromJson(Map<String, dynamic> json) {
    return Socio(
      id: json['id']?.toString(),
      nombre: json['nombre'] ?? '',
      telefono: json['telefono'] ?? '',
      email: json['email'] ?? '',
      qrToken: json['qrToken']?.toString(),
      estado: (json['estado'] ?? 'pendiente').toString().toLowerCase(), 
      rol: (json['rol'] ?? 'socio').toString().toLowerCase(),
      // Mapeamos el campo que viene del backend[cite: 3]
      diasRestantes: json['diasRestantes'] != null ? (json['diasRestantes'] as num).toInt() : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'telefono': telefono,
      'email': email,
      'estado': estado.toLowerCase(), 
      'rol': rol.toLowerCase(),
      // El backend calcula los días, pero lo incluimos por si acaso
    };
  }
}