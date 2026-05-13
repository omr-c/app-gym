class Socio {
  final String? id;
  final String nombre;
  final String email;
  final String telefono;
  final String? fotoUrl;
  final String? qrToken;
  final String? bio;
  final String? instagramUrl;
  final String estado;
  final int diasRestantes;
  final String? rol;

  Socio({
    this.id,
    required this.nombre,
    required this.email,
    required this.telefono,
    this.fotoUrl,
    this.qrToken,
    this.bio,
    this.instagramUrl,
    this.estado = "pendiente",
    this.diasRestantes = 0,
    this.rol,
  });

  factory Socio.fromJson(Map<String, dynamic> json) {
    // Mapeo seguro para evitar errores por datos nulos o tipos incorrectos
    return Socio(
      id: json['id']?.toString(),
      nombre: json['nombre']?.toString() ?? "Usuario",
      email: json['email']?.toString() ?? "",
      telefono: json['telefono']?.toString() ?? "Sin registro",
      fotoUrl: json['fotoUrl']?.toString(),
      qrToken: json['qrToken']?.toString(),
      bio: json['bio']?.toString(),
      instagramUrl: json['instagramUrl']?.toString(),
      estado: json['estado']?.toString() ?? "pendiente",
      diasRestantes: json['diasRestantes'] != null 
          ? (json['diasRestantes'] is int ? json['diasRestantes'] : (json['diasRestantes'] as double).toInt()) 
          : 0,
      rol: json['rol']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'email': email,
    'telefono': telefono,
    'fotoUrl': fotoUrl,
    'bio': bio,
    'instagramUrl': instagramUrl,
    'rol': rol,
  };
}