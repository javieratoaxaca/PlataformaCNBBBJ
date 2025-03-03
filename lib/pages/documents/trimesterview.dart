import 'package:flutter/material.dart';
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
                                  icon: const Icon(Icons.download, color: greenColorLight, size: 30),
                                  onPressed:()async{
                                  await _firebaseService.descargarZIP(context, trimester);
                                    },
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
}
