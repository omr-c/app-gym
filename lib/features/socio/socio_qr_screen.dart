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
  final Socio socio;
  const SocioQrScreen({super.key, required this.socio});

  @override
  State<SocioQrScreen> createState() => _SocioQrScreenState();
}

class _SocioQrScreenState extends State<SocioQrScreen> {
  late Socio _socioActual;
  bool _cargando = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _socioActual = widget.socio;
    
    // Si el socio no está activo, escuchamos cambios (pago en recepción)
    if (_socioActual.estado.toLowerCase() != 'activo') {
      _iniciarVerificacionAutomatica();
    }
  }

  void _iniciarVerificacionAutomatica() {
    debugPrint("--- iniciando verificacion automatica de pago ---");
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _refrescarEstado(silencioso: true);
      
      if (_socioActual.estado.toLowerCase() == 'activo') {
        _timer?.cancel();
        debugPrint("--- socio activo detectado, deteniendo temporizador ---");
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refrescarEstado({bool silencioso = false}) async {
    if (!silencioso) setState(() => _cargando = true);
    
    // Priorizamos el endpoint de perfil si ya tenemos el token para obtener días restantes
    final String url = _socioActual.qrToken != null 
        ? "http://192.168.1.68:8080/api/socios/perfil/${_socioActual.qrToken}"
        : "http://192.168.1.68:8080/api/auth/verificar/${_socioActual.email}";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final nuevosDatos = Socio.fromJson(json.decode(response.body));
        
        // Actualizamos si cambió el estado o los días restantes[cite: 2, 3]
        if (nuevosDatos.estado.toLowerCase() != _socioActual.estado.toLowerCase() || 
            nuevosDatos.diasRestantes != _socioActual.diasRestantes) {
          setState(() {
            _socioActual = nuevosDatos;
          });
        }
      }
    } catch (e) {
      debugPrint("error al refrescar: $e");
    } finally {
      if (mounted && !silencioso) {
        setState(() => _cargando = false);
      }
    }
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    try {
      _timer?.cancel();
      await GoogleSignIn.standard().signOut();
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(builder: (context) => const LoginScreen()), 
          (route) => false
        );
      }
    } catch (e) {
      debugPrint("error al cerrar sesion: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool estaActivo = _socioActual.estado.toLowerCase() == 'activo';
    // Lógica de alerta: Naranja si queda una semana o menos
    bool alertaVencimiento = _socioActual.diasRestantes <= 7;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Identidad Digital'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => _cerrarSesion(context)
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refrescarEstado(silencioso: false),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            alignment: Alignment.center, 
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _socioActual.nombre, 
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 5),
                Text(
                  _socioActual.email,
                  style: const TextStyle(color: Colors.grey, fontSize: 14)
                ),
                const SizedBox(height: 30),
                
                // Contenedor del QR[cite: 2]
                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: QrImageView(
                      data: _socioActual.qrToken ?? 'sin-token',
                      version: QrVersions.auto,
                      size: 240.0,
                      backgroundColor: Colors.white,
                      eyeStyle: QrEyeStyle(
                        eyeShape: QrEyeShape.square, 
                        color: estaActivo ? Colors.black : Colors.grey
                      ),
                      dataModuleStyle: QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square, 
                        color: estaActivo ? Colors.black : Colors.grey
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Badge de Estado[cite: 2]
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
                  decoration: BoxDecoration(
                    color: estaActivo ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: estaActivo ? Colors.green : Colors.orange,
                      width: 1.5
                    )
                  ),
                  child: Text(
                    _socioActual.estado.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 1.2,
                      color: estaActivo ? Colors.green : Colors.orange
                    )
                  ),
                ),
                
                const SizedBox(height: 20),

                // TARJETA DE DÍAS RESTANTES (Solo si está activo)
                if (estaActivo)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: alertaVencimiento 
                              ? Colors.orange.withOpacity(0.3) 
                              : Colors.black.withOpacity(0.05), 
                          blurRadius: 10,
                          spreadRadius: 2
                        )
                      ]
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded, 
                          color: alertaVencimiento ? Colors.orange : Colors.blueAccent
                        ),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Membresía",
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              "${_socioActual.diasRestantes} días restantes",
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold,
                                color: alertaVencimiento ? Colors.orange : Colors.black87
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),
                
                if (_cargando) 
                  const CircularProgressIndicator()
                else 
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: Text(
                      estaActivo 
                        ? (alertaVencimiento 
                            ? "¡Tu membresía vence pronto! Revisa tu correo." 
                            : "Disfruta tu entrenamiento en Gym Rats")
                        : "Esperando confirmación de pago en recepción...", 
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: alertaVencimiento && estaActivo ? Colors.orange : Colors.grey, 
                        fontSize: 13,
                        fontWeight: alertaVencimiento ? FontWeight.w500 : FontWeight.normal
                      )
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