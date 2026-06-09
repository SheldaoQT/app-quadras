import 'package:app_quadras/esporte.dart';
import 'package:app_quadras/jogo.dart';
import 'package:app_quadras/quadra.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JogoRepository {
  final supabase = Supabase.instance.client;

  Future<void> buscarJogos() async {
    var teste = <int, List<int>>{};

    final registrosQuadra = await supabase.from('quadra').select();
    for (var element in registrosQuadra) {
      if (teste.containsKey(element['id']) == false) {
        teste[element['id']] = [];
      }
    }

    final registrosQuadraEsporte = await supabase.from('quadra_esporte').select();
    for (var element in registrosQuadraEsporte) {
      if (teste[element['quadra_id']]!.contains(element['esporte_id']) == false) {
        teste[element['quadra_id']]!.add(element['esporte_id']);
      }
    }

    final registrosEsporte = await supabase.from('esporte').select();

    final quadras = <Quadra>[];
    for (var element in teste.entries) {
      final idQuadra = element.key;

      final esportesHabilitados = registrosEsporte
          .where((element) => teste[idQuadra]!.contains(element['id']))
          .map((e) => Esporte.fromSupabase(e))
          .toList();

      quadras.add(
        Quadra(
          id: idQuadra,
          descricao: registrosQuadra.firstWhere((element) => element['id'] == idQuadra)['descricao'],
          esportesHabilitados: esportesHabilitados,
        ),
      );
    }

    final registrosJogo = await supabase.from('jogo').select();
    // debugPrint('registros jogo: $registrosJogo');

    final jogos = <Jogo>[];
    for (var element in registrosJogo) {
      // jogos.add(Jogo(id: element['id'], quadra: quadras.firstWhere((e) => e.id == element['quadra_id']), esporte: esportes.fi, data: data, horarioInicio: horarioInicio, horarioFim: horarioFim, host: host))
    }
  }
}
