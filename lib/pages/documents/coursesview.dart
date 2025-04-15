import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plataformacnbbbjo/pages/documents/filesview.dart';


// [CoursesView] muestra los cursos disponibles de una dependencia
/// específica y un trimestre determinado.
// Esta clase consulta los datos desde Firestore en tiempo real y presenta
// cada curso como una tarjeta en una cuadrícula adaptable.
// Al seleccionar un curso, redirige a la vista `FilesListPage` donde
// se muestran los archivos relacionados al curso.
class CoursesView extends StatelessWidget {
  final String trimester; /// Trimestre actual seleccionado.
  final String dependecyId; /// ID de la dependencia seleccionada.
  final String dependencyName;  /// Nombre de la dependencia seleccionada.

  // Constructor de [CoursesView].
  // Requiere [trimester], [dependecyId] y [dependencyName] para filtrar
  // los cursos correspondientes.
  const CoursesView({
    super.key,
    required this.trimester,
    required this.dependecyId,
    required this.dependencyName,
  });

  @override
  Widget build(BuildContext context) {
    

    return Scaffold(
      appBar: AppBar(title: Text('Cursos de $dependencyName')),
      /// Escucha en tiempo real los cursos filtrados por trimestre y dependencia.
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Cursos')
            .where('Trimestre', isEqualTo: trimester)
            .where('IdDependencia', isEqualTo: dependecyId)
            .snapshots(),
        /// Muestra diferentes vistas dependiendo del estado de conexión y datos.
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay cursos disponibles."));
          }

          var courses = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            /// Utiliza un `LayoutBuilder` para hacer la cuadrícula adaptable a diferentes tamaños de pantalla.
            child: LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = 1; // Por defecto 1 columna
                double aspectRatio = 1.5; // Relación de aspecto de las tarjetas

                if (constraints.maxWidth > 1200) {
                  crossAxisCount = 2; // Escritorio grande
                  aspectRatio = 2;
                } else if (constraints.maxWidth > 800) {
                  crossAxisCount = 2; // Tabletas y pantallas medianas
                  aspectRatio = 1.8;
                }

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: aspectRatio,
                  ),
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    var course = courses[index];

                    /// Obtiene los campos relevantes del documento.
                    String? courseName = course['NombreCurso'];
                    String? dependency = course['Dependencia'];
                    String? trimester = course['Trimestre'];
                    /// Verifica que los campos existan antes de mostrar la tarjeta.
                    if (courseName == null || dependency == null || trimester == null) {
                      return const Center(
                        child: Text("Error: Datos del curso incompletos"),
                      );
                    }
                    /// Tarjeta visual que representa el curso.
                    return Material(
                      borderRadius: BorderRadius.circular(12),
                      elevation: 5,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        /// Navega a la vista de archivos al tocar la tarjeta.
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FilesListPage(
                                courseName: courseName,
                                dependency: dependency,
                                trimester: trimester,
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
                                  courseName,
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
          );
        },
      ),
    );
  }
}
