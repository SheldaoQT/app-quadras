import 'package:app_quadras/esporte.dart';
import 'package:app_quadras/horario_funcionamento.dart';
import 'package:app_quadras/login_store.dart';
import 'package:app_quadras/quadra.dart';
import 'package:app_quadras/usuario.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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
  var horariosFuncionamento = <HorarioFuncionamento>[];
  int? idQuadraSelecionada;
  int? idEsporteSelecionado;
  int etapa = 0;
  DateTime dataJogo = DateTime.now();
  TextEditingController dataJogoController = TextEditingController();
  TextEditingController horarioInicioController = TextEditingController();
  TextEditingController horarioFimController = TextEditingController();
  TimeOfDay? horarioInicioJogo;
  TimeOfDay? horarioFimJogo;
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
                consultarHorariosFuncionamento().then(
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
      idEsporteSelecionado = quadras.first.esportesHabilitados.first.id;
    });
    debugPrint('quadras length: ${quadras.length}');
    if (quadras.isNotEmpty) {
      setState(() {
        idQuadraSelecionada = quadras.first.id;
      });
    }
  }

  Future<void> consultarHorariosFuncionamento() async {
    final supabase = Supabase.instance.client;
    final horarioFuncionamentoJson = await supabase.from('horario_funcionamento').select();
    setState(() {
      horariosFuncionamento = horarioFuncionamentoJson.map(
        (json) {
          return HorarioFuncionamento(
            descricao: json['descricao'],
            horarioInicio: json['horario_inicio'],
            horarioFim: json['horario_fim'],
          );
        },
      ).toList();
    });
  }

  String obterDescricaoDiaSemana(DateTime dateTime) {
    if (dateTime.weekday == 1) {
      return 'Segunda';
    }
    if (dateTime.weekday == 2) {
      return 'Terça';
    }
    if (dateTime.weekday == 3) {
      return 'Quarta';
    }
    if (dateTime.weekday == 4) {
      return 'Quinta';
    }
    if (dateTime.weekday == 5) {
      return 'Sexta';
    }
    if (dateTime.weekday == 6) {
      return 'Sábado';
    }
    return 'Domingo';
  }

  String obterStringTimeOfDay(TimeOfDay timeOfDay) {
    final hora = timeOfDay.hour.toString().padLeft(2, '0');
    final minuto = timeOfDay.minute.toString().padLeft(2, '0');
    return '$hora:$minuto';
  }

  void salvarJogo(Usuario usuarioLogado) async {
    final supabase = Supabase.instance.client;
    try {
      await supabase.from('jogo').insert({
        'quadra_id': idQuadraSelecionada,
        'esporte_id': idEsporteSelecionado,
        'data': DateFormat('yyyy-MM-dd').format(dataJogo),
        'hora_inicio': obterStringTimeOfDay(horarioInicioJogo!),
        'hora_fim': obterStringTimeOfDay(horarioFimJogo!),
        'host': usuarioLogado.id,
      });
    } catch (e) {
      debugPrint('exception: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cadastro de jogo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.2,
          child: isLoading
              ? Center(
                  child: CircularProgressIndicator.adaptive(),
                )
              : Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    spacing: 8,
                    children: [
                      DropdownButtonFormField(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                        ),
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
                            idEsporteSelecionado = quadras.firstWhere((element) => element.id == idQuadraSelecionada).esportesHabilitados.first.id;
                          });
                        },
                      ),
                      if (etapa == 0)
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              etapa = 1;
                            });
                          },
                          child: Text('Avançar'),
                        ),
                      if (etapa >= 1)
                        DropdownButtonFormField(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          initialValue: idEsporteSelecionado,
                          items: quadras.firstWhere((element) => element.id == idQuadraSelecionada).esportesHabilitados.map(
                            (esporte) {
                              return DropdownMenuItem(
                                value: esporte.id,
                                child: Text(esporte.descricao),
                              );
                            },
                          ).toList(),
                          onChanged: quadras.firstWhere((element) => element.id == idQuadraSelecionada).esportesHabilitados.length == 1
                              ? null
                              : (value) {
                                  setState(() {
                                    idEsporteSelecionado = value as int?;
                                  });
                                },
                        ),
                      if (etapa == 1)
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              etapa = 2;
                            });
                          },
                          child: Text('Avançar'),
                        ),
                      if (etapa >= 2)
                        ElevatedButton(
                          onPressed: () async {
                            // showDatePicker(
                            //   context: context,
                            //   initialDate: dataJogo,
                            //   firstDate: DateTime(2000),
                            //   lastDate: DateTime(2100),
                            // ).then(
                            //   (selectedDate) {
                            //     if (selectedDate != null) {
                            //       print('data selecionada: ${DateFormat('dd/MM/yy').format(selectedDate)}');
                            //       setState(() {
                            //         dataJogo = selectedDate;
                            //       });
                            //     }
                            //   },
                            // );
                            final selectedDate = await showDatePicker(
                              context: context,
                              initialDate: dataJogo,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (selectedDate != null) {
                              // print('data selecionada: ${DateFormat('dd/MM/yy').format(selectedDate)}');
                              // print('weekday: ${selectedDate.weekday}');
                              final inteirosDiasSemana = horariosFuncionamento.map(
                                (hf) {
                                  if (hf.descricao == 'Segunda') {
                                    return 1;
                                  }
                                  if (hf.descricao == 'Terça') {
                                    return 2;
                                  }
                                  if (hf.descricao == 'Quarta') {
                                    return 3;
                                  }
                                  if (hf.descricao == 'Quinta') {
                                    return 4;
                                  }
                                  if (hf.descricao == 'Sexta') {
                                    return 5;
                                  }
                                  if (hf.descricao == 'Sábado') {
                                    return 6;
                                  }
                                  if (hf.descricao == 'Domingo') {
                                    return 7;
                                  }
                                },
                              ).toList();
                              if (inteirosDiasSemana.contains(selectedDate.weekday)) {
                                setState(() {
                                  dataJogo = selectedDate;
                                  dataJogoController.text = DateFormat('dd/MM/yy').format(selectedDate);
                                  etapa = 3;
                                });
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog.adaptive(
                                      title: Text('Atenção'),
                                      content: Text('Não é possível cadastrar jogos neste dia da semana.'),
                                      actions: [
                                        ElevatedButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: Text('Fechar'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            }
                          },
                          child: Text('Selecionar data'),
                        ),
                      if (etapa >= 2)
                        TextFormField(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Data selecionada',
                          ),
                          controller: dataJogoController,
                        ),
                      if (etapa >= 3)
                        ElevatedButton(
                          onPressed: () async {
                            final selectedInitialTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (selectedInitialTime != null) {
                              print('horário inicial: ${selectedInitialTime.hour}:${selectedInitialTime.minute}');
                              final horarioFuncionamentoDataJogo = horariosFuncionamento.firstWhere(
                                (hf) => hf.descricao == obterDescricaoDiaSemana(dataJogo),
                              );
                              if (selectedInitialTime.hour >= horarioFuncionamentoDataJogo.horarioInicio) {
                                setState(() {
                                  horarioInicioJogo = selectedInitialTime;
                                  horarioInicioController.text = obterStringTimeOfDay(horarioInicioJogo!);
                                  etapa = 4;
                                });
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog.adaptive(
                                      title: Text('Atenção'),
                                      content: Text(
                                        'Não é possível selecionar um horário antes de ${horarioFuncionamentoDataJogo.horarioInicio.toString().padLeft(2, '0')}:00.',
                                      ),
                                      actions: [
                                        ElevatedButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: Text('Fechar'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            }
                          },
                          child: Text('Selecionar horário início'),
                        ),
                      if (etapa >= 3)
                        TextFormField(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Horário de início selecionado',
                          ),
                          controller: horarioInicioController,
                        ),
                      if (etapa >= 4)
                        ElevatedButton(
                          onPressed: () async {
                            final selectedEndTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (selectedEndTime != null) {
                              print('horário final: ${selectedEndTime.hour}:${selectedEndTime.minute}');
                              final horarioFuncionamentoDataJogo = horariosFuncionamento.firstWhere(
                                (hf) => hf.descricao == obterDescricaoDiaSemana(dataJogo),
                              );
                              if (selectedEndTime.hour >= horarioFuncionamentoDataJogo.horarioInicio) {
                                setState(() {
                                  horarioFimJogo = selectedEndTime;
                                  horarioFimController.text = obterStringTimeOfDay(horarioFimJogo!);
                                  etapa = 5;
                                });
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog.adaptive(
                                      title: Text('Atenção'),
                                      content: Text(
                                        'Não é possível selecionar um horário depois de ${horarioFuncionamentoDataJogo.horarioFim.toString().padLeft(2, '0')}:00.',
                                      ),
                                      actions: [
                                        ElevatedButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: Text('Fechar'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            }
                          },
                          child: Text('Selecionar horário fim'),
                        ),
                      if (etapa >= 4)
                        TextFormField(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Horário de fim selecionado',
                          ),
                          controller: horarioFimController,
                        ),
                      if (etapa >= 5)
                        ElevatedButton(
                          onPressed: () {
                            salvarJogo(context.read<LoginStore>().usuario!);
                          },
                          child: Text('Salvar jogo'),
                        ),
                      // if (etapa >= 5)
                      //   ElevatedButton(
                      //     onPressed: () {
                      //       salvarJogo();
                      //     },
                      //     child: Text('Salvar jogo'),
                      //   ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
