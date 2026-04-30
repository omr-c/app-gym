import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // necesario para el timer
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
  Timer? _timer; // controlador del temporizador

  @override
  void initState() {
    super.initState();
    _socioActual = widget.socio;
    
    // si el socio no esta activo al entrar, iniciamos la escucha automatica
    if (_socioActual.estado.toLowerCase() != 'activo') {
      _iniciarVerificacionAutomatica();
    }
  }

  // funcion que pregunta al servidor cada 5 segundos de forma silenciosa
  void _iniciarVerificacionAutomatica() {
    debugPrint("--- iniciando verificacion automatica de pago ---");
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _refrescarEstado(silencioso: true);
      
      // si ya paso a activo, apagamos el reloj para ahorrar bateria
      if (_socioActual.estado.toLowerCase() == 'activo') {
        _timer?.cancel();
        debugPrint("--- socio activo detectado, deteniendo temporizador ---");
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // limpiamos el proceso al salir de la pantalla
    super.dispose();
  }

  // funcion para obtener los datos mas recientes de la bd
  Future<void> _refrescarEstado({bool silencioso = false}) async {
    if (!silencioso) setState(() => _cargando = true);
    
    final String url = "http://192.168.1.127:8080/api/auth/verificar/${_socioActual.email}";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final nuevosDatos = Socio.fromJson(json.decode(response.body));
        
        // solo redibujamos si el estado realmente cambio en la base de datos
        if (nuevosDatos.estado.toLowerCase() != _socioActual.estado.toLowerCase()) {
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

  // funcion corregida para cerrar sesion
  Future<void> _cerrarSesion(BuildContext context) async {
    try {
      _timer?.cancel(); // detenemos el timer antes de salir
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('identidad digital'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => _cerrarSesion(context) // ahora la funcion si existe
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refrescarEstado(silencioso: false),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.8,
            alignment: Alignment.center, 
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _socioActual.nombre, 
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 20),
                
                QrImageView(
                  data: _socioActual.qrToken ?? 'sin-token',
                  version: QrVersions.auto,
                  size: 250.0,
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
                
                const SizedBox(height: 20),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: estaActivo ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'estado: ${_socioActual.estado.toUpperCase()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      color: estaActivo ? Colors.green : Colors.orange
                    )
                  ),
                ),
                
                const SizedBox(height: 15),
                if (_cargando) 
                  const CircularProgressIndicator()
                else 
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      estaActivo 
                        ? "membresia vigente" 
                        : "esperando confirmacion de pago en recepcion...", 
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)
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