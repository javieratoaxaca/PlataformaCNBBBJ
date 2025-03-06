import 'package:flutter/material.dart';
import 'package:plataformacnbbbjo/dataConst/constand.dart';
import 'package:plataformacnbbbjo/util/responsive.dart';

/// `PaginatedTableNormal` es un widget que muestra una tabla paginada en Flutter.
///
/// Recibe una lista de columnas, una lista de filas con datos y un indicador de carga.
/// Si `isLoading` es `true`, muestra un indicador de progreso.
/// De lo contrario, renderiza una `PaginatedDataTable` con los datos proporcionados.

class PaginatedTableNormal extends StatelessWidget {
  /// Lista de nombres de columnas para la tabla.
  final List<String> columns;

  /// Lista de filas que contienen los datos de la tabla.
  final List<Map<String, dynamic>> rows;

  /// Indica si los datos están cargando.
  final bool isLoading;

  /// Constructor de `PaginatedTableNormal`.
  const PaginatedTableNormal(
      {super.key,
      required this.columns,
      required this.rows,
      required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: PaginatedDataTable(
              headingRowColor: WidgetStateProperty.all(greenColorLight),
              columns: columns
                  .map((col) => DataColumn(
                          label: Text(
                        col,
                        style: TextStyle(
                            fontSize: responsiveFontSize(context, 18),
                            fontWeight: FontWeight.bold, color: Colors.white),
                      )))
                  .toList(),
              source: _TableData(rows),
              rowsPerPage: 5, // Número de filas por página
            ),
          );
  }
}

/// `_TableData` es una fuente de datos para `PaginatedDataTable`.
///
/// Se encarga de construir las filas de la tabla a partir de una lista de mapas.
class _TableData extends DataTableSource {
  /// Lista de filas con los datos de la tabla.
  final List<Map<String, dynamic>> rows;

  _TableData(this.rows);

  @override
  DataRow getRow(int index) {
    if (index >= rows.length) return const DataRow(cells: []);
    final row = rows[index];

    return DataRow(
      cells: row.values
          .map((value) => DataCell(Text(
                value.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              )))
          .toList(),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => rows.length;

  @override
  int get selectedRowCount => 0;
}
