import 'package:app_quadras/esporte.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EsporteRepository {
  final supabase = Supabase.instance.client;

  Future<List<Esporte>> buscarEsportes() async {
    final esportesSupabase = await supabase
        .from("esporte") //
        .select();
    return esportesSupabase.map((e) => Esporte.fromSupabase(e)).toList();
  }

  Future<void> cadastrarEsporte(Esporte esporte) async {
    await supabase.from('esporte').insert({
      'descricao': esporte.descricao,
      'numero_jogadores': esporte.numeroJogadores,
    });
  }
}
