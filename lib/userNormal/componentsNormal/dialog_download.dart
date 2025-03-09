import 'package:flutter/material.dart';
import 'package:plataformacnbbbjo/components/formPatrts/actions_form_check.dart';
import 'package:plataformacnbbbjo/components/formPatrts/custom_snackbar.dart';
import 'package:plataformacnbbbjo/dataConst/constand.dart';
import 'package:plataformacnbbbjo/userNormal/serviceuser/service_apk.dart';
import 'package:plataformacnbbbjo/util/responsive.dart';

class DialogDownload extends StatefulWidget {
  const DialogDownload({super.key});

  @override
  State<DialogDownload> createState() => _DialogDownloadState();
}

class _DialogDownloadState extends State<DialogDownload> {


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text('¿Esta seguro de descargar la Aplicación?', style: TextStyle(
        fontSize: responsiveFontSize(context, 16),
        fontWeight: FontWeight.bold
      ),),
      content: Column(
        children: [
          Text('Debe tener un celular con version de Andriod 6.0 o superior', style: TextStyle(
        fontSize: responsiveFontSize(context, 14)
      ),),
      Text('y un tamaño minimo de 2 pulgadas de ancho.', style: TextStyle(
        fontSize: responsiveFontSize(context, 14)
      ),)
        ],
      ),
      actions: [
        Center(
          child: ActionsFormCheck(isEditing: true,
          onUpdate: () async {
            await downloadApkFile(context);
            if(context.mounted) {
              showCustomSnackBar(context, 'Aplicación descargada correctamente', greenColorLight);
              Navigator.pop(context);
            }
          },
          onCancel: () => Navigator.pop(context),
          ),
        )
      ],
    );
  }
}