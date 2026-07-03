import 'package:app_quadras/servico.dart';
import 'package:app_quadras/horario_trabalho.dart';
import 'package:app_quadras/login_store.dart';
import 'package:app_quadras/profissional.dart';
import 'package:app_quadras/profissional_store.dart';
import 'package:app_quadras/usuario.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CadastroAgendamento extends StatefulWidget {
  const CadastroAgendamento({super.key});

  @override
  State<CadastroAgendamento> createState() => _CadastroAgendamentoState();
}

class _CadastroAgendamentoState extends State<CadastroAgendamento> {
  bool isLoading = true;

  List<Profissional> profissionais = [];
  List<HorarioTrabalho> horariosTrabalho = [];

  dynamic idProfissionalSelecionado;

  String? idServicoSelecionado;

  int etapa = 0;

  DateTime dataAgendamento = DateTime.now();

  final dataController = TextEditingController();

  final horarioInicioController = TextEditingController();

  final horarioFimController = TextEditingController();

  TimeOfDay? horarioInicio;

  TimeOfDay? horarioFim;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  @override
  void dispose() {
    dataController.dispose();
    horarioInicioController.dispose();
    horarioFimController.dispose();
    super.dispose();
  }

  Future<void> carregarDados() async {
    await context.read<ProfissionalStore>().buscarProfissionais();

    await consultarHorarios();

    if (!mounted) return;

    setState(() {
      profissionais = context.read<ProfissionalStore>().profissionais;

      isLoading = false;
    });
  }

  Future<void> consultarHorarios() async {
    final supabase = Supabase.instance.client;

    final resposta = await supabase
        .from(
          'horario_trabalho',
        )
        .select();

    horariosTrabalho = resposta.map<HorarioTrabalho>((json) {
      return HorarioTrabalho(
        descricao: json['descricao'],
        horarioInicio: json['horario_inicio'],
        horarioFim: json['horario_fim'],
      );
    }).toList();
  }

  String formatarHorario(
    TimeOfDay horario,
  ) {
    return '${horario.hour.toString().padLeft(2, '0')}:${horario.minute.toString().padLeft(2, '0')}';
  }

  bool horarioValido() {
    if (horarioInicio == null || horarioFim == null) {
      return false;
    }

    final inicio = horarioInicio!.hour * 60 + horarioInicio!.minute;

    final fim = horarioFim!.hour * 60 + horarioFim!.minute;

    return fim > inicio;
  }

  Future<void> salvarAgendamento(
    Usuario usuario,
  ) async {
    if (!horarioValido()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Horário inválido',
          ),
        ),
      );

      return;
    }

    try {
      final supabase = Supabase.instance.client;

      await supabase.from('agendamento').insert({
        'cliente_id': usuario.id,
        'profissional_id': idProfissionalSelecionado,
        'servico_id': idServicoSelecionado,
        'data': DateFormat(
          'yyyy-MM-dd',
        ).format(dataAgendamento),
        'hora_inicio': formatarHorario(
          horarioInicio!,
        ),
        'hora_fim': formatarHorario(
          horarioFim!,
        ),
        'status': 'agendado',
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Agendamento realizado',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cadastro de agendamento',
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(
                16,
              ),
              child: Column(
                children: [
                  DropdownButtonFormField(
                    initialValue: idProfissionalSelecionado,
                    decoration: const InputDecoration(
                      labelText: 'Profissional',
                    ),
                    items: profissionais.map(
                      (p) {
                        return DropdownMenuItem(
                          value: p.id,
                          child: Text(
                            p.descricao,
                          ),
                        );
                      },
                    ).toList(),
                    onChanged: (value) {
                      setState(() {
                        idProfissionalSelecionado = value;

                        etapa = 1;
                      });
                    },
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  if (etapa >= 1)
                    DropdownButtonFormField(
                      initialValue: idServicoSelecionado,
                      decoration: const InputDecoration(
                        labelText: 'Serviço',
                      ),
                      items: profissionais
                          .firstWhere(
                            (e) => e.id == idProfissionalSelecionado,
                          )
                          .servicosHabilitados
                          .map(
                            (
                              Servico s,
                            ) {
                              return DropdownMenuItem(
                                value: s.id,
                                child: Text(
                                  s.nome,
                                ),
                              );
                            },
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          idServicoSelecionado = value;

                          etapa = 2;
                        });
                      },
                    ),

                  const SizedBox(
                    height: 12,
                  ),

                  if (etapa >= 2)
                    ElevatedButton(
                      onPressed: () async {
                        final data = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(
                            2100,
                          ),
                        );

                        if (data != null) {
                          setState(() {
                            dataAgendamento = data;

                            dataController.text = DateFormat(
                              'dd/MM/yyyy',
                            ).format(data);

                            etapa = 3;
                          });
                        }
                      },
                      child: const Text(
                        'Selecionar data',
                      ),
                    ),

                  TextField(
                    controller: dataController,
                    readOnly: true,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  ElevatedButton(
                    onPressed: () async {
                      horarioInicio = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );

                      if (horarioInicio != null) {
                        horarioInicioController.text = formatarHorario(horarioInicio!);

                        setState(() {
                          etapa = 4;
                        });
                      }
                    },
                    child: const Text(
                      'Horário início',
                    ),
                  ),

                  TextField(
                    controller: horarioInicioController,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  ElevatedButton(
                    onPressed: () async {
                      horarioFim = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );

                      if (horarioFim != null) {
                        horarioFimController.text = formatarHorario(horarioFim!);

                        setState(() {
                          etapa = 5;
                        });
                      }
                    },
                    child: const Text(
                      'Horário fim',
                    ),
                  ),

                  TextField(
                    controller: horarioFimController,
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  ElevatedButton(
                    onPressed: () {
                      salvarAgendamento(
                        context.read<LoginStore>().usuario!,
                      );
                    },
                    child: const Text(
                      'Salvar',
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
