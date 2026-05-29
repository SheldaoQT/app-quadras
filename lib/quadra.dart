import 'package:app_quadras/esporte.dart';

class Quadra {
  final int? id;
  final String descricao;
  final List<Esporte> esportesHabilitados;

  Quadra({
    this.id,
    required this.descricao,
    required this.esportesHabilitados,
  });
}
