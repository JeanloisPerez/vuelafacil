import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login22/main.dart';

void main() {
  testWidgets('Verifica que la pantalla de login se cargue correctamente', (
    WidgetTester tester,
  ) async {
    // Construye la app
    await tester.pumpWidget(vuelaFacil());

    // Verifica que el texto de bienvenida aparezca
    expect(find.text('Bienvenido a Login22'), findsOneWidget);

    // Verifica que los campos de correo y contraseña existan
    expect(find.byType(TextField), findsNWidgets(2));

    // Verifica que el botón de inicio de sesión exista
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
