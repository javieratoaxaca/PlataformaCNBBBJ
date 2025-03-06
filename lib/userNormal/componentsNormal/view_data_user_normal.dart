import 'package:flutter/cupertino.dart';
import 'package:plataformacnbbbjo/components/formPatrts/body_widgets.dart';
import 'package:plataformacnbbbjo/userNormal/componentsNormal/tableNormal/table_normal.dart';

  //Componente que muestra una tabla con información de ejemplo o información de los cursos completados
class ViewDataUserNormal extends StatefulWidget {
  const ViewDataUserNormal({super.key});

  @override
  State<ViewDataUserNormal> createState() => _ViewDataUserNormalState();
}

class _ViewDataUserNormalState extends State<ViewDataUserNormal> {
  @override
  Widget build(BuildContext context) {
    return const BodyWidgets(body: TableNormal());
  }
}
