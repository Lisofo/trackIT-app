import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Próximamente'),
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono de construcción
              Icon(
                Icons.construction,
                size: 80,
                color: Colors.orange[700],
              ),
              
              const SizedBox(height: 32),
              
              // Título
              Text(
                '¡En Construcción!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Descripción
              Text(
                'Estamos trabajando duro para traerte esta funcionalidad muy pronto.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                '¡Vuelve pronto!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Botón para volver
              ElevatedButton.icon(
                onPressed: () {
                  // Vuelve a la pantalla anterior
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    // Si no hay pantalla anterior, va al inicio
                    context.go('/');
                  }
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver atrás'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Botón alternativo para ir al inicio
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Ir al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}