import 'package:app_quadras/agendamento.dart';
import 'package:app_quadras/profissional.dart';
import 'package:app_quadras/servico.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AgendamentoRepository {
  final supabase = Supabase.instance.client;

  Future<List<Agendamento>> buscarAgendamentos() async {
    final registros = await supabase.from('agendamento').select();

    return registros
        .map<Agendamento>(
          (e) => Agendamento.fromSupabase(e),
        )
        .toList();
  }

  Future<List<Profissional>> buscarProfissionais() async {
    final registrosProfissional = await supabase
        .from(
          'profissional',
        )
        .select();

    final registrosServico = await supabase
        .from(
          'servico',
        )
        .select();

    final profissionais = <Profissional>[];

    for (final profissional in registrosProfissional) {
      final id = profissional['id'].toString();

      final servicos = registrosServico
          .where(
            (s) => s['profissional_id'].toString() == id,
          )
          .map(
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

  Future<void> salvarAgendamento(
    Agendamento agendamento,
  ) async {
    await supabase
        .from('agendamento')
        .insert(
          agendamento.toSupabase(),
        );
  }

  Future<void> cancelarAgendamento(
    String id,
  ) async {
    await supabase
        .from('agendamento')
        .update({
          'status': 'cancelado',
        })
        .eq(
          'id',
          id,
        );
  }
}
