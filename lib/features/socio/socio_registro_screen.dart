import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'socio_model.dart';
import 'socio_api_service.dart';
import 'socio_qr_screen.dart';
import '../auth/login_screen.dart';

class SocioRegistroScreen extends StatefulWidget {
  final String? emailGoogle;
  final String? nombreGoogle;
  
  const SocioRegistroScreen({super.key, this.emailGoogle, this.nombreGoogle});

  @override
  _SocioRegistroScreenState createState() => _SocioRegistroScreenState();
}

class _SocioRegistroScreenState extends State<SocioRegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmarController = TextEditingController();
  final TextEditingController _codigoController = TextEditingController();

  bool _cargando = false;
  bool _esperandoCodigo = false;
  
  // Variables para controlar la visibilidad de las contraseñas
  bool _oscurecerContrasena = true;
  bool _oscurecerConfirmar = true;
  
  late bool _vieneDeGoogle;
  final SocioApiService _apiService = SocioApiService();

  @override
  void initState() {
    super.initState();
    _vieneDeGoogle = widget.emailGoogle != null;
    if (_vieneDeGoogle) {
      _emailController.text = widget.emailGoogle!;
      _nombreController.text = widget.nombreGoogle ?? "";
    }
  }

  void _pedirCodigo() async {
    if (_formKey.currentState!.validate()) {
      if (!_vieneDeGoogle && _passwordController.text != _confirmarController.text) {
        _mostrarMensaje('Las contraseñas no coinciden');
        return;
      }
      setState(() => _cargando = true);

      if (_vieneDeGoogle) {
        _guardarPerfilEnServidor();
        return;
      }

      final int statusCode = await _apiService.enviarCodigo(_emailController.text.trim(), _telefonoController.text.trim());
      
      setState(() => _cargando = false);
      if (statusCode == 200) {
        setState(() => _esperandoCodigo = true);
        _mostrarMensaje('Código enviado al correo');
      } else if (statusCode == 400 || statusCode == 409) {
        _mostrarMensaje('El correo o teléfono ya están registrados en el sistema');
      } else {
        _mostrarMensaje('Error en el servidor al enviar correo (Fallo de conexión SMTP)');
      }
    }
  }

  void _completarRegistroManual() async {
    if (_codigoController.text.isEmpty) return;
    setState(() => _cargando = true);

    bool esValido = await _apiService.validarCodigo(_emailController.text.trim(), _codigoController.text.trim());

    if (esValido) {
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        _guardarPerfilEnServidor();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          _mostrarMensaje('Este correo ya está en Firebase. Usa el botón de limpieza en el Login.');
        } else {
          _mostrarMensaje('Error en autenticación: ${e.message}');
        }
        if (mounted) setState(() => _cargando = false);
      }
    } else {
      _mostrarMensaje('El código es incorrecto');
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _guardarPerfilEnServidor() async {
    Socio nuevo = Socio(
      nombre: _nombreController.text.trim(),
      telefono: _telefonoController.text.trim(),
      email: _emailController.text.trim(),
    );

    Socio? registrado = await _apiService.registrarsocio(nuevo);
    
    if (registrado != null && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SocioQrScreen(socio: registrado)));
    } else {
      _mostrarMensaje('Error al guardar el perfil en la base de datos');
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
    }
    if (mounted) setState(() => _cargando = false);
  }

  void _mostrarMensaje(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_vieneDeGoogle ? 'Completar Perfil' : 'Registro Manual'), 
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            if (_vieneDeGoogle) {
              await FirebaseAuth.instance.signOut();
              await GoogleSignIn().signOut();
            }
            if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (!_esperandoCodigo) ...[
                TextFormField(controller: _nombreController, decoration: const InputDecoration(labelText: 'Nombre completo', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Requerido' : null),
                const SizedBox(height: 15),
                TextFormField(controller: _telefonoController, decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Requerido' : null),
                const SizedBox(height: 15),
                TextFormField(controller: _emailController, enabled: !_vieneDeGoogle, decoration: const InputDecoration(labelText: 'Correo', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Requerido' : null),
                
                if (!_vieneDeGoogle) ...[
                  const SizedBox(height: 15),
                  // Campo de contraseña con boton para mostrar/ocultar
                  TextFormField(
                    controller: _passwordController, 
                    obscureText: _oscurecerContrasena, 
                    decoration: InputDecoration(
                      labelText: 'Contraseña', 
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_oscurecerContrasena ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _oscurecerContrasena = !_oscurecerContrasena),
                      )
                    ), 
                    validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null
                  ),
                  const SizedBox(height: 15),
                  // Campo confirmar contraseña con boton para mostrar/ocultar
                  TextFormField(
                    controller: _confirmarController, 
                    obscureText: _oscurecerConfirmar, 
                    decoration: InputDecoration(
                      labelText: 'Confirmar contraseña', 
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_oscurecerConfirmar ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _oscurecerConfirmar = !_oscurecerConfirmar),
                      )
                    )
                  ),
                ],

                const SizedBox(height: 30),
                if (_cargando) const CircularProgressIndicator()
                else SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _pedirCodigo, child: Text(_vieneDeGoogle ? 'Finalizar Registro' : 'Verificar y Enviar Código'))),
              ] else ...[
                const Text("Ingresa el código enviado a tu correo:"),
                const SizedBox(height: 20),
                TextFormField(controller: _codigoController, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, letterSpacing: 8), keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder())),
                const SizedBox(height: 30),
                if (_cargando) const CircularProgressIndicator()
                else ...[
                  SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _completarRegistroManual, child: const Text('Completar Registro'))),
                  TextButton(onPressed: () => setState(() => _esperandoCodigo = false), child: const Text("Editar datos ingresados")),
                ]
              ],
            ],
          ),
        ),
      ),
    );
  }
}