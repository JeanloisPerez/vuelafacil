import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/profile_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  static const String routeName = '/profile';

  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;
  final profileService = ProfileServiceSupabase();
  bool _editing = false;
  final FocusNode _firstFieldFocus = FocusNode();

  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _documentoCtrl = TextEditingController();
  final _tipoDocumentoCtrl = TextEditingController();
  final _nacionalidadCtrl = TextEditingController();
  final _fechaCtrl = TextEditingController();

  bool _loading = true;
  String? _imageUrl;
  DateTime? _fechaNacimiento;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstFieldFocus.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase
        .from('users')
        .select()
        .eq('usuario_id', user.id)
        .maybeSingle();

    if (data != null) {
      _nombreCtrl.text = data['nombre'] ?? '';
      _apellidoCtrl.text = data['apellido'] ?? '';
      _telefonoCtrl.text = data['telefono'] ?? '';
      _nacionalidadCtrl.text = data['nacionalidad'] ?? '';
      _documentoCtrl.text = data['documento_identidad'] ?? '';
      _tipoDocumentoCtrl.text = data['tipo_documento'] ?? '';

      _imageUrl = data['image_url'];

      if (data['fecha_nacimiento'] != null) {
        final dt = DateTime.tryParse(data['fecha_nacimiento']);
        if (dt != null) {
          _fechaNacimiento = dt;
          _fechaCtrl.text = "${dt.day}/${dt.month}/${dt.year}";
        }
      }
    }

    setState(() => _loading = false);
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        _fechaNacimiento = picked;
        _fechaCtrl.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _uploadImage() async {
    if (!_editing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Activa edición para cambiar la foto")),
      );
      return;
    }
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    setState(() => _loading = true);

    final url = await profileService.uploadProfileImage(picked.path);

    setState(() => _loading = false);

    if (url == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Error al subir la imagen. Verifica que el bucket exista en Supabase.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase
          .from('users')
          .update({'image_url': url})
          .eq('usuario_id', user.id);

      if (!mounted) return;
      setState(() => _imageUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Foto actualizada"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      print('Could not update image_url: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No se pudo guardar en DB: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase
        .from('users')
        .update({
          'nombre': _nombreCtrl.text.trim(),
          'apellido': _apellidoCtrl.text.trim(),
          'telefono': _telefonoCtrl.text.trim(),
          'nacionalidad': _nacionalidadCtrl.text.trim(),
          'documento_identidad': _documentoCtrl.text.trim(),
          'tipo_documento': _tipoDocumentoCtrl.text.trim(),
          'fecha_nacimiento': _fechaNacimiento?.toIso8601String(),
        })
        .eq('usuario_id', user.id);

    setState(() => _loading = false);
    // exit edit mode after save
    setState(() => _editing = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Perfil actualizado")));
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cerrar sesión"),
        content: const Text("¿Deseas cerrar la sesión?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Cerrar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await supabase.auth.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        LoginScreen.routeName,
        (r) => false,
      );
    }
  }

  InputDecoration _fieldDecoration({required String label, Widget? prefix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: prefix,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Mi Perfil",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // solo botón de cerrar sesión en la AppBar (editar se muestra en el header)
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.redAccent),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          children: [
            // Header card with gradient and avatar
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF5A3FFF), Color(0xFF7C63FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Avatar with border/glow
                  GestureDetector(
                    onTap: _uploadImage,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        gradient: LinearGradient(
                          colors: [
                            _imageUrl == null
                                ? Colors.white
                                : Colors.white.withOpacity(0.9),
                            Colors.white.withOpacity(0.6),
                          ],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.white,
                        backgroundImage: _imageUrl != null
                            ? NetworkImage(_imageUrl!)
                            : null,
                        child: _imageUrl == null
                            ? const Icon(
                                Icons.person,
                                size: 44,
                                color: Color(0xFF5A3FFF),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${_nombreCtrl.text} ${_apellidoCtrl.text}"
                                  .trim()
                                  .isEmpty
                              ? "Usuario"
                              : "${_nombreCtrl.text} ${_apellidoCtrl.text}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          supabase.auth.currentUser?.email ?? '',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.verified,
                                    size: 14,
                                    color: Colors.white70,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Cuenta',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if ((_telefonoCtrl.text).isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.phone,
                                      size: 14,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _telefonoCtrl.text,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (_editing) {
                        // si ya está en modo edición, guardar cambios
                        _save();
                      } else {
                        setState(() {
                          _editing = true;
                        });
                        // focus al primer campo para editar
                        FocusScope.of(context).requestFocus(_firstFieldFocus);
                      }
                    },
                    icon: Icon(
                      _editing ? Icons.check_rounded : Icons.edit_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Card with form
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Two column layout on wide screens handled by Wrap
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width > 760
                              ? (MediaQuery.of(context).size.width - 96) / 2
                              : double.infinity,
                          child: TextFormField(
                            controller: _nombreCtrl,
                            focusNode: _firstFieldFocus,
                            readOnly: !_editing,
                            decoration: _fieldDecoration(
                              label: "Nombre",
                              prefix: const Icon(Icons.person),
                            ),
                            validator: (v) =>
                                v!.isEmpty ? "Campo obligatorio" : null,
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width > 760
                              ? (MediaQuery.of(context).size.width - 96) / 2
                              : double.infinity,
                          child: TextFormField(
                            controller: _apellidoCtrl,
                            readOnly: !_editing,
                            decoration: _fieldDecoration(
                              label: "Apellido",
                              prefix: const Icon(Icons.person_outline),
                            ),
                            validator: (v) =>
                                v!.isEmpty ? "Campo obligatorio" : null,
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width > 760
                              ? (MediaQuery.of(context).size.width - 96) / 2
                              : double.infinity,
                          child: TextFormField(
                            controller: _telefonoCtrl,
                            readOnly: !_editing,
                            decoration: _fieldDecoration(
                              label: "Teléfono",
                              prefix: const Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width > 760
                              ? (MediaQuery.of(context).size.width - 96) / 2
                              : double.infinity,
                          child: GestureDetector(
                            onTap: _pickBirthDate,
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: _fechaCtrl,
                                readOnly:
                                    true, // always readonly but only pick when editing
                                decoration: _fieldDecoration(
                                  label: "Fecha de nacimiento",
                                  prefix: const Icon(Icons.calendar_today),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width > 760
                              ? (MediaQuery.of(context).size.width - 96) / 2
                              : double.infinity,
                          child: TextFormField(
                            controller: _nacionalidadCtrl,
                            readOnly: !_editing,
                            decoration: _fieldDecoration(
                              label: "Nacionalidad",
                              prefix: const Icon(Icons.flag),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width > 760
                              ? (MediaQuery.of(context).size.width - 96) / 2
                              : double.infinity,
                          child: TextFormField(
                            controller: _documentoCtrl,
                            readOnly: !_editing,
                            decoration: _fieldDecoration(
                              label: "Documento",
                              prefix: const Icon(Icons.badge),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width > 760
                              ? (MediaQuery.of(context).size.width - 96) / 2
                              : double.infinity,
                          child: TextFormField(
                            controller: _tipoDocumentoCtrl,
                            readOnly: !_editing,
                            decoration: _fieldDecoration(
                              label: "Tipo de documento",
                              prefix: const Icon(Icons.description),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Save button (gradient)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _editing ? _save : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF5A3FFF), Color(0xFF7C63FF)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF5A3FFF,
                                ).withOpacity(0.18),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              _editing ? "Guardar cambios" : "Editar perfil",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Secondary actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () async {
                            // permitir subir foto también desde aquí
                            await _uploadImage();
                          },
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Color(0xFF5A3FFF),
                          ),
                          label: const Text("Cambiar foto"),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            // eliminar foto
                            final user = supabase.auth.currentUser;
                            if (user == null) return;
                            await supabase
                                .from('users')
                                .update({'image_url': null})
                                .eq('usuario_id', user.id);
                            setState(() => _imageUrl = null);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Foto eliminada")),
                            );
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          label: const Text(
                            "Eliminar foto",
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Small tips card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.06)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Mantén tu perfil actualizado para recibir notificaciones y ofertas personalizadas.",
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
