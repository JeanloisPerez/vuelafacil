import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileServiceSupabase {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> getProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final response = await supabase
        .from('profile')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    return response;
  }

  Future<void> saveProfile({
    required String name,
    required String phone,
    required String email,
    required String? imageUrl,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('profile').upsert({
      'user_id': user.id,
      'name': name,
      'phone': phone,
      'email': email,
      'image_url': imageUrl,
    });
  }

  Future<String?> uploadProfileImage(String filePath) async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final bucket = 'profile_images';
    final fileName = 'profile_${user.id}.jpg';
    final file = File(filePath);

    if (!await file.exists()) {
      print("⚠ El archivo no existe: $filePath");
      return null;
    }

    try {
      await supabase.storage
          .from(bucket)
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));

      final publicUrl = supabase.storage.from(bucket).getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      print('Error uploading to storage (bucket=$bucket): $e');
      return null;
    }
  }

  Future<bool> deleteProfileImage() async {
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    final bucket = 'profile_images';
    final fileName = 'profile_${user.id}.jpg';

    try {
      await supabase.storage.from(bucket).remove([fileName]);
      return true;
    } catch (e) {
      print('Error deleting from storage (bucket=$bucket): $e');
      return false;
    }
  }
}
