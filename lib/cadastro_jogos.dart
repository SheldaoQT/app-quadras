import 'package:app_quadras/esporte.dart';
import 'package:app_quadras/quadra.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CadastroJogos extends StatefulWidget {
  const CadastroJogos({super.key});

  @override
  State<CadastroJogos> createState() => _CadastroJogosState();
}

class _CadastroJogosState extends State<CadastroJogos> {
  var isLoading = true;
  var esportes = <Esporte>[];
  var esportesHabilitadosPorQuadra = <int, List<int>>{};
  var quadras = <Quadra>[];
  int? idQuadraSelecionada;
  /**
   * {
   *  quadra_id: [ ids esportes ]
   * }
   * 
   * {
   *  8: [1],
   *  9: [1, 2]
   * }
   */

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    consultarEsportes().then(
      (value) {
        consultarEsportesHabilitadosPorQuadra().then(
          (value) {
            consultarQuadras().then(
              (value) {
                setState(() {
                  isLoading = false;
                });
              },
            );
          },
        );
      },
    );
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
    setState(() {
      quadras = quadrasJson.map(
        (json) {
          final esportesHabilitados = <Esporte>[];
          debugPrint('esportes habilitados quadra: $esportesHabilitadosPorQuadra');
          debugPrint('json: $json');

          final idsEsportesHabilitados = [];
          if (esportesHabilitadosPorQuadra.containsKey(json['id'])) {
            esportesHabilitados.add(esportes.firstWhere((element) => element.id == idsEsportesHabilitados[json['id']]));
          }

          return Quadra(id: json['id'], descricao: json['descricao'], esportesHabilitados: esportesHabilitados);
        },
      ).toList();
    });
    debugPrint('quadras length: ${quadras.length}');
    if (quadras.isNotEmpty) {
      setState(() {
        idQuadraSelecionada = quadras.first.id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cadastro de jogo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SizedBox.expand(
        child: isLoading
            ? Center(
                child: CircularProgressIndicator.adaptive(),
              )
            : Column(
                children: [
                  DropdownButtonFormField(
                    initialValue: idQuadraSelecionada,
                    items: quadras.map(
                      (quadra) {
                        return DropdownMenuItem(
                          value: quadra.id,
                          child: Text(quadra.descricao),
                        );
                      },
                    ).toList(),
                    onChanged: (value) {
                      setState(() {
                        idQuadraSelecionada = value;
                      });
                    },
                  ),
                ],
              ),
      ),
    );
  }
}
