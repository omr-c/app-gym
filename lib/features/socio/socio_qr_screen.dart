import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart'; 
import 'dart:convert';
import 'dart:async';
import 'socio_model.dart';
import 'socio_api_service.dart';
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
  bool _subiendoFoto = false;
  Timer? _timer;
  String _imageVersion = DateTime.now().millisecondsSinceEpoch.toString();

  final SocioApiService _apiService = SocioApiService();
  final ImagePicker _picker = ImagePicker();
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _socioActual = widget.socio;

    // Refresco automático al entrar para sincronizar foto y detalles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refrescarEstado(silencioso: true);
    });

    if (_socioActual.estado.toLowerCase() != 'activo') {
      _iniciarVerificacionAutomatica();
    }
  }

  void _iniciarVerificacionAutomatica() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _refrescarEstado(silencioso: true);
      if (_socioActual.estado.toLowerCase() == 'activo') _timer?.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refrescarEstado({bool silencioso = false}) async {
    if (!silencioso) setState(() => _cargando = true);
    final String url = "http://192.168.1.68:8080/api/socios/perfil/${_socioActual.qrToken}";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('socio_local', response.body);
        if (mounted) setState(() => _socioActual = Socio.fromJson(json.decode(response.body)));
      }
    } catch (e) { debugPrint("Error de sincronización: $e"); }
    if (mounted && !silencioso) setState(() => _cargando = false);
  }

  Future<void> _actualizarPerfilCompleto() async {
    final TextEditingController nameController = TextEditingController(text: _socioActual.nombre);
    XFile? nuevaImagen;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Editar Perfil", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
                  if (picked != null) setModalState(() => nuevaImagen = picked);
                },
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: nuevaImagen != null 
                    ? FileImage(File(nuevaImagen!.path)) 
                    : (_socioActual.fotoUrl != null ? CachedNetworkImageProvider("${_socioActual.fotoUrl}?v=$_imageVersion") : null) as ImageProvider?,
                  child: nuevaImagen == null && _socioActual.fotoUrl == null ? const Icon(Icons.add_a_photo, size: 30) : null,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Nombre completo", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  onPressed: _subiendoFoto ? null : () async {
                    setModalState(() => _subiendoFoto = true);
                    String? urlFinal = _socioActual.fotoUrl;
                    if (nuevaImagen != null) {
                      final String ruta = 'perfiles/${_socioActual.id}.jpg';
                      await supabase.storage.from('avatars').upload(ruta, File(nuevaImagen!.path), fileOptions: const FileOptions(upsert: true));
                      urlFinal = supabase.storage.from('avatars').getPublicUrl(ruta);
                    }
                    bool exito = await _apiService.actualizarPerfil(_socioActual.id!, nameController.text.trim(), urlFinal);
                    if (exito && mounted) {
                      setState(() => _imageVersion = DateTime.now().millisecondsSinceEpoch.toString());
                      await _refrescarEstado(silencioso: true);
                      Navigator.pop(context);
                    }
                    setModalState(() => _subiendoFoto = false);
                  },
                  child: _subiendoFoto ? const CircularProgressIndicator(color: Colors.white) : const Text("Guardar Cambios"),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool activo = _socioActual.estado.toLowerCase() == 'activo';
    bool alerta = _socioActual.diasRestantes <= 7;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Mi Identidad Gym', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.redAccent), onPressed: () => _cerrarSesion())
        ],
      ),
      body: _cargando 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () => _refrescarEstado(silencioso: false),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildTarjetaPrincipal(activo, alerta),
                  const SizedBox(height: 20),
                  _buildSeccionDetalles(),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: _actualizarPerfilCompleto,
                    icon: const Icon(Icons.manage_accounts),
                    label: const Text("Gestionar Perfil"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blueAccent,
                      side: const BorderSide(color: Colors.blueAccent)
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildTarjetaPrincipal(bool activo, bool alerta) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: const Offset(0, 5))]),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: activo ? Colors.green[600] : Colors.orange[600], borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25))),
            child: Center(child: Text(activo ? "SOCIO ACTIVO" : "PAGO PENDIENTE", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2))),
          ),
          const SizedBox(height: 25),
          
          SizedBox(
            width: 100,
            height: 100,
            child: ClipOval(
              child: _socioActual.fotoUrl != null && _socioActual.fotoUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: "${_socioActual.fotoUrl}?v=$_imageVersion",
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => const Icon(Icons.person, size: 50),
                    )
                  : Container(color: Colors.blue[50], child: const Icon(Icons.person, size: 50, color: Colors.blueAccent)),
            ),
          ),
          
          const SizedBox(height: 15),
          Text(_socioActual.nombre, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(_socioActual.email, style: TextStyle(color: Colors.grey[600])),
          const Padding(padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30), child: Divider()),
          const Text("QR DE ACCESO", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 10),
          QrImageView(data: _socioActual.qrToken ?? "n/a", size: 180, eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: activo ? Colors.black : Colors.grey[300])),
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.only(bottom: 25),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: activo ? (alerta ? Colors.orange[50] : Colors.green[50]) : Colors.orange[50],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined, size: 18, color: activo ? (alerta ? Colors.orange : Colors.green) : Colors.orange),
                const SizedBox(width: 8),
                Text(
                  activo ? "${_socioActual.diasRestantes} días vigentes" : "Esperando validación",
                  style: TextStyle(fontWeight: FontWeight.bold, color: activo ? (alerta ? Colors.orange[700] : Colors.green[700]) : Colors.orange[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionDetalles() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Información Registrada", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(height: 25),
          _buildItemDetalle(Icons.phone_android, "Teléfono", _socioActual.telefono),
          const SizedBox(height: 15),
          _buildItemDetalle(Icons.vpn_key_outlined, "Socio ID", _socioActual.id?.substring(0, 8).toUpperCase() ?? "N/A"),
        ],
      ),
    );
  }

  Widget _buildItemDetalle(IconData icono, String titulo, String valor) {
    return Row(
      children: [
        Icon(icono, size: 22, color: Colors.blueAccent),
        const SizedBox(width: 15),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          Text(valor, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ]),
      ],
    );
  }

  Future<void> _cerrarSesion() async {
    _timer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('socio_local');
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }
}