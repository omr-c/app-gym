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
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _cargando = false;
  bool _oscurecerContrasena = true;

  // verifica el usuario contra el backend de spring boot
  Future<void> _verificarEnSpringBoot(String? email) async {
    if (email == null) return;
    final String url = "http://192.168.1.68:8080/api/auth/verificar/$email";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final datos = json.decode(response.body);
        datos['email'] = email;
        Socio socioCargado = Socio.fromJson(datos);

        if (socioCargado.rol == 'admin' || socioCargado.rol == 'recepcion') {
          if (mounted) {
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (context) => const ScannerScreen())
            );
          }
        } else {
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
      _mostrarMensaje("Error de conexión con el servidor", esError: true);
    }
  }

  // funcion para enviar el correo de recuperacion de contrasena
  Future<void> _recuperarContrasena() async {
    String email = _emailController.text.trim();
    
    if (email.isEmpty) {
      _mostrarMensaje("Por favor, escribe tu correo para enviarte el enlace", esError: true);
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _mostrarMensaje("Enlace de recuperación enviado a su correo");
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _mostrarMensaje("No existe un usuario con ese correo", esError: true);
      } else {
        _mostrarMensaje("Error al enviar el correo: ${e.message}", esError: true);
      }
    }
  }

  Future<void> _loginConGoogle() async {
    setState(() => _cargando = true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _cargando = false);
        return; 
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credencial = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken, 
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _auth.signInWithCredential(credencial);
      await _verificarEnSpringBoot(userCredential.user?.email);
    } catch (e) {
      _mostrarMensaje("Error al conectar con Google", esError: true);
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
    } on FirebaseAuthException catch (e) {
      _mostrarMensaje("Credenciales incorrectas o usuario inexistente", esError: true);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: esError ? Colors.red : Colors.green)
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
              const Text("Inicia Sesión", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController, 
                decoration: const InputDecoration(labelText: "Correo", border: OutlineInputBorder())
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController, 
                obscureText: _oscurecerContrasena,
                decoration: InputDecoration(
                  labelText: "Contraseña", 
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_oscurecerContrasena ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _oscurecerContrasena = !_oscurecerContrasena),
                  )
                )
              ),
              
              // enlace de recuperacion de contrasena
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _recuperarContrasena,
                  child: const Text("¿Olvidaste tu contraseña?", style: TextStyle(fontSize: 13))
                ),
              ),

              const SizedBox(height: 10),
              if (_cargando) const CircularProgressIndicator()
              else ...[
                SizedBox(
                  width: double.infinity, 
                  height: 50, 
                  child: ElevatedButton(onPressed: _loginConCorreo, child: const Text("Entrar"))
                ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => const SocioRegistroScreen())
                    );
                  },
                  child: const Text("¿No tienes cuenta? Regístrate aquí", style: TextStyle(color: Colors.blueAccent))
                ),
                const SizedBox(height: 10),
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