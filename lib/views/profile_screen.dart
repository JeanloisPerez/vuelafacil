import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_navbar.dart';
import 'saved_flights_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  static const String routeName = '/profile';

  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();
  int currentIndex = 2;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _nameController.text = prefs.getString('profile_name') ?? '';
      _emailController.text = prefs.getString('profile_email') ?? '';
      _phoneController.text = prefs.getString('profile_phone') ?? '';
      _imagePath = prefs.getString('profile_image');
      _isLoading = false;
    });
  }

  Future<void> _saveProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', _nameController.text);
    await prefs.setString('profile_email', _emailController.text);
    await prefs.setString('profile_phone', _phoneController.text);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Perfil actualizado correctamente'),
        backgroundColor: Color(0xFF5A3FFF),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image', image.path);

        setState(() {
          _imagePath = image.path;
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imagen de perfil actualizada'),
            backgroundColor: Color(0xFF5A3FFF),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Seleccionar imagen desde',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF5A3FFF)),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Color(0xFF5A3FFF),
              ),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_imagePath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar foto'),
                onTap: () async {
                  Navigator.pop(context);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('profile_image');
                  setState(() {
                    _imagePath = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      Navigator.pushReplacementNamed(context, LoginScreen.routeName);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFF5A3FFF)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF5A3FFF),
                              width: 3,
                            ),
                          ),
                          child: ClipOval(
                            child: _imagePath != null
                                ? (kIsWeb
                                      ? Image.network(
                                          _imagePath!,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          File(_imagePath!),
                                          fit: BoxFit.cover,
                                        ))
                                : _buildDefaultAvatar(),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF5A3FFF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _nameController.text.isEmpty
                        ? 'Nombre de usuario'
                        : _nameController.text,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _emailController.text,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildInfoCard(
                    icon: Icons.person_outline,
                    label: 'Nombre completo',
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.email_outlined,
                    label: 'Correo electrónico',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: false,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.phone_outlined,
                    label: 'Teléfono',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5A3FFF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _saveProfileData,
                      child: const Text(
                        'Guardar cambios',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: CustomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() => currentIndex = index);
          if (index == 0) {
            Navigator.of(context).pushReplacementNamed('/home');
            return;
          } else if (index == 1) {
            Navigator.pushNamed(context, SavedFlightsScreen.routeName);
          } else if (index == 2) {
            Navigator.pushNamed(context, ProfileScreen.routeName);
          }
        },
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: const Color(0xFF5A3FFF).withOpacity(0.1),
      child: const Center(
        child: Icon(Icons.person, size: 60, color: Color(0xFF5A3FFF)),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        decoration: InputDecoration(
          icon: Icon(icon, color: const Color(0xFF5A3FFF)),
          labelText: label,
          border: InputBorder.none,
          labelStyle: TextStyle(color: Colors.grey[600]),
        ),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: enabled ? Colors.black : Colors.grey[600],
        ),
      ),
    );
  }
}
