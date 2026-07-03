import 'package:app_quadras/componente_agendamento.dart';
import 'package:app_quadras/horario_trabalho.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HorariosDisponiveis extends StatefulWidget {
  const HorariosDisponiveis({
    super.key,
    required this.descricaoDia,
    this.horarioTrabalho,
  });

  final String descricaoDia;

  final HorarioTrabalho? horarioTrabalho;

  @override
  State<HorariosDisponiveis> createState() => _HorariosDisponiveisState();
}

class _HorariosDisponiveisState extends State<HorariosDisponiveis> {
  String horarioInicio = '08:00';

  String horarioFim = '18:00';

  bool selecionandoInicio = true;

  @override
  void initState() {
    super.initState();

    if (widget.horarioTrabalho != null) {
      horarioInicio = widget.horarioTrabalho!.horarioInicio;

      horarioFim = widget.horarioTrabalho!.horarioFim;
    }
  }

  void selecionarHorario(
    String horario,
  ) {
    setState(() {
      if (selecionandoInicio) {
        horarioInicio = horario;
      } else {
        horarioFim = horario;
      }
    });
  }

  Color corHorario(
    String horario,
  ) {
    return horario.compareTo(
                  horarioInicio,
                ) >=
                0 &&
            horario.compareTo(
                  horarioFim,
                ) <=
                0
        ? Colors.green
        : Colors.red;
  }

  Future<void> salvarHorario() async {
    final supabase = Supabase.instance.client;

    if (widget.horarioTrabalho != null) {
      await supabase
          .from(
            'horario_trabalho',
          )
          .update({
            'horario_inicio': horarioInicio,

            'horario_fim': horarioFim,
          })
          .eq(
            'id',
            widget.horarioTrabalho!.id!,
          );
    } else {
      await supabase
          .from(
            'horario_trabalho',
          )
          .insert({
            'descricao': widget.descricaoDia,

            'horario_inicio': horarioInicio,

            'horario_fim': horarioFim,
          });
    }

    if (mounted) {
      Navigator.pop(
        context,
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final horarios = List.generate(
      24,
      (
        i,
      ) => '${i.toString().padLeft(2, '0')}:00',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Horários Disponíveis',
        ),
      ),

      body: Column(
        children: [
          const SizedBox(
            height: 20,
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              ChoiceChip(
                label: const Text(
                  'Início',
                ),

                selected: selecionandoInicio,

                onSelected: (_) {
                  setState(() {
                    selecionandoInicio = true;
                  });
                },
              ),

              const SizedBox(
                width: 10,
              ),

              ChoiceChip(
                label: const Text(
                  'Fim',
                ),

                selected: !selecionandoInicio,

                onSelected: (_) {
                  setState(() {
                    selecionandoInicio = false;
                  });
                },
              ),
            ],
          ),

          const SizedBox(
            height: 20,
          ),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(
                20,
              ),

              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,

                childAspectRatio: 2,
              ),

              itemCount: horarios.length,

              itemBuilder:
                  (
                    context,
                    index,
                  ) {
                    final horario = horarios[index];

                    return ComponenteAgendamento(
                      textoHorario: horario,

                      containerColor: corHorario(
                        horario,
                      ),

                      clickContainer: () {
                        selecionarHorario(
                          horario,
                        );
                      },
                    );
                  },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(
              20,
            ),

            child: ElevatedButton(
              onPressed: salvarHorario,

              child: const Text(
                'Salvar',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
