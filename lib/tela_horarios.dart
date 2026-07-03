import 'package:app_quadras/horario_trabalho.dart';
import 'package:app_quadras/horarios_disponiveis.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TelaHorarios extends StatefulWidget {
  const TelaHorarios({
    super.key,
  });

  @override
  State<TelaHorarios> createState() => _TelaHorariosState();
}

class _TelaHorariosState extends State<TelaHorarios> {
  final diasSemana = [
    'Domingo',
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
  ];

  List<HorarioTrabalho> horarios = [];

  bool carregando = false;

  @override
  void initState() {
    super.initState();

    carregarHorarios();
  }

  Future<void> carregarHorarios() async {
    setState(() {
      carregando = true;
    });

    final supabase = Supabase.instance.client;

    final resposta = await supabase
        .from(
          'horario_trabalho',
        )
        .select();

    horarios = resposta
        .map(
          (
            e,
          ) => HorarioTrabalho(
            descricao: e['descricao'],

            horarioInicio: e['horario_inicio'],

            horarioFim: e['horario_fim'],
          ),
        )
        .toList();

    setState(() {
      carregando = false;
    });
  }

  bool existeHorario(
    String dia,
  ) {
    return horarios
        .where(
          (
            e,
          ) => e.descricao == dia,
        )
        .isNotEmpty;
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Horários',
        ),
      ),

      body: carregando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(
                16,
              ),

              itemCount: diasSemana.length,

              itemBuilder:
                  (
                    context,
                    index,
                  ) {
                    final dia = diasSemana[index];

                    final horario = horarios
                        .where(
                          (
                            e,
                          ) => e.descricao == dia,
                        )
                        .firstOrNull;

                    return Card(
                      child: ListTile(
                        title: Text(
                          dia,
                        ),

                        leading: Icon(
                          existeHorario(
                                dia,
                              )
                              ? Icons.check_circle
                              : Icons.cancel,

                          color:
                              existeHorario(
                                dia,
                              )
                              ? Colors.green
                              : Colors.red,
                        ),

                        onTap: () async {
                          await Navigator.push(
                            context,

                            MaterialPageRoute(
                              builder:
                                  (
                                    _,
                                  ) => HorariosDisponiveis(
                                    descricaoDia: dia,

                                    horarioTrabalho: horario,
                                  ),
                            ),
                          );

                          carregarHorarios();
                        },
                      ),
                    );
                  },
            ),
    );
  }
}
