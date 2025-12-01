import 'package:flutter/material.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatelessWidget {
  static const String routeName = '/welcome';

  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final email = args != null && args.containsKey('email')
        ? args['email'] as String
        : 'Usuario';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              child: SizedBox(
                height: 260,
                width: double.infinity,
                child: Image.asset(
                  "lib/core/assets/plane.png",
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 25),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "¡Bienvenido!",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    email,
                    style: const TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Has iniciado sesión correctamente en Vuela Fácil.",
                    style: TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, HomeScreen.routeName);
                },
                child: Container(
                  height: 55,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5A3FFF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Center(
                    child: Text(
                      "Buscar vuelos",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            const Spacer(),

            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text(
                  "Cerrar sesión",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
