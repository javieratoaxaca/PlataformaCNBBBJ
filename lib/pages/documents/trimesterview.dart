import 'package:flutter/material.dart';
import 'package:plataformacnbbbjo/components/formPatrts/actions_form_check.dart';
import 'package:plataformacnbbbjo/components/formPatrts/my_button.dart';
import 'package:plataformacnbbbjo/dataConst/constand.dart';
import 'package:plataformacnbbbjo/pages/documents/dependenciesview.dart';
import 'package:plataformacnbbbjo/pages/documents/firebaseservice.dart';

class TrimesterView extends StatefulWidget {
  const TrimesterView({super.key});

  @override
  State<TrimesterView> createState() => _TrimesterViewState();
}

class _TrimesterViewState extends State<TrimesterView> {
  final FirebaseService _firebaseService = FirebaseService();
  List<String> trimesters = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrimesters();
  }

  Future<void> _loadTrimesters() async {
    trimesters = await _firebaseService.getTrimesters();
    setState(() => isLoading = false);
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : trimesters.isEmpty
              ? const Center(child: Text('No hay trimestres disponibles.'))
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
                        itemCount: trimesters.length,
                        itemBuilder: (context, index) {
                          String trimester = trimesters[index];
                          return Stack(
                            children: [
                              Material(
                                borderRadius: BorderRadius.circular(12),
                                elevation: 5,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DependenciesView(
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
                                            fit: BoxFit.cover,
                                            'assets/images/logoActualizado.jpg',
                                            width: double.infinity,
                                            height: 100,
                                            
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            'Trimestre $trimester',
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
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: IconButton(
                                  
                                  onPressed:() => _descargarYEliminarZIP(
                                    context,
                                    trimester
                                  ),
                                  icon: const Icon(Icons.download, color: greenColorLight, size: 30),
                                  tooltip: "Descargar archivos de este trimestre",
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }
  void _descargarYEliminarZIP(BuildContext context, String trimestre) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text("Confirmar"),
      content: Text("Al aceptar, se descargarán y eliminarán los archivos del trimestre $trimestre. \n ¿Continuar?"),
      actions:[
        ActionsFormCheck(
          isEditing: true,
          onCancel: (){
            if (dialogContext.mounted) {
             Navigator.of(dialogContext).pop();
          }
          },
          onUpdate: ()async{
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
            }
            if (!context.mounted) return;
            await _firebaseService.descargarZIP(context, trimestre);
             final archivosExisten = await _firebaseService.verificarArchivosTrimestre(trimestre);
             if (!context.mounted) return;
            if (archivosExisten) {
              await _firebaseService.eliminarArchivosTrimestre(context, trimestre);
            } else {
              if (!context.mounted) return;
              //mostrarDialogo(context, "Sin archivos", "No hay archivos en el trimestre $trimestre para eliminar.");
            }
          },
        )
      ]
    ),
  );
}
void mostrarDialogo(BuildContext context, String titulo, String mensaje) {
  if (!context.mounted) return;

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
           MyButton(text: "Aceptar", icon: Icon(Icons.check_circle_outline), buttonColor: greenColorLight, onPressed: () => Navigator.pop(context),),
        ],
      );
    },
  );
}

}
