class Usuario {
  final int id;

  final String nomeCompleto;

  final String login;

  final String senha;

  final bool isAdm;

  Usuario({
    required this.id,
    required this.nomeCompleto,
    required this.login,
    required this.senha,
    required this.isAdm,
  });

  factory Usuario.fromSupabase(
    Map<String, dynamic> map,
  ) {
    return Usuario(
      id: map['id'] ?? 0,

      nomeCompleto: map['nome_completo'] ?? map['nome'] ?? '',

      login: map['login'] ?? '',

      senha: map['senha'] ?? '',

      isAdm: map['is_adm'] ?? false,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'nome_completo': nomeCompleto,

      'login': login,

      'senha': senha,

      'is_adm': isAdm,
    };
  }

  Usuario copyWith({
    int? id,
    String? nomeCompleto,
    String? login,
    String? senha,
    bool? isAdm,
  }) {
    return Usuario(
      id: id ?? this.id,

      nomeCompleto: nomeCompleto ?? this.nomeCompleto,

      login: login ?? this.login,

      senha: senha ?? this.senha,

      isAdm: isAdm ?? this.isAdm,
    );
  }
}
