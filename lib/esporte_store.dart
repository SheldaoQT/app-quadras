import 'package:app_quadras/esporte.dart';
import 'package:app_quadras/esporte_repository.dart';
import 'package:flutter/material.dart';

class EsporteStore extends ChangeNotifier {
  final repository = EsporteRepository();
  var isLoading = false;
  final esportes = <Esporte>[];

  Future<void> buscarEsportes() async {
    isLoading = true;
    notifyListeners();

    esportes.clear();
    esportes.addAll(await repository.buscarEsportes());
    await Future.delayed(const Duration(seconds: 3));

    isLoading = false;
    notifyListeners();
  }

  Future<void> cadastrarEsporte(Esporte esporte) async {
    await repository.cadastrarEsporte(esporte);
  }
}
