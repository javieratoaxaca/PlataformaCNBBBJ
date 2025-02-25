import 'package:flutter/cupertino.dart';

///Controlador para el Widget personalizado `FirebaseDropdown` con las acciones para poder utilizar el
///widget en la UI.
class FirebaseDropdownController extends ChangeNotifier {
  //Documento seleccionado de tipo Map<String, dynamic>? aceptando valores nulos
  Map<String, dynamic>? _selectedDocument;

  // Metodo para obtener el valor seleccionado
  Map<String, dynamic>? get selectedDocument => _selectedDocument;

  // Metodo para establecer el documento seleccionado
  void setDocument(Map<String, dynamic>? document) {
    _selectedDocument = document;
    notifyListeners(); // Notifica a los listeners
  }

  // Limpia la selección actual
  void clearSelection() {
    _selectedDocument = null;
    notifyListeners(); // Notifica a los listeners
  }

  // Elimina un listener
  void clearSection(Function() listener) {
    _selectedDocument = null;
    notifyListeners();
  }

  //Sincroniza la selección actual con los documentos disponibles
  void synchronizeSelection(List<Map<String, dynamic>> documents) {
    if (_selectedDocument != null &&
        !documents.any((doc) => doc['Id'] == _selectedDocument?['Id'])) {
      clearSelection();
    }
  }
}