import 'package:app_quadras/quadra.dart';
import 'package:app_quadras/quadra_repository.dart';
import 'package:flutter/material.dart';

class QuadraStore extends ChangeNotifier {
  final repository = QuadraRepository();
  var isLoading = false;
  final quadras = <Quadra>[];

  Future<void> buscarQuadras() async {
    isLoading = true;
    notifyListeners();

    quadras.clear();
    quadras.addAll(await repository.buscarQuadras());

    isLoading = false;
    notifyListeners();
  }
}
