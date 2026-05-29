class Esporte {
  final int? id;
  final String descricao;
  final int numeroJogadores;

  Esporte({
    this.id,
    required this.descricao,
    required this.numeroJogadores,
  });

  factory Esporte.fromSupabase(Map<String, dynamic> map) {
    return Esporte(
      id: map['id'],
      descricao: map['descricao'],
      numeroJogadores: map['numero_jogadores'],
    );
  }

  @override
  String toString() {
    return "descricao: $descricao - nr_jogadores: $numeroJogadores";
  }
}
