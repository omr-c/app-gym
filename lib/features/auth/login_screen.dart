import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../socio/socio_registro_screen.dart';
import '../socio/socio_qr_screen.dart';
import '../socio/socio_model.dart';
import '../recepcion/scanner_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // CORRECCIÓN: Configuración de GoogleSignIn con scopes necesarios
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _cargando = false;

  Future<void> _verificarEnSpringBoot(String? email) async {
    if (email == null) return;
    
    // Tu IP local para la conexión con el servidor de Spring Boot[cite: 1]
    final String url = "http://192.168.1.127:8080/api/auth/verificar/$email";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final datos = json.decode(response.body);
        Socio socioCargado = Socio.fromJson(datos);

        // Validación de roles para redirección[cite: 1]
        if (socioCargado.rol == 'admin' || socioCargado.rol == 'recepcion') {
          debugPrint("Rol detectado: ${socioCargado.rol}. Redirigiendo a recepción.");
          if (mounted) {
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (context) => const ScannerScreen())
            );
          }
        } else {
          debugPrint("Rol detectado: socio. Redirigiendo a identidad digital.");
          if (mounted) {
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (context) => SocioQrScreen(socio: socioCargado))
            );
          }
        }
      } else if (response.statusCode == 404) {
        if (mounted) {
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (context) => SocioRegistroScreen(emailPrellenado: email))
          );
        }
      }
    } catch (e) {
      _mostrarError("Error de conexión con el servidor: $e");
    }
  }

  Future<void> _loginConGoogle() async {
    setState(() => _cargando = true);
    try {
      // Iniciar flujo de Google Sign-In[cite: 1]
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        setState(() => _cargando = false);
        return; 
      }

      // Obtener tokens de autenticación[cite: 1]
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Crear credencial para Firebase[cite: 1]
      final AuthCredential credencial = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken, 
        idToken: googleAuth.idToken,
      );

      // Autenticar en Firebase[cite: 1]
      final UserCredential userCredential = await _auth.signInWithCredential(credencial);
      
      // Verificar usuario en el Backend de Java[cite: 1]
      await _verificarEnSpringBoot(userCredential.user?.email);
      
    } catch (e) {
      debugPrint("Error Google Sign-In: $e");
      _mostrarError("Error al autenticar con Google");
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _loginConCorreo() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;
    setState(() => _cargando = true);
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(), 
        password: _passwordController.text.trim(),
      );
      await _verificarEnSpringBoot(userCredential.user?.email);
    } catch (e) {
      _mostrarError("Correo o contraseña inválidos");
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Icon(Icons.fitness_center, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 20),
              const Text("SMART GYM", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController, 
                decoration: const InputDecoration(labelText: "Correo", border: OutlineInputBorder())
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController, 
                decoration: const InputDecoration(labelText: "Contraseña", border: OutlineInputBorder()), 
                obscureText: true
              ),
              const SizedBox(height: 25),
              if (_cargando) const CircularProgressIndicator()
              else ...[
                SizedBox(
                  width: double.infinity, 
                  height: 50, 
                  child: ElevatedButton(onPressed: _loginConCorreo, child: const Text("Entrar"))
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, 
                  height: 50, 
                  child: OutlinedButton.icon(
                    onPressed: _loginConGoogle,
                    icon: Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png', 
                      height: 24
                    ),
                    label: const Text("Continuar con Google"),
                  )
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}