import 'package:flutter/material.dart';
import 'package:plataformacnbbbjo/pages/documents/coursesview.dart';
import 'package:plataformacnbbbjo/pages/documents/firebaseservice.dart';

// [DependenciesView] muestra una lista de dependencias disponibles
// para un trimestre específico.
// Al seleccionar una dependencia, el usuario es redirigido a la vista
// [CoursesView], donde puede consultar los cursos relacionados a dicha dependencia.
class DependenciesView extends StatefulWidget {
  final String trimester;  /// Trimestre seleccionado para filtrar las dependencias.

  // Constructor de [DependenciesView].
  const DependenciesView({super.key, required this.trimester});

  @override
  State<DependenciesView> createState() => _DependenciesViewState();
}

class _DependenciesViewState extends State<DependenciesView> {
   /// Instancia del servicio de Firebase que gestiona la obtención de datos.
  final FirebaseService _firebaseService = FirebaseService();
  /// Lista de dependencias obtenidas desde Firebase. 
  List<Map<String, dynamic>> dependencies = [];
  /// Indica si los datos aún se están cargando.
  bool isLoading = true;

  /// Método que se llama automáticamente al iniciar el widget.
  /// Se encarga de iniciar la carga de dependencias.
  @override
  void initState() {
    super.initState();
    _loadDependencies();
  }

  /// Carga las dependencias desde Firebase según el trimestre actual.
  /// Al finalizar la carga, actualiza el estado para mostrar los datos.
  Future<void> _loadDependencies() async {
    dependencies = await _firebaseService.getDependencies(widget.trimester);
    setState(() => isLoading = false);
  }

  /// Construye la interfaz de usuario para mostrar las dependencias.
  /// Muestra un indicador de carga mientras se obtienen los datos, un mensaje
  /// si no hay dependencias, o una cuadrícula de tarjetas en caso contrario.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dependencias')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : dependencies.isEmpty
              ? const Center(child: Text('No hay dependencias disponibles.'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = 1; 
                      double aspectRatio = 1.5; 

                      if (constraints.maxWidth > 1200) {
                        crossAxisCount = 2; 
                        aspectRatio = 2;
                      } else if (constraints.maxWidth > 800) {
                        crossAxisCount = 2; 
                        aspectRatio = 1.8;
                      }

                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16.0,
                          mainAxisSpacing: 16.0,
                          childAspectRatio: aspectRatio,
                        ),
                        itemCount: dependencies.length,
                        itemBuilder: (context, index) {
                          final dependencia = dependencies[index];

                          return Material(
                            borderRadius: BorderRadius.circular(12),
                            elevation: 5,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CoursesView(
                                      trimester: widget.trimester,
                                      dependecyId: dependencia['IdDependencia'],
                                      dependencyName: dependencia['NombreDependencia'],
                                    ),
                                  ),
                                );
                              },
                              child: Column(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                      child: Image.asset(
                                        'assets/images/logo.jpg',
                                        width: double.infinity,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        dependencia['NombreDependencia'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
