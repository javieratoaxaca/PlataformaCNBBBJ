import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plataformacnbbbjo/auth/auth_service.dart';
import 'package:plataformacnbbbjo/dataConst/constand.dart';
import 'package:plataformacnbbbjo/pages/configuration/cerrar_sesion.dart';
import 'package:plataformacnbbbjo/userNormal/blockNormal/drawer_block_normal.dart';
import 'package:plataformacnbbbjo/userNormal/blockNormal/drawer_state_normal.dart';
import 'package:plataformacnbbbjo/userNormal/pages/course_selection_page.dart';
import 'package:plataformacnbbbjo/userNormal/pages/user_notifications_page.dart';
import 'package:plataformacnbbbjo/userNormal/pages/configuration_normal.dart';
import 'package:plataformacnbbbjo/userNormal/pages/dashboard_normal.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../drawerNormal/drawer_widget_normal.dart';

  /// Pantalla principal de la aplicación.
  ///
  /// Este widget es la página principal que organiza la navegación interna de la app
  /// a través de un Drawer (menú lateral) y un AppBar. Dependiendo de la opción seleccionada
  /// en el Drawer (representada por [NavItemNormal]), se muestra el contenido correspondiente.
  ///
  /// Se utiliza [BlocProvider] y [BlocConsumer] para gestionar el estado del Drawer a través
  /// de [NavDrawerBlocNormal] y actualizar la interfaz de forma reactiva.

class HomeNormal extends StatefulWidget {
  const HomeNormal({super.key});

  @override
  State<HomeNormal> createState() => _HomeNormalState();
}

class _HomeNormalState extends State<HomeNormal> {
  // Servicio de autenticación para obtener datos del usuario.
  late AuthService authServiceNormal;

  // Bloc que gestiona el estado del Drawer y la navegación.
  late NavDrawerBlocNormal _blocNormal;

  // Widget que contiene el contenido actual que se mostrará según la opción del Drawer.
  late Widget _contentNormal;

  // Variable para guardar el valor del CUPO
  String? userCupo; 

  @override
  void initState() {
    super.initState();
    authServiceNormal = AuthService();
    _blocNormal = NavDrawerBlocNormal();
    // Se inicializa el contenido en función de la opción seleccionada en el Drawer.
    _contentNormal = _getContentForStateNormal(_blocNormal.state.selected);
    _loadUserCupo();
  }

