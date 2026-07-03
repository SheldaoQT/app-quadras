import 'package:app_quadras/servico.dart';

class Profissional {
  final String id;

  final String descricao;

  final double comissao;

  final List<Servico> servicosHabilitados;

  Profissional({
    required this.id,
    required this.descricao,
    required this.comissao,
    this.servicosHabilitados = const [],
  });

  factory Profissional.fromSupabase(
    Map<String, dynamic> map,
  ) {
    return Profissional(
      id: map['id']?.toString() ?? '',

      descricao: map['descricao']?.toString() ?? '',

      comissao: (map['comissao'] ?? 0).toDouble(),

      servicosHabilitados: [],
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'descricao': descricao,
      'comissao': comissao,
    };
  }

  Profissional copyWith({
    String? id,
    String? descricao,
    double? comissao,
    List<Servico>? servicosHabilitados,
  }) {
    return Profissional(
      id: id ?? this.id,
      descricao: descricao ?? this.descricao,
      comissao: comissao ?? this.comissao,
      servicosHabilitados: servicosHabilitados ?? this.servicosHabilitados,
    );
  }
}
