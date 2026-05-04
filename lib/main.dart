import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'firebase_options.dart';

// importaciones de tus modelos y pantallas
import 'features/auth/login_screen.dart'; 
import 'features/socio/socio_model.dart';
import 'features/socio/socio_qr_screen.dart';
import 'features/recepcion/scanner_screen.dart';

void main() async {
  // asegura que los bindings de flutter esten listos
  WidgetsFlutterBinding.ensureInitialized();
  
  // inicializa firebase con tus opciones configuradas
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const GymApp());
}

class GymApp extends StatelessWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gym System Unificado',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
      ),
      // el home ahora es el verificador de sesion
      home: const AuthWrapper(),
    );
  }
}

// este widget decide que pantalla mostrar al iniciar la app
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // correccion: usamos addpostframecallback para esperar a que el frame termine
    // esto evita el error de navigator locked durante el build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revisarSesion();
    });
  }

  Future<void> _revisarSesion() async {
    // obtenemos el usuario actual de firebase auth
    User? usuarioFirebase = FirebaseAuth.instance.currentUser;

    // si no hay usuario, mandamos al login directamente
    if (usuarioFirebase == null) {
      _navegarA(const LoginScreen());
      return;
    }

    // si hay usuario, consultamos su rol y estado en el backend de spring boot
    final String email = usuarioFirebase.email!;
    final String url = "http://192.168.1.68:8080/api/auth/verificar/$email";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final datos = json.decode(response.body);
        // inyectamos el email ya que el backend no lo devuelve en este endpoint
        datos['email'] = email;
        Socio socioCargado = Socio.fromJson(datos);

        // redireccion segun el rol definido en la base de datos
        if (socioCargado.rol == 'admin' || socioCargado.rol == 'recepcion') {
          _navegarA(const ScannerScreen());
        } else {
          _navegarA(SocioQrScreen(socio: socioCargado));
        }
      } else {
        // si el backend no reconoce al usuario mandamos a login
        _navegarA(const LoginScreen());
      }
    } catch (e) {
      // en caso de error de red mandamos a login por seguridad
      _navegarA(const LoginScreen());
    }
  }

  // funcion auxiliar para cambiar de pantalla limpiando la pila
  void _navegarA(Widget pantalla) {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => pantalla),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // mostramos una pantalla de carga mientras el callback se dispara
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 80, color: Colors.blueAccent),
            SizedBox(height: 20),
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              "Cargando Aplicación...",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}