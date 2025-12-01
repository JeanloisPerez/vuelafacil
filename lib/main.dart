import 'package:flutter/material.dart';
import 'views/login_screen.dart';
import 'views/welcome_screen.dart';
import 'views/home_screen.dart';
import 'views/FlightListScreen.dart';
import 'views/saved_flights_screen.dart';
import 'views/profile_screen.dart';
import 'views/forgot_password_screen.dart';
import 'views/reset_password_screen.dart';
import 'views/register_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://fblavelhbqvlqjgzdvdj.supabase.co',
    anonKey: 'sb_publishable_rPxe26D7c_wmzm1LPozSQg_497I2itS',
  );

  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final event = data.event;
    print('Auth Event: $event');

    if (event == AuthChangeEvent.passwordRecovery) {
      print('Password Recovery detectado, navegando a ResetPasswordScreen');

      Future.delayed(const Duration(milliseconds: 500), () {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          ResetPasswordScreen.routeName,
          (route) => false,
        );
      });
    }
  });

  runApp(const vuelaFacil());
}

class vuelaFacil extends StatelessWidget {
  const vuelaFacil({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Vuela Facil',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: LoginScreen.routeName,
      routes: {
        LoginScreen.routeName: (_) => const LoginScreen(),
        WelcomeScreen.routeName: (_) => const WelcomeScreen(),
        HomeScreen.routeName: (_) => const HomeScreen(),
        FlightListScreen.routeName: (_) => const FlightListScreen(),
        SavedFlightsScreen.routeName: (_) => const SavedFlightsScreen(),
        ProfileScreen.routeName: (_) => const ProfileScreen(),
        ForgotPasswordScreen.routeName: (_) => const ForgotPasswordScreen(),
        ResetPasswordScreen.routeName: (_) => const ResetPasswordScreen(),
        RegisterScreen.routeName: (_) => const RegisterScreen(),
      },

      onGenerateRoute: (settings) {
        print('🔗 onGenerateRoute: ${settings.name}');

        if (settings.name == ResetPasswordScreen.routeName) {
          return MaterialPageRoute(builder: (_) => const ResetPasswordScreen());
        }

        return MaterialPageRoute(builder: (_) => const LoginScreen());
      },
    );
  }
}
