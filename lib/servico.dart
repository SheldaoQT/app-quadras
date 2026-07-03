class Servico {
  final String id;

  final String nome;

  final double preco;

  final int duracao;

  final String profissionalId;

  Servico({
    required this.id,
    required this.nome,
    required this.preco,
    required this.duracao,
    required this.profissionalId,
  });

  factory Servico.fromSupabase(Map<String, dynamic> map) {
    return Servico(
      id: map['id'].toString(),
      nome: map['nome'] ?? '',
      preco: (map['preco'] as num).toDouble(),
      duracao: map['duracao'] ?? 0,
      profissionalId: map['profissional_id'].toString(),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'nome': nome,
      'preco': preco,
      'duracao': duracao,
      'profissional_id': profissionalId,
    };
  }
}
