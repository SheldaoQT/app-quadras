import 'package:app_quadras/servico.dart';
import 'package:app_quadras/servico_repository.dart';
import 'package:flutter/material.dart';

class ServicoStore extends ChangeNotifier {
  final repository = ServicoRepository();

  bool isLoading = false;

  final List<Servico> servicos = [];

  Future<void> buscarServicos() async {
    isLoading = true;

    notifyListeners();

    try {
      servicos.clear();

      servicos.addAll(
        await repository.buscarServicos(),
      );
    } finally {
      isLoading = false;

      notifyListeners();
    }
  }

  Future<void> cadastrarServico(
    Servico servico,
  ) async {
    await repository.cadastrarServico(
      servico,
    );

    await buscarServicos();
  }

  Future<void> atualizarServico(
    Servico servico,
  ) async {
    await repository.atualizarServico(
      servico,
    );

    await buscarServicos();
  }

  Future<void> excluirServico(
    String id,
  ) async {
    await repository.excluirServico(
      id,
    );

    servicos.removeWhere(
      (e) => e.id == id,
    );

    notifyListeners();
  }
}
