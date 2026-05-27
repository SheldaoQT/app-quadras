import 'package:app_quadras/usuario.dart';
import 'package:flutter/material.dart';

class LoginStore extends ChangeNotifier {
  Usuario? _usuario;

  Usuario? get usuario => _usuario;

  void setUsuario(Usuario pUsuario) {
    _usuario = pUsuario;
  }
}
