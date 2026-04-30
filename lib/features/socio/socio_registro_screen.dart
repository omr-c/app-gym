import 'package:flutter/material.dart';
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
  bool _cargando = false;
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
      setState(() => _cargando = true);

      Socio nuevoSocio = Socio(
        nombre: _nombreController.text,
        telefono: _telefonoController.text,
        email: _emailController.text,
      );

      Socio? socioRegistrado = await _apiService.registrarsocio(nuevoSocio);
      setState(() => _cargando = false);

      if (socioRegistrado != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SocioQrScreen(socio: socioRegistrado))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('error al registrar socio'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('unete al gimnasio'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'nombre completo', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'campo obligatorio' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(labelText: 'telefono', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'campo obligatorio' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _emailController,
                enabled: widget.emailPrellenado == null,
                decoration: const InputDecoration(labelText: 'correo electronico', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 30),
              if (_cargando) const CircularProgressIndicator()
              else SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _registrar,
                  child: const Text('crear identidad digital'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}