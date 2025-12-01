import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  static const String routeName = '/register';

  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _fechaNacimientoCtrl = TextEditingController();
  final _nacionalidadCtrl = TextEditingController();
  final _documentoCtrl = TextEditingController();
  final _tipoDocumentoCtrl = TextEditingController();

  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  DateTime? _selectedBirthDate;

  final _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _telefonoCtrl.dispose();
    _fechaNacimientoCtrl.dispose();
    _nacionalidadCtrl.dispose();
    _documentoCtrl.dispose();
    _tipoDocumentoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = DateTime(now.year - 18, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        _fechaNacimientoCtrl.text =
            '${picked.day.toString().padLeft(2, '0')}/'
            '${picked.month.toString().padLeft(2, '0')}/'
            '${picked.year}';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final nombre = _nombreCtrl.text.trim();
      final apellido = _apellidoCtrl.text.trim();
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text;
      final telefono = _telefonoCtrl.text.trim().isEmpty
          ? null
          : _telefonoCtrl.text.trim();
      final nacionalidad = _nacionalidadCtrl.text.trim().isEmpty
          ? null
          : _nacionalidadCtrl.text.trim();
      final documento = _documentoCtrl.text.trim().isEmpty
          ? null
          : _documentoCtrl.text.trim();
      final tipoDocumento = _tipoDocumentoCtrl.text.trim().isEmpty
          ? null
          : _tipoDocumentoCtrl.text.trim();

      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = authResponse.user;
      if (user == null) {
        throw Exception('No se pudo crear el usuario.');
      }

      await _supabase.from('users').insert({
        'usuario_id': user.id,
        'nombre': nombre,
        'apellido': apellido,
        'telefono': telefono,
        'fecha_nacimiento': _selectedBirthDate?.toIso8601String(),
        'nacionalidad': nacionalidad,
        'documento_identidad': documento,
        'tipo_documento': tipoDocumento,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cuenta creada correctamente. Revisa tu correo para confirmar.',
          ),
        ),
      );

      // Ir al login
      Navigator.pushReplacementNamed(context, LoginScreen.routeName);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al registrar: $e')));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    Widget? prefix,
    Widget? suffix,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false,
    void Function()? onTap,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefix,
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final maxWidth = width > 900 ? 900.0 : (width > 700 ? 700.0 : width * 0.95);
    final isWide = width > 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Crear cuenta',
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          height: 68,
                          width: 68,
                          decoration: BoxDecoration(
                            color: const Color(0xFF5A3FFF).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_add_alt_1,
                            size: 36,
                            color: Color(0xFF5A3FFF),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Bienvenido',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Crea una cuenta para continuar',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Form fields: two columns on wide screens
                    isWide
                        ? Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: (maxWidth - 12) / 2,
                                child: _buildTextField(
                                  controller: _nombreCtrl,
                                  label: 'Nombre',
                                  prefix: const Icon(Icons.person),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Ingrese su nombre'
                                      : null,
                                ),
                              ),
                              SizedBox(
                                width: (maxWidth - 12) / 2,
                                child: _buildTextField(
                                  controller: _apellidoCtrl,
                                  label: 'Apellido',
                                  prefix: const Icon(Icons.person_outline),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Ingrese su apellido'
                                      : null,
                                ),
                              ),
                              SizedBox(
                                width: (maxWidth - 12) / 2,
                                child: _buildTextField(
                                  controller: _emailCtrl,
                                  label: 'Correo electrónico',
                                  prefix: const Icon(Icons.email),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty)
                                      return 'Ingrese su correo';
                                    final emailReg = RegExp(
                                      r'^[^@]+@[^@]+\.[^@]+$',
                                    );
                                    if (!emailReg.hasMatch(v.trim()))
                                      return 'Correo no válido';
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(
                                width: (maxWidth - 12) / 2,
                                child: _buildTextField(
                                  controller: _telefonoCtrl,
                                  label: 'Teléfono (opcional)',
                                  prefix: const Icon(Icons.phone),
                                  keyboardType: TextInputType.phone,
                                ),
                              ),
                              SizedBox(
                                width: (maxWidth - 12) / 2,
                                child: _buildTextField(
                                  controller: _passwordCtrl,
                                  label: 'Contraseña',
                                  prefix: const Icon(Icons.lock),
                                  obscure: _obscurePass,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscurePass
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscurePass = !_obscurePass,
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Ingrese una contraseña';
                                    if (v.length < 6)
                                      return 'Mínimo 6 caracteres';
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(
                                width: (maxWidth - 12) / 2,
                                child: _buildTextField(
                                  controller: _confirmPasswordCtrl,
                                  label: 'Confirmar contraseña',
                                  prefix: const Icon(Icons.lock_outline),
                                  obscure: _obscureConfirm,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm,
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Repita la contraseña';
                                    if (v != _passwordCtrl.text)
                                      return 'Las contraseñas no coinciden';
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(
                                width: (maxWidth - 12) / 2,
                                child: GestureDetector(
                                  onTap: _pickBirthDate,
                                  child: AbsorbPointer(
                                    child: _buildTextField(
                                      controller: _fechaNacimientoCtrl,
                                      label: 'Fecha de nacimiento (opcional)',
                                      prefix: const Icon(Icons.calendar_today),
                                      readOnly: true,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: (maxWidth - 12) / 2,
                                child: _buildTextField(
                                  controller: _nacionalidadCtrl,
                                  label: 'Nacionalidad (opcional)',
                                  prefix: const Icon(Icons.flag),
                                ),
                              ),
                              SizedBox(
                                width: (maxWidth - 12) / 2,
                                child: _buildTextField(
                                  controller: _documentoCtrl,
                                  label: 'Documento (opcional)',
                                  prefix: const Icon(Icons.badge),
                                ),
                              ),
                              SizedBox(
                                width: (maxWidth - 12) / 2,
                                child: _buildTextField(
                                  controller: _tipoDocumentoCtrl,
                                  label: 'Tipo de documento (opcional)',
                                  prefix: const Icon(Icons.description),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _buildTextField(
                                controller: _nombreCtrl,
                                label: 'Nombre',
                                prefix: const Icon(Icons.person),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Ingrese su nombre'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(
                                controller: _apellidoCtrl,
                                label: 'Apellido',
                                prefix: const Icon(Icons.person_outline),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Ingrese su apellido'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(
                                controller: _emailCtrl,
                                label: 'Correo electrónico',
                                prefix: const Icon(Icons.email),
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty)
                                    return 'Ingrese su correo';
                                  final emailReg = RegExp(
                                    r'^[^@]+@[^@]+\.[^@]+$',
                                  );
                                  if (!emailReg.hasMatch(v.trim()))
                                    return 'Correo no válido';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(
                                controller: _telefonoCtrl,
                                label: 'Teléfono (opcional)',
                                prefix: const Icon(Icons.phone),
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(
                                controller: _passwordCtrl,
                                label: 'Contraseña',
                                prefix: const Icon(Icons.lock),
                                obscure: _obscurePass,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscurePass
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePass = !_obscurePass,
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'Ingrese una contraseña';
                                  if (v.length < 6)
                                    return 'Mínimo 6 caracteres';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(
                                controller: _confirmPasswordCtrl,
                                label: 'Confirmar contraseña',
                                prefix: const Icon(Icons.lock_outline),
                                obscure: _obscureConfirm,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm,
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'Repita la contraseña';
                                  if (v != _passwordCtrl.text)
                                    return 'Las contraseñas no coinciden';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: _pickBirthDate,
                                child: AbsorbPointer(
                                  child: _buildTextField(
                                    controller: _fechaNacimientoCtrl,
                                    label: 'Fecha de nacimiento (opcional)',
                                    prefix: const Icon(Icons.calendar_today),
                                    readOnly: true,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(
                                controller: _nacionalidadCtrl,
                                label: 'Nacionalidad (opcional)',
                                prefix: const Icon(Icons.flag),
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(
                                controller: _documentoCtrl,
                                label: 'Documento (opcional)',
                                prefix: const Icon(Icons.badge),
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(
                                controller: _tipoDocumentoCtrl,
                                label: 'Tipo de documento (opcional)',
                                prefix: const Icon(Icons.description),
                              ),
                            ],
                          ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A3FFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Crear cuenta',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '¿Ya tienes cuenta?',
                          style: TextStyle(color: Colors.black54),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(
                              context,
                              LoginScreen.routeName,
                            );
                          },
                          child: const Text(
                            'Inicia sesión',
                            style: TextStyle(color: Color(0xFF5A3FFF)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
