import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:plataformacnbbbjo/auth/auth_gate.dart';
import 'package:plataformacnbbbjo/firebase_options.dart';
import 'package:plataformacnbbbjo/providers/edit_provider.dart';
import 'package:plataformacnbbbjo/providers/theme.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await SentryFlutter.init((options) {
    options.dsn = 'https://4a07a0bc008b9ee9e2126c4950b70287@o4508933325848576.ingest.us.sentry.io/4508933337448448';
    options.tracesSampleRate = 1.0; //CAPTURA EL 100% DE LAS TRANSACCIONES EN PRODUCCION
    options.profilesSampleRate = 1.0; //CAPURA EL 100% DE LAS TRANSACCIONES RASTREADAS
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()), //Provier del tema
        ChangeNotifierProvider(create: (_) => EditProvider()), //Provider del employee
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return MaterialApp(
        theme: themeNotifier.isDarkTheme ? darkTheme : lightTheme,
        debugShowCheckedModeBanner: false,
        home: const AuthGate());
  }
}