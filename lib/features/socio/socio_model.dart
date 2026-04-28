class Socio {
  final String? id;
  final String nombre;
  final String telefono;
  final String email;
  final String? fotourl;
  final String? qrtoken;
  final String? bio;
  final String? instagramurl;
  final String? estado;

  Socio({
    this.id,
    required this.nombre,
    required this.telefono,
    required this.email,
    this.fotourl,
    this.qrtoken,
    this.bio,
    this.instagramurl,
    this.estado,
  });

  // factory para crear un objeto socio desde el json que responde spring boot
  factory Socio.fromjson(Map<String, dynamic> json) {
    return Socio(
      id: json['id'],
      nombre: json['nombre'],
      telefono: json['telefono'],
      email: json['email'],
      fotourl: json['fotoUrl'],
      qrtoken: json['qrToken'],
      bio: json['bio'],
      instagramurl: json['instagramUrl'],
      estado: json['estado'],
    );
  }

  // metodo para convertir el socio a json y enviarlo al backend
  Map<String, dynamic> tojson() {
    return {
      'nombre': nombre,
      'telefono': telefono,
      'email': email,
      'fotoUrl': fotourl,
      'bio': bio,
      'instagramUrl': instagramurl,
    };
  }
}