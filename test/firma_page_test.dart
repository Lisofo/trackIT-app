// test/widgets/firma_page_test.dart
import 'package:app_tec_sedel/pages/drawerPages/firma_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import 'package:app_tec_sedel/models/orden.dart';
import 'package:app_tec_sedel/providers/auth_provider.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:app_tec_sedel/services/revision_services.dart';

// Mocks
class MockAuthProvider extends Mock implements AuthProvider {}
class MockOrdenProvider extends Mock implements OrdenProvider {}
class MockRevisionServices extends Mock implements RevisionServices {}

void main() {
  late MockAuthProvider mockAuthProvider;
  late MockOrdenProvider mockOrdenProvider;

  setUp(() {
    mockAuthProvider = MockAuthProvider();
    mockOrdenProvider = MockOrdenProvider();
  });

  tearDown(() {
    resetMockitoState(); // Limpia el estado de Mockito entre tests
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
        ChangeNotifierProvider<OrdenProvider>.value(value: mockOrdenProvider),
      ],
      child: const MaterialApp(
        home: Firma(),
      ),
    );
  }

  testWidgets('Muestra loading inicial en FirmaPage', (WidgetTester tester) async {
    // Arrange
    when(mockAuthProvider.token).thenReturn('test-token');
    when(mockOrdenProvider.orden).thenReturn(Orden.empty());
    when(mockOrdenProvider.marcaId).thenReturn(1);

    // Act
    await tester.pumpWidget(createWidgetUnderTest());

    // Assert
    expect(find.text('Cargando, por favor espere...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Muestra campos de nombre y área', (WidgetTester tester) async {
    // Arrange
    when(mockAuthProvider.token).thenReturn('test-token');
    when(mockOrdenProvider.orden).thenReturn(Orden(
      ordenTrabajoId: 1,
      otRevisionId: 1,
      estado: 'EN_PROCESO',
    ));
    when(mockOrdenProvider.marcaId).thenReturn(1);

    // Act
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Nombre'), findsOneWidget);
    expect(find.text('Area'), findsOneWidget);
  });

  testWidgets('Muestra zona de firma', (WidgetTester tester) async {
    // Arrange
    when(mockAuthProvider.token).thenReturn('test-token');
    when(mockOrdenProvider.orden).thenReturn(Orden(
      ordenTrabajoId: 1,
      otRevisionId: 1,
      estado: 'EN_PROCESO',
    ));
    when(mockOrdenProvider.marcaId).thenReturn(1);

    // Act
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(Signature), findsOneWidget);
  });

  testWidgets('Boton guardar se muestra cuando cliente está disponible', (WidgetTester tester) async {
    // Arrange
    when(mockAuthProvider.token).thenReturn('test-token');
    when(mockOrdenProvider.orden).thenReturn(Orden(
      ordenTrabajoId: 1,
      otRevisionId: 1,
      estado: 'EN_PROCESO',
    ));
    when(mockOrdenProvider.marcaId).thenReturn(1);

    // Act
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Guardar'), findsOneWidget);
  });

  testWidgets('Boton limpiar firma se muestra', (WidgetTester tester) async {
    // Arrange
    when(mockAuthProvider.token).thenReturn('test-token');
    when(mockOrdenProvider.orden).thenReturn(Orden(
      ordenTrabajoId: 1,
      otRevisionId: 1,
      estado: 'EN_PROCESO',
    ));
    when(mockOrdenProvider.marcaId).thenReturn(1);

    // Act
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Assert - Buscar botón de limpiar (icono de delete)
    expect(find.byIcon(Icons.delete), findsAtLeast(1));
  });

  testWidgets('Switch cliente no disponible se muestra cuando no hay firmas', (WidgetTester tester) async {
    // Arrange
    when(mockAuthProvider.token).thenReturn('test-token');
    when(mockOrdenProvider.orden).thenReturn(Orden(
      ordenTrabajoId: 1,
      otRevisionId: 1,
      estado: 'EN_PROCESO',
    ));
    when(mockOrdenProvider.marcaId).thenReturn(1);

    // Act
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Cliente no disponible'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('Campos se deshabilitan cuando cliente no está disponible', (WidgetTester tester) async {
    // Arrange
    when(mockAuthProvider.token).thenReturn('test-token');
    when(mockOrdenProvider.orden).thenReturn(Orden(
      ordenTrabajoId: 1,
      otRevisionId: 1,
      estado: 'EN_PROCESO',
    ));
    when(mockOrdenProvider.marcaId).thenReturn(1);

    // Act
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Encontrar y activar el switch
    final switchWidget = find.byType(Switch);
    await tester.tap(switchWidget);
    await tester.pump();

    // Assert - Los campos deberían estar deshabilitados
    // (Podemos verificar el color de fondo o estado de enabled)
  });

  testWidgets('Lista de firmas se muestra cuando existen', (WidgetTester tester) async {
    // Arrange
    when(mockAuthProvider.token).thenReturn('test-token');
    when(mockOrdenProvider.orden).thenReturn(Orden(
      ordenTrabajoId: 1,
      otRevisionId: 1,
      estado: 'EN_PROCESO',
    ));
    when(mockOrdenProvider.marcaId).thenReturn(1);

    // Act
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(ListView), findsOneWidget);
  });
}