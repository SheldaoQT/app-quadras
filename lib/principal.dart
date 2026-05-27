import 'package:app_quadras/esporte.dart';
import 'package:app_quadras/jogo.dart';
import 'package:app_quadras/login_store.dart';
import 'package:app_quadras/pesquisa_jogos.dart';
import 'package:app_quadras/quadra.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  var quadras = <Quadra>[];
  var esportes = <Esporte>[];
  var jogos = <Jogo>[];
  var esportesHabilitadosPorQuadra = <int, List<int>>{};

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    consultarEsportes().then((value) {
      consultarEsportesHabilitadosPorQuadra().then((value) {
        consultarQuadras().then((value) {
          consultarJogos().then(
            (value) {},
          );
        });
      });
    });
  }

  Future<void> consultarEsportes() async {
    final supabase = Supabase.instance.client;
    final esportesJson = await supabase.from('esporte').select();
    esportes.clear();
    setState(() {
      esportes = esportesJson.map(
        (json) {
          return Esporte(
            id: json['id'],
            descricao: json['descricao'],
            numeroJogadores: json['numero_jogadores'],
          );
        },
      ).toList();
      debugPrint('esportes length: ${esportes.length}');
    });
  }

  Future<void> consultarEsportesHabilitadosPorQuadra() async {
    final supabase = Supabase.instance.client;
    final esportesHabilitadosPorQuadraJson = await supabase.from('quadra_esporte').select();
    esportesHabilitadosPorQuadra.clear();
    for (var i = 0; i < esportesHabilitadosPorQuadraJson.length; i++) {
      final idQuadraAtual = esportesHabilitadosPorQuadraJson[i]['quadra_id'];
      if (esportesHabilitadosPorQuadra.containsKey(idQuadraAtual)) {
        (esportesHabilitadosPorQuadra[idQuadraAtual] as List<int>).add(esportesHabilitadosPorQuadraJson[i]['esporte_id']);
      } else {
        esportesHabilitadosPorQuadra[idQuadraAtual] = List<int>.from([esportesHabilitadosPorQuadraJson[i]['esporte_id']]);
      }
    }
    debugPrint('esportes habilitados por quadra length: ${esportesHabilitadosPorQuadra.length}');
  }

  Future<void> consultarQuadras() async {
    final supabase = Supabase.instance.client;
    final quadrasJson = await supabase.from('quadra').select();
    quadras.clear();
    debugPrint('[consultarQuadras] esportes habilitados por quadra: $esportesHabilitadosPorQuadra');
    setState(() {
      quadras = quadrasJson.map(
        (json) {
          final esportesHabilitados = <Esporte>[];
          debugPrint('[consultarQuadras] json: $json');

          // final idsEsportesHabilitados = [];
          // if (esportesHabilitadosPorQuadra.containsKey(json['id'])) {
          //   esportesHabilitados.add(esportes.firstWhere((element) => element.id == idsEsportesHabilitados[json['id']]));
          // }
          if (esportesHabilitadosPorQuadra.containsKey(json['id'])) {
            List<int> idsEsportesHabilitados = esportesHabilitadosPorQuadra[json['id']] as List<int>;
            for (var i = 0; i < idsEsportesHabilitados.length; i++) {
              final esporte = esportes.firstWhere((element) => element.id == idsEsportesHabilitados[i]);
              esportesHabilitados.add(esporte);
            }
          }

          return Quadra(id: json['id'], descricao: json['descricao'], esportesHabilitados: esportesHabilitados);
        },
      ).toList();
      quadras.removeWhere((element) => element.esportesHabilitados.isEmpty);
    });
    debugPrint('quadras length: ${quadras.length}');
  }

  Future<void> consultarJogos() async {
    final supabase = Supabase.instance.client;
    final jogosSupabase =
        await supabase //
            .from('jogo')
            .select()
            .eq('host', context.read<LoginStore>().usuario!.id);
    debugPrint('jogos supabase: $jogosSupabase');
    jogos.clear();
    setState(() {
      jogos = jogosSupabase.map(
        (e) {
          List<String> partesHorarioInicio = (e['hora_inicio'] as String).split(':');
          final hora = int.parse(partesHorarioInicio[0]);
          final minuto = int.parse(partesHorarioInicio[1]);

          List<String> partesHorarioFim = (e['hora_fim'] as String).split(':');
          final horaFim = int.parse(partesHorarioFim[0]);
          final minutoFim = int.parse(partesHorarioFim[1]);

          return Jogo(
            id: e['id'],
            quadra: quadras.firstWhere((element) => element.id == e['quadra_id']),
            esporte: esportes.firstWhere((element) => element.id == e['esporte_id']),
            data: DateFormat('yyyy-MM-dd').parse(e['data']),
            horarioInicio: TimeOfDay(hour: hora, minute: minuto),
            horarioFim: TimeOfDay(hour: horaFim, minute: minutoFim),
            host: context.read<LoginStore>().usuario!,
          );
        },
      ).toList();
    });
    // Jogo(id: id, quadra: quadra, esporte: esporte, data: data, horarioInicio: horarioInicio, horarioFim: horarioFim, host: host)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tela principal"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: Drawer(),
      body: RefreshIndicator.adaptive(
        onRefresh: consultarJogos,
        child: SizedBox.expand(
          child: Column(
            children: [
              Expanded(
                child: jogos.isEmpty
                    ? Container(
                        alignment: Alignment.center,
                        child: Text('Você não está participando de nenhum jogo no momento'),
                      )
                    : Container(
                        width: MediaQuery.of(context).size.width * 0.3,
                        child: ListView.builder(
                          itemCount: jogos.length,
                          itemBuilder: (context, index) {
                            // return Center(
                            //   child: Container(
                            //     padding: EdgeInsets.all(16),
                            //     decoration: BoxDecoration(
                            //       border: Border.all(),
                            //       borderRadius: BorderRadius.circular(16),
                            //     ),
                            //     child: Column(
                            //       crossAxisAlignment: CrossAxisAlignment.start,
                            //       children: [
                            //         Text(jogos[index].quadra.descricao),
                            //         Text(
                            //           '${DateFormat('dd/MM/yy').format(jogos[index].data)} - ${jogos[index].horarioInicio.hour}:${jogos[index].horarioInicio.minute}',
                            //         ),
                            //         Text(jogos[index].esporte.descricao),
                            //         Text('? confirmados'),
                            //       ],
                            //     ),
                            //   ),
                            // );
                            return Center(
                              child: Card(
                                elevation: 8,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(jogos[index].quadra.descricao),
                                      Text(
                                        '${DateFormat('dd/MM/yy').format(jogos[index].data)} - ${jogos[index].horarioInicio.hour}:${jogos[index].horarioInicio.minute}',
                                      ),
                                      Text(jogos[index].esporte.descricao),
                                      Text('?/${jogos[index].esporte.numeroJogadores} confirmados'),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
              Container(
                color: Theme.of(context).colorScheme.inversePrimary,
                alignment: Alignment.center,
                height: MediaQuery.of(context).size.height * 0.1,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PesquisaJogos(),
                    ),
                  ),
                  child: Text('Jogos'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
