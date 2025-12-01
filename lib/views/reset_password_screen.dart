import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordScreen extends StatefulWidget {
  static const String routeName = '/resetPassword';

  final String? code;

  const ResetPasswordScreen({super.key, this.code});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _loading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _success = false;

  @override
  void dispose() {
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final supabase = Supabase.instance.client;

      // Usar el código del deep link para resetear la contraseña
      await supabase.auth.updateUser(
        UserAttributes(password: _newPassCtrl.text.trim()),
      );

      setState(() => _success = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña actualizada correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      // Redirigir al login después de 2 segundos
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error inesperado: ${e.toString()}')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _success
            ? null
            : IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.black87,
                ),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            child: Column(
              children: [
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5A3FFF).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _success ? Icons.check_circle : Icons.lock_outline,
                    size: 60,
                    color: _success ? Colors.green : const Color(0xFF5A3FFF),
                  ),
                ),
                const SizedBox(height: 25),
                Text(
                  _success ? "Contraseña actualizada" : "Nueva contraseña",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _success
                      ? "Tu contraseña ha sido cambiada exitosamente"
                      : "Ingresa tu nueva contraseña",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54, fontSize: 16),
                ),
                const SizedBox(height: 30),
                if (!_success)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _newPassCtrl,
                            obscureText: _obscure1,
                            decoration: InputDecoration(
                              labelText: 'Nueva contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure1
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure1 = !_obscure1),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Ingrese contraseña';
                              }
                              if (v.length < 6) {
                                return 'Mínimo 6 caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPassCtrl,
                            obscureText: _obscure2,
                            decoration: InputDecoration(
                              labelText: 'Confirmar contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure2
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure2 = !_obscure2),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Confirme contraseña';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _resetPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5A3FFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: _loading
                                  ? const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Actualizar contraseña',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
