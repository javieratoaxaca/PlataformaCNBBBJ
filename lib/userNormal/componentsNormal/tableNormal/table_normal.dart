import 'package:flutter/cupertino.dart';
import 'package:plataformacnbbbjo/userNormal/componentsNormal/tableNormal/paginated_table_normal.dart';
import 'package:plataformacnbbbjo/userNormal/componentsNormal/tableNormal/table_data_example_normal.dart';
import 'package:plataformacnbbbjo/userNormal/serviceuser/paginated_table_service.dart';
import 'package:plataformacnbbbjo/util/responsive.dart';

/// `TableNormal` es un widget de estado (`StatefulWidget`) que muestra una tabla
/// paginada con los cursos completados por un usuario.
///
/// La tabla obtiene los datos desde un servicio externo y maneja diferentes estados,
/// como la carga de datos, la visualización de los cursos completados y un mensaje
/// en caso de que no haya cursos registrados.

class TableNormal extends StatefulWidget {
   /// Constructor de la clase `TableNormal`
  const TableNormal({super.key});

  @override
  State<TableNormal> createState() => _TableNormalState();
}

class _TableNormalState extends State<TableNormal> {
  /// Variable para controlar el estado de carga de los datos.
  bool isLoading = true;

  /// Lista de filas que contendrán los datos de los cursos completados.
  List<Map<String, dynamic>> rows = [];

  /// Definición de las columnas de la tabla.
  final List<String> columns = ['NOMBRE DEL CURSO', 'TRIMESTRE',
    'FECHA DE FINALIZACIÓN'];

  @override
  void initState() {
    super.initState();
    _loadData(); // Carga los datos cuando el widget es inicializado.
  }

  /// Método asíncrono que obtiene los datos de los cursos completados
  /// desde el servicio `PaginatedTableService` y actualiza el estado.
  Future<void> _loadData() async {
    final paginatedTableService = PaginatedTableService();
    List<Map<String, dynamic>> fetchedRows = await paginatedTableService.fetchCompletedCourses();

    setState(() {
      rows = fetchedRows;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Aquí podrás ver los cursos que has completado',
            style: TextStyle(
                fontSize: responsiveFontSize(context, 20),
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10.0),
          if (isLoading)
            const CupertinoActivityIndicator(radius: 15) // Indicador de carga
          else if (rows.isEmpty) ...[
            Text(
              'Aún no has completado un curso',
              style: TextStyle(
                  fontSize: responsiveFontSize(context, 18),
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10.0),
            SizedBox(
              width: double.infinity,
              child: PaginatedTableNormal(
                columns: TableDataExampleNormal.getColumns(),
                rows: TableDataExampleNormal.getRows(),
                isLoading: false,
              ),
            )
          ] else ...[
            Text(
              'Mis cursos completados',
              style: TextStyle(
                  fontSize: responsiveFontSize(context, 20),
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10.0),
            SizedBox(
              width: double.infinity,
              child: PaginatedTableNormal(
                columns: columns,
                rows: rows,
                isLoading: false,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