  Future<void> _loadUserCupo() async {
  try {
    // Se obtiene el UID del usuario autenticado
    String? uid = authServiceNormal.getCurrentUserUid();
    
    if (uid == null) {
      throw Exception("El UID del usuario es nulo.");
    }

    // Obtener datos del usuario desde la colección "User"
    final userSnapshot = await FirebaseFirestore.instance
        .collection('User')
        .where('uid', isEqualTo: uid)
        .get();

    if (userSnapshot.docs.isEmpty) {
      throw Exception("No se encontró el usuario en la base de datos.");
    }

    final userData = userSnapshot.docs.first.data();
    String cupo = userData['CUPO'];

    // Obtener datos del empleado desde la colección "Empleados"
    final employeeSnapshot = await FirebaseFirestore.instance
        .collection('Empleados')
        .where('CUPO', isEqualTo: cupo)
        .get();

    if (employeeSnapshot.docs.isEmpty) {
      throw Exception("No se encontró un empleado con el CUPO correspondiente.");
    }

    // Actualizar el estado con el CUPO encontrado
    setState(() {
      userCupo = cupo;
    });

  } catch (exception, stackTrace) {
    

    // Captura la excepción en Sentry
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag("error_type", "load_user_cupo");
      },
    );
  }
}

  @override
  Widget build(BuildContext context) {
    // Se obtiene el correo del usuario actual para pasarlo al Drawer.
    String? userEmailNormal = authServiceNormal.getCurrentUserEmail();
    
  String? uid = authServiceNormal.getCurrentUserUid();
    return BlocProvider(
      // Se provee el NavDrawerBlocNormal para que el resto de la interfaz pueda reaccionar
      // a los cambios en la navegación.
      create: (context) => _blocNormal,
      child: BlocConsumer<NavDrawerBlocNormal, NavDrawerStateNormal>(
        // Escucha cambios en el estado del Drawer y actualiza el contenido correspondiente.
        listener: (BuildContext context, NavDrawerStateNormal state) {
          setState(() {
            _contentNormal = _getContentForStateNormal(state.selected);
          });
        },
        builder: (context, state) {
          return LayoutBuilder(
            builder: (context, constraints) {
              // Se determina si se trata de una pantalla grande (ancho > 800)
              // para decidir si se muestra el Drawer de forma permanente.
              bool isLargeScreen = constraints.maxWidth > 800;
              return Scaffold(
                appBar: AppBar(
                  // El título del AppBar varía según la opción seleccionada.
                  title: Text(
                    _getAppbarTitleNormal(state.selected),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  shadowColor: Colors.black,
                  scrolledUnderElevation: 10.0,
                  centerTitle: true,
                  systemOverlayStyle: SystemUiOverlayStyle.dark,
                  actions: [
                    IconButton(
                      splashRadius: 35.0,
                      iconSize: 30.0,
                      tooltip: 'Notificaciones',
                      icon: Stack(
                        children: [
                          const Icon(Icons.notifications_rounded),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('notifications')
                                  .where('uid', isEqualTo: uid)
                                  .where('statusUser', isEqualTo: 'activo') // Solo notificaciones activas
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                int unreadCount = snapshot.data!.docs.length;

                                return Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: wineDark,
                                    shape: BoxShape.circle,
                                  
                                  ),
                                  
                                  child: Text(
                                    unreadCount > 9 ? '9+' : '$unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              },
                            ),
                          ),
                    ],
    ),
    onPressed: () {
      showDialog(
        context: context,
        builder: (context) => UserNotificationsPage(), // Muestra el panel lateral de notificaciones
      );
    },
  ),
],

                ),
                // En pantallas pequeñas se muestra el Drawer como menú lateral.
                drawer: isLargeScreen ? null : NavDrawerWidgetNormal(userEmail: userEmailNormal),
                body: Row(
                  children: [
                    // En pantallas grandes se muestra el Drawer en forma permanente.
                    if (isLargeScreen)
                      SizedBox(
                        width: 300, // Ancho fijo para el Drawer en pantallas grandes.
                        child: NavDrawerWidgetNormal(userEmail: userEmailNormal),
                      ),
                    // Área que muestra el contenido actual basado en la navegación.
                    Expanded(child: _contentNormal),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Retorna el contenido correspondiente en función del [NavItemNormal] del Drawer.
  ///
  /// Este metodo determina qué widget se debe mostrar en la pantalla principal
  /// según la opción seleccionada en el menú lateral.

  Widget _getContentForStateNormal(NavItemNormal selected) {
    switch (selected) {
      case NavItemNormal.homeUserView:
        return const DashboardNormal();
      case NavItemNormal.cursosView:
        if (userCupo != null) {
          return DynamicCourseSelectionPage(cupo: userCupo!); // Pasar el CUPO
        } else {
          return const Center(child: CircularProgressIndicator()); // Mostrar cargando si el CUPO aún no está disponible
        }
      case NavItemNormal.configuracionUserView:
        return const ConfigurationNormal();
      case NavItemNormal.cerrarSesionView:
        return const CerrarSesion();
      }
  }

  /// Retorna el título que se debe mostrar en el AppBar en función del [NavItemNormal].
  ///
  /// Este metodo asocia cada opción del Drawer con un título específico.

  String _getAppbarTitleNormal(NavItemNormal selected) {
    switch (selected) {
      case NavItemNormal.homeUserView:
        return "Inicio";
      case NavItemNormal.cursosView:
        return "Mis cursos";
      case NavItemNormal.configuracionUserView:
        return "Configuración";
      case NavItemNormal.cerrarSesionView:
        return "Cerrar Sesión";
      }
  }
}
