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
}
