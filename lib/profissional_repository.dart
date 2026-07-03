import 'package:app_quadras/profissional.dart';
import 'package:app_quadras/servico.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfissionalRepository {
  final supabase = Supabase.instance.client;

  Future<List<Profissional>> buscarProfissionais() async {
    final registrosProfissional = await supabase.from('profissional').select();

    final registrosServico = await supabase.from('servico').select();

    final profissionais = <Profissional>[];

    for (final profissional in registrosProfissional) {
      final id = profissional['id'].toString();

      final servicos = registrosServico
          .where(
            (s) => s['profissional_id']?.toString() == id,
          )
          .map<Servico>(
            (e) => Servico.fromSupabase(e),
          )
          .toList();

      profissionais.add(
        Profissional(
          id: id,

          descricao: profissional['descricao'] ?? '',

          comissao: (profissional['comissao'] ?? 0).toDouble(),

          servicosHabilitados: servicos,
        ),
      );
    }

    return profissionais;
  }

  Future<void> cadastrarProfissional(
    Profissional profissional,
  ) async {
    await supabase.from('profissional').insert({
      'descricao': profissional.descricao,

      'comissao': profissional.comissao,
    });
  }

  Future<void> atualizarProfissional(
    Profissional profissional,
  ) async {
    await supabase
        .from('profissional')
        .update({
          'descricao': profissional.descricao,

          'comissao': profissional.comissao,
        })
        .eq(
          'id',
          profissional.id,
        );
  }

  Future<void> excluirProfissional(
    String id,
  ) async {
    await supabase
        .from('profissional')
        .delete()
        .eq(
          'id',
          id,
        );
  }
}
