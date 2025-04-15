import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:plataformacnbbbjo/auth/auth_service.dart';
import 'package:plataformacnbbbjo/userNormal/serviceuser/firebase_service.dart';
import 'package:plataformacnbbbjo/util/responsive.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'cursos_normal.dart';

/// Página que permite a un usuario ver y seleccionar los cursos que aún tiene pendientes de completar.
/// Esta pantalla carga dinámicamente los cursos pendientes desde Firebase
/// según el ID de usuario autenticado y un código de cupo proporcionado.
/// Cada curso se muestra como una tarjeta interactiva.
class DynamicCourseSelectionPage extends StatefulWidget {
  /// Código de cupo proporcionado al usuario.
  final String cupo;
  /// Constructor de la página de selección dinámica de cursos.
  const DynamicCourseSelectionPage({super.key, required this.cupo});

  @override
  // ignore: library_private_types_in_public_api
  _DynamicCourseSelectionPageState createState() => _DynamicCourseSelectionPageState();
}

class _DynamicCourseSelectionPageState extends State<DynamicCourseSelectionPage> {
  /// Instancia del servicio de Firebase para obtener los cursos.
  final FirebaseService _firebaseService = FirebaseService();
  /// Lista de cursos pendientes que serán mostrados en la interfaz. 
  List<Map<String, dynamic>> cursosPendientes = [];
  /// Indica si se están cargando los datos desde Firebase.
  bool isLoading = true;
  /// Inicializa el estado de la vista y carga los cursos pendientes.
  @override
  void initState() {
    super.initState();
    cargarCursosPendientes();
  }

    /// Obtiene los cursos pendientes del usuario autenticado desde Firebase.
    /// Utiliza el `cupo` proporcionado para filtrar los cursos.
    /// También maneja errores utilizando Sentry para su reporte.
    Future<void> cargarCursosPendientes() async {
    try {
      final userId = AuthService().getCurrentUserUid();
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }
      
      final cursos = await _firebaseService.obtenerCursosPendientes(userId, widget.cupo);

      setState(() {
        cursosPendientes = cursos;
        isLoading = false;
        
      });

      if (cursos.isEmpty) {
        
      }
    } on FirebaseException catch (exception, stackTrace) {
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
        withScope: (scope) {
          scope.setTag('firebase_error_code', exception.code);
        },
      );
      setState(() {
        isLoading = false;
        cursosPendientes = []; 
      });
    } catch (exception, stackTrace) {
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
        withScope: (scope) {
          scope.setTag('error_type', 'unknown_exception');
        },
      );
      setState(() {
        isLoading = false;
        cursosPendientes = []; 
      });
    }
  }

  /// Construye la interfaz principal de la página.
  /// Muestra un indicador de carga, un mensaje si no hay cursos
  /// o un grid con tarjetas interactivas de los cursos pendientes.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : cursosPendientes.isEmpty
              ? const Center(child: Text('No hay cursos pendientes.'))
              : Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // ignore: unused_local_variable
                      int crossAxisCount = 2;
                      // ignore: unused_local_variable
                      double childAspectRatio = 1.2;

                      if (constraints.maxWidth > 600) {
                        crossAxisCount = 3; 
                        childAspectRatio = 1.4;
                      }
                      if (constraints.maxWidth > 900) {
                        crossAxisCount = 4; 
                        childAspectRatio = 1.5;
                      }

                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 2, 
                          crossAxisSpacing: 16.0,
                          mainAxisSpacing: 16.0,
                          childAspectRatio: MediaQuery.of(context).size.width > 800 ? 1.5 : 1,
                        ),
                        itemCount: cursosPendientes.length,
                        itemBuilder: (context, index) {
                          final curso = cursosPendientes[index];
                          return CourseCard(
                            courseName: curso['NombreCurso'],
                            trimester: curso['Trimestre'],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CursosNormal(
                                    course: curso['NombreCurso'],
                                    subCourse: null,
                                    trimester: curso['Trimestre'],
                                    dependecy: curso['Dependencia'],
                                    idCurso: curso['IdCurso'],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

/// Componente visual que representa una tarjeta de curso pendiente.
/// Muestra el nombre del curso, el trimestre, una fecha de inicio opcional y una imagen representativa. Es completamente interactivo.
class CourseCard extends StatelessWidget {
  /// Nombre del curso mostrado en la tarjeta.
  final String courseName;
  /// Trimestre en que se imparte el curso.
  final String trimester;
  /// Fecha de inicio del curso (opcional).
  final String? startDate;
  /// Acción que se ejecuta cuando el usuario toca la tarjeta.
  final VoidCallback onTap;

   /// Constructor de la tarjeta de curso.
  const CourseCard({
    super.key,
    required this.courseName,
    required this.trimester,
    this.startDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logoActualizado.jpg',
                  height: MediaQuery.of(context).size.width < 600 ? 70 : 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 20),
                Text(
                  courseName,
                  style: TextStyle(
                    fontSize: responsiveFontSize(context, 15),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Trimestre: $trimester',
                  style: TextStyle(fontSize: responsiveFontSize(context, 14)),
                  textAlign: TextAlign.center,
                ),
                if (startDate != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Inicio: $startDate',
                    style: TextStyle(fontSize: responsiveFontSize(context, 14)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
