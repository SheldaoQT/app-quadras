import 'package:app_quadras/servico.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ServicoRepository {
  final supabase = Supabase.instance.client;

  Future<List<Servico>> buscarServicos() async {
    final servicosSupabase = await supabase.from('servico').select();

    return servicosSupabase
        .map<Servico>(
          (e) => Servico.fromSupabase(e),
        )
        .toList();
  }

  Future<void> cadastrarServico(
    Servico servico,
  ) async {
    await supabase.from('servico').insert({
      'nome': servico.nome,

      'preco': servico.preco,

      'duracao': servico.duracao,

      'profissional_id': servico.profissionalId,
    });
  }

  Future<void> atualizarServico(
    Servico servico,
  ) async {
    await supabase
        .from('servico')
        .update({
          'nome': servico.nome,

          'preco': servico.preco,

          'duracao': servico.duracao,

          'profissional_id': servico.profissionalId,
        })
        .eq(
          'id',
          servico.id,
        );
  }

  Future<void> excluirServico(
    String id,
  ) async {
    await supabase
        .from('servico')
        .delete()
        .eq(
          'id',
          id,
        );
  }
}
