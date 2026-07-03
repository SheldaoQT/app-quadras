class HorarioTrabalho {
  final String? id;

  final String descricao;

  final String horarioInicio;

  final String horarioFim;

  HorarioTrabalho({
    this.id,
    required this.descricao,
    required this.horarioInicio,
    required this.horarioFim,
  });

  factory HorarioTrabalho.fromSupabase(
    Map<String, dynamic> map,
  ) {
    return HorarioTrabalho(
      id: map['id']?.toString(),

      descricao: map['descricao'] ?? '',

      horarioInicio: map['horario_inicio']?.toString() ?? '08:00',

      horarioFim: map['horario_fim']?.toString() ?? '18:00',
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'descricao': descricao,

      'horario_inicio': horarioInicio,

      'horario_fim': horarioFim,
    };
  }

  HorarioTrabalho copyWith({
    String? id,
    String? descricao,
    String? horarioInicio,
    String? horarioFim,
  }) {
    return HorarioTrabalho(
      id: id ?? this.id,

      descricao: descricao ?? this.descricao,

      horarioInicio: horarioInicio ?? this.horarioInicio,

      horarioFim: horarioFim ?? this.horarioFim,
    );
  }
}
