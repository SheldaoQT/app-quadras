import 'package:app_quadras/esporte.dart';
import 'package:app_quadras/quadra.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuadraRepository {
  final supabase = Supabase.instance.client;

  Future<List<Quadra>> buscarQuadras() async {
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

    return quadras;
  }
}
