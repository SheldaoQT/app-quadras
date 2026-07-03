class Agendamento {
  final String id;

  final String clienteId;

  final String profissionalId;

  final String servicoId;

  final DateTime data;

  final String status;

  Agendamento({
    required this.id,
    required this.clienteId,
    required this.profissionalId,
    required this.servicoId,
    required this.data,
    required this.status,
  });

  factory Agendamento.fromSupabase(
    Map<String, dynamic> map,
  ) {
    return Agendamento(
      id: map['id']?.toString() ?? '',

      clienteId: map['cliente_id']?.toString() ?? '',

      profissionalId: map['profissional_id']?.toString() ?? '',

      servicoId: map['servico_id']?.toString() ?? '',

      data:
          DateTime.tryParse(
            map['data']?.toString() ?? '',
          ) ??
          DateTime.now(),

      status: map['status']?.toString() ?? 'agendado',
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'cliente_id': clienteId,

      'profissional_id': profissionalId,

      'servico_id': servicoId,

      'data': data.toIso8601String(),

      'status': status,
    };
  }
}
