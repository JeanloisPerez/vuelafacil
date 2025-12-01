import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordScreen extends StatefulWidget {
  static const String routeName = '/forgotPassword';

  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final supabase = Supabase.instance.client;

      await supabase.auth.resetPasswordForEmail(
        _emailCtrl.text.trim(),
        redirectTo: 'io.supabase.flutter://reset-callback/',
      );

      setState(() => _emailSent = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se envió un enlace de recuperación a tu correo'),
          backgroundColor: Colors.green,
        ),
      );

      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
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
                  child: const Icon(
                    Icons.lock_reset,
                    size: 60,
                    color: Color(0xFF5A3FFF),
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  "Recuperar contraseña",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  "Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 16),
                ),

                const SizedBox(height: 30),

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
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          enabled: !_emailSent,
                          decoration: InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Ingrese su correo';
                            }
                            final emailReg = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                            if (!emailReg.hasMatch(v.trim())) {
                              return 'Correo inválido';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _loading || _emailSent
                                ? null
                                : _sendResetEmail,
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
                                : Text(
                                    _emailSent
                                        ? '✓ Enlace enviado'
                                        : 'Enviar enlace de recuperación',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        if (_emailSent)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Revisa tu correo en los próximos minutos',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 14,
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

                const SizedBox(height: 20),

                if (!_emailSent)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      '¿Recordaste tu contraseña? Volver a iniciar sesión',
                      style: TextStyle(color: Color(0xFF5A3FFF)),
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
