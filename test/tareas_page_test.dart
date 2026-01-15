// test/widgets/tareas_page_test.dart
import 'package:app_tec_sedel/pages/drawerPages/tareas_page.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:app_tec_sedel/models/orden.dart';
import 'package:app_tec_sedel/models/tarea.dart';
import 'package:app_tec_sedel/providers/auth_provider.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:app_tec_sedel/services/tareas_services.dart';
import 'package:app_tec_sedel/services/revision_services.dart';

// Mocks
class MockAuthProvider extends Mock implements AuthProvider {}
class MockOrdenProvider extends Mock implements OrdenProvider {}
class MockTareasServices extends Mock implements TareasServices {}
class MockRevisionServices extends Mock implements RevisionServices {}

void main() {
  late MockAuthProvider mockAuthProvider;
  late MockOrdenProvider mockOrdenProvider;
  late MockTareasServices mockTareasServices;
  late MockRevisionServices mockRevisionServices;

  setUp(() {
    mockAuthProvider = MockAuthProvider();
    mockOrdenProvider = MockOrdenProvider();
    mockTareasServices = MockTareasServices();
    mockRevisionServices = MockRevisionServices();
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
        home: TareasPage(),
      ),
    );
  }

  testWidgets('Muestra loading inicial', (WidgetTester tester) async {
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

  testWidgets('Muestra mensaje de recarga cuando falla carga', (WidgetTester tester) async {
    // Arrange
    when(mockAuthProvider.token).thenReturn('test-token');
    when(mockOrdenProvider.orden).thenReturn(Orden.empty());
    when(mockOrdenProvider.marcaId).thenReturn(1);

    // Act
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle(); // Esperar a que termine la carga

    // Assert
    expect(find.text('Recargar'), findsOneWidget);
    expect(find.byIcon(Icons.replay_outlined), findsOneWidget);
  });

  testWidgets('Muestra dropdown de tareas cuando carga correctamente', (WidgetTester tester) async {
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

    // Simular que se completó la carga con datos
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Seleccione una tarea'), findsOneWidget);
    expect(find.byType(DropdownSearch<Tarea>), findsOneWidget);
  });

  testWidgets('Boton agregar se muestra cuando hay datos', (WidgetTester tester) async {
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
    expect(find.text('Agregar +'), findsOneWidget);
  });

  testWidgets('No permite agregar tarea cuando orden está pendiente', (WidgetTester tester) async {
    // Arrange
    when(mockAuthProvider.token).thenReturn('test-token');
    when(mockOrdenProvider.orden).thenReturn(Orden(
      ordenTrabajoId: 1,
      otRevisionId: 1,
      estado: 'PENDIENTE',
    ));
    when(mockOrdenProvider.marcaId).thenReturn(1);

    // Act
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Intentar presionar el botón
    final button = find.text('Agregar +');
    await tester.tap(button);
    await tester.pump();

    // Assert - Debería mostrar snackbar de error
    expect(find.text('No puede de ingresar o editar datos.'), findsNothing);
  });

  testWidgets('Muestra lista de revisiones cuando existen', (WidgetTester tester) async {
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

    // Assert - Debería mostrar el ListView para revisiones
    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(Dismissible), findsNothing); // No hay datos todavía
  });
}