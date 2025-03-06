import 'package:flutter/material.dart';
import 'package:plataformacnbbbjo/components/formPatrts/body_widgets.dart';
import 'package:plataformacnbbbjo/components/formPatrts/my_button.dart';
import 'package:plataformacnbbbjo/dataConst/constand.dart';
import 'package:plataformacnbbbjo/userNormal/componentsNormal/dialog_download.dart';
import 'package:plataformacnbbbjo/util/responsive.dart';

class GetApk extends StatefulWidget {
  const GetApk({super.key});

  @override
  State<GetApk> createState() => _GetApkState();
}

class _GetApkState extends State<GetApk> {
  @override
  Widget build(BuildContext context) {
    return BodyWidgets(body: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Descargar aplicación para celular', style: TextStyle(
          fontSize: responsiveFontSize(context, 18),
          fontWeight: FontWeight.bold
        ),),
        const SizedBox(height: 5.0),
        MyButton(text: 'Descargar', icon: Icon(Icons.download), 
        buttonColor: greenColorLight, onPressed: () {
          showDialog(context: context, builder: (BuildContext context) {
            return DialogDownload();
          });
        },)
      ],
    ));
  }
}