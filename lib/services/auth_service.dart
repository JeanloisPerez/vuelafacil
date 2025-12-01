import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  Future<String?> registrarUsuario({
    required String email,
    required String password,
    required String nombre,
    required String apellido,
    required String telefono,
    required String documento,
    required String tipoDocumento,
  }) async {
    try {
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = authResponse.user;

      if (user == null) {
        return 'No se pudo registrar el usuario.';
      }

      await supabase.from('users').insert({
        'usuario_id': user.id,
        'nombre': nombre,
        'apellido': apellido,
        'email': email,
        'password_hash': 'N/A',
        'telefono': telefono,
        'documento_identidad': documento,
        'tipo_documento': tipoDocumento,
      });

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      await supabase.auth.signInWithPassword(email: email, password: password);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  dynamic obtenerUsuarioActual() {
    return supabase.auth.currentUser;
  }
}
