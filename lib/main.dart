import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'firebase_options.dart';

import 'features/auth/login_screen.dart'; 
import 'features/socio/socio_model.dart';
import 'features/socio/socio_qr_screen.dart';
import 'features/recepcion/scanner_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Supabase.initialize(
    url: 'https://gorddzvcftvlxydwxkgo.supabase.co',
    anonKey: 'sb_publishable_lapr2m-sB6WNd49ODnMXwA_LRFCUI3R',
  );

  runApp(const GymApp());
}

class GymApp extends StatelessWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gym Rats System',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _verificarSesion();
  }

  void _verificarSesion() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _obtenerDatosSocio(user.email);
      } else {
        _navegarA(const LoginScreen());
      }
    });
  }

  Future<void> _obtenerDatosSocio(String? email) async {
    if (email == null) return;

    final prefs = await SharedPreferences.getInstance();
    final String? socioLocal = prefs.getString('socio_local');
    
    // Verificación de pertenencia del caché
    if (socioLocal != null) {
      final Map<String, dynamic> datosCache = json.decode(socioLocal);
      if (datosCache['email'] == email) {
        _navegarA(SocioQrScreen(socio: Socio.fromJson(datosCache)));
      } else {
        // Limpieza si los datos pertenecen a otra cuenta
        await prefs.remove('socio_local');
      }
    }

    final String url = "http://192.168.1.68:8080/api/auth/verificar/$email";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await prefs.setString('socio_local', response.body);
        
        final datos = json.decode(response.body);
        datos['email'] = email;
        Socio socioCargado = Socio.fromJson(datos);

        if (socioCargado.rol == 'admin' || socioCargado.rol == 'recepcion') {
          _navegarA(const ScannerScreen());
        } else {
          // Navegación con datos frescos para asegurar actualización
          _navegarA(SocioQrScreen(socio: socioCargado));
        }
      } else if (socioLocal == null) {
        _navegarA(const LoginScreen());
      }
    } catch (e) {
      if (socioLocal == null) _navegarA(const LoginScreen());
    }
  }

  void _navegarA(Widget pantalla) {
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => pantalla));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 80, color: Colors.blueAccent),
            SizedBox(height: 20),
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Sincronizando...', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}