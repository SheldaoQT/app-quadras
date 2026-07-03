import 'package:app_quadras/profissional.dart';
import 'package:app_quadras/profissional_repository.dart';
import 'package:flutter/material.dart';

class ProfissionalStore extends ChangeNotifier {
  final repository = ProfissionalRepository();

  bool isLoading = false;

  final List<Profissional> profissionais = [];

  Future<void> buscarProfissionais() async {
    isLoading = true;

    notifyListeners();

    try {
      profissionais.clear();

      profissionais.addAll(
        await repository.buscarProfissionais(),
      );
    } finally {
      isLoading = false;

      notifyListeners();
    }
  }

  Future<void> cadastrarProfissional(
    Profissional profissional,
  ) async {
    await repository.cadastrarProfissional(
      profissional,
    );

    await buscarProfissionais();
  }

  Future<void> atualizarProfissional(
    Profissional profissional,
  ) async {
    await repository.atualizarProfissional(
      profissional,
    );

    await buscarProfissionais();
  }

  Future<void> excluirProfissional(
    String id,
  ) async {
    await repository.excluirProfissional(
      id,
    );

    profissionais.removeWhere(
      (e) => e.id == id,
    );

    notifyListeners();
  }
}
