import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'socio_model.dart';
import 'socio_api_service.dart';
import 'socio_qr_screen.dart';

class SocioRegistroScreen extends StatefulWidget {
  final String? emailPrellenado;
  const SocioRegistroScreen({super.key, this.emailPrellenado});

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

  bool _cargando = false;
  bool _oscurecerContrasena = true;
  bool _oscurecerConfirmar = true;
  
  final SocioApiService _apiService = SocioApiService();

  @override
  void initState() {
    super.initState();
    if (widget.emailPrellenado != null) {
      _emailController.text = widget.emailPrellenado!;
    }
  }

  void _registrar() async {
    if (_formKey.currentState!.validate()) {
      if (widget.emailPrellenado == null && 
          _passwordController.text != _confirmarController.text) {
        _mostrarMensaje('Las contraseñas no coinciden');
        return;
      }

      setState(() => _cargando = true);

      try {
        // 1. preparar datos para el backend
        Socio nuevoSocio = Socio(
          nombre: _nombreController.text.trim(),
          telefono: _telefonoController.text.trim(),
          email: _emailController.text.trim(),
        );

        // 2. intentar registrar en spring boot (aqui se valida el telefono)
        Socio? socioRegistrado = await _apiService.registrarsocio(nuevoSocio);
        
        if (socioRegistrado == null) {
          // si el api devuelve null, probablemente el telefono o email ya existen
          if (mounted) setState(() => _cargando = false);
          _mostrarMensaje('El teléfono o correo ya están registrados en el gimnasio');
          return;
        }

        // 3. si el backend acepto al socio, creamos la cuenta en firebase auth
        if (widget.emailPrellenado == null) {
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
        }

        if (mounted) {
          setState(() => _cargando = false);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SocioQrScreen(socio: socioRegistrado))
          );
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) setState(() => _cargando = false);
        _mostrarMensaje(e.code == 'email-already-in-use' 
            ? 'Este correo ya esta registrado' 
            : 'Error en la cuenta: ${e.message}');
      } catch (e) {
        if (mounted) setState(() => _cargando = false);
        _mostrarMensaje('Error inesperado durante el registro');
      }
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Únete al gimnasio'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre completo', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _emailController,
                enabled: widget.emailPrellenado == null,
                decoration: const InputDecoration(labelText: 'Correo electrónico', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
              ),
              
              if (widget.emailPrellenado == null) ...[
                const SizedBox(height: 15),
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
                  validator: (value) => (value == null || value.length < 6) ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _confirmarController,
                  obscureText: _oscurecerConfirmar,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Contraseña', 
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_oscurecerConfirmar ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _oscurecerConfirmar = !_oscurecerConfirmar),
                    )
                  ),
                  validator: (value) => value!.isEmpty ? 'Debes confirmar la contraseña' : null,
                ),
              ],
              
              const SizedBox(height: 30),
              if (_cargando) const CircularProgressIndicator()
              else ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _registrar,
                    child: const Text('Crear identidad digital'),
                  ),
                ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("¿Ya tienes cuenta? Inicia sesión", style: TextStyle(color: Colors.grey))
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}