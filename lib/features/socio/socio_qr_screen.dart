import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'socio_model.dart';
import '../auth/login_screen.dart';

class SocioQrScreen extends StatefulWidget {
  final SocioModel socio;
  const SocioQrScreen({super.key, required this.socio});

  @override
  State<SocioQrScreen> createState() => _SocioQrScreenState();
}

class _SocioQrScreenState extends State<SocioQrScreen> {
  late SocioModel _socioActual;
  bool _cargando = false;
  Timer? _timer;
  final String ip = "192.168.1.127";

  @override
  void initState() {
    super.initState();
    _socioActual = widget.socio;
    // Si el socio no está activo, escuchamos cambios automáticamente
    if (_socioActual.estado.toLowerCase() != 'activo') {
      _iniciarVerificacionAutomatica();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _iniciarVerificacionAutomatica() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final response = await http.get(
          Uri.parse("http://$ip:8080/api/socios/perfil-por-email?email=${_socioActual.email}")
        );
        if (response.statusCode == 200) {
          final nuevoSocio = SocioModel.fromJson(jsonDecode(response.body));
          if (nuevoSocio.estado.toLowerCase() == 'activo') {
            setState(() => _socioActual = nuevoSocio);
            _timer?.cancel();
          }
        }
      } catch (e) {
        debugPrint("Error verificando pago: $e");
      }
    });
  }

  Future<void> _logout() async {
    try {
      await GoogleSignIn.standard().signOut();
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Error al cerrar sesión: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool estaActivo = _socioActual.estado.toLowerCase() == 'activo';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("MI PASE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.orange),
            onPressed: _logout,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Nombre del socio en mayúsculas y negrita
                Text(
                  _socioActual.nombre.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 30),
                
                // Tarjeta Central con gradiente en los bordes
                Container(
                  padding: const EdgeInsets.all(4), // Grosor del borde del gradiente
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(35),
                    gradient: const LinearGradient(
                      colors: [Colors.orange, Color(0xFF8B0000)], // Naranja a Rojo Oscuro
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.black, // Fondo de la tarjeta para resaltar el borde
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white, // Contenedor blanco para lectura perfecta
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (estaActivo ? Colors.green : Colors.red).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                      child: QrImageView(
                        data: _socioActual.qrToken ?? "sin-token",
                        version: QrVersions.auto,
                        size: 220.0,
                        gapless: false,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: Text(
                  estaActivo 
                    ? "¡Bienvenido! Disfruta tu entrenamiento."
                    : "⚠️ Presenta este código en recepción para pagar y activar tu acceso.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
                
                const SizedBox(height: 20),
                
                // Indicador de estado estilizado
                Chip(
                  backgroundColor: estaActivo ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                  side: BorderSide(color: estaActivo ? Colors.green : Colors.red),
                  label: Text(
                    estaActivo ? "ACCESO AUTORIZADO" : "PAGO PENDIENTE",
                    style: TextStyle(
                      color: estaActivo ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}