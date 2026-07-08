import 'package:flutter/material.dart';
import 'package:app_barba/cadastro_horario.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TelaHorarios extends StatefulWidget {
  const TelaHorarios({super.key});

  @override
  State<TelaHorarios> createState() => _TelaHorariosState();
}

class _TelaHorariosState extends State<TelaHorarios> {
  bool carregando = true;
  List<dynamic> horarios = [];

  final List<String> horariosDisponiveis = [
    '06:00',
    '06:30',
    '07:00',
    '07:30',
    '08:00',
    '08:30',
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '12:00',
    '12:30',
    '13:00',
    '13:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
    '17:00',
    '17:30',
    '18:00',
    '18:30',
    '19:00',
    '19:30',
    '20:00',
    '20:30',
    '21:00',
    '21:30',
    '22:00',
  ];

  @override
  void initState() {
    super.initState();
    buscarHorarios();
  }

  String nomeDia(int dia) {
    switch (dia) {
      case 0:
        return 'Domingo';
      case 1:
        return 'Segunda-feira';
      case 2:
        return 'Terça-feira';
      case 3:
        return 'Quarta-feira';
      case 4:
        return 'Quinta-feira';
      case 5:
        return 'Sexta-feira';
      case 6:
        return 'Sábado';
      default:
        return 'Dia inválido';
    }
  }

  Map<String, List<dynamic>> horariosAgrupadosPorBarbeiro() {
    final Map<String, List<dynamic>> agrupados = {};

    for (final horario in horarios) {
      final funcionario = horario['usuarios'];
      final nome = funcionario?['nome'] ?? 'Funcionário';

      if (!agrupados.containsKey(nome)) {
        agrupados[nome] = [];
      }

      agrupados[nome]!.add(horario);
    }

    return agrupados;
  }

  Map<int, List<dynamic>> horariosAgrupadosPorDia(List<dynamic> listaHorarios) {
    final Map<int, List<dynamic>> agrupados = {};

    for (final horario in listaHorarios) {
      final dia = horario['dia_semana'];

      if (!agrupados.containsKey(dia)) {
        agrupados[dia] = [];
      }

      agrupados[dia]!.add(horario);
    }

    for (final lista in agrupados.values) {
      lista.sort((a, b) {
        return formatarHoraTexto(a['hora_inicio']).compareTo(
          formatarHoraTexto(b['hora_inicio']),
        );
      });
    }

    return agrupados;
  }

  Future<void> buscarHorarios() async {
    try {
      final resposta = await Supabase.instance.client.from('horarios').select('''
            *,
            usuarios(*)
          ''').order('barbeiro_id').order('dia_semana').order('hora_inicio');

      if (!mounted) return;

      setState(() {
        horarios = resposta;
        carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        carregando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao buscar horários: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> excluirHorario(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir horário'),
        content: const Text('Deseja realmente excluir este horário?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await Supabase.instance.client.from('horarios').delete().eq('id', id);

      await buscarHorarios();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Horário excluído com sucesso'),
          backgroundColor: Colors.green,
        ),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir horário: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> editarHorario(Map horario) async {
    String? horaInicio = formatarHoraTexto(horario['hora_inicio']);
    String? horaFim = formatarHoraTexto(horario['hora_fim']);

    if (!horariosDisponiveis.contains(horaInicio)) {
      horaInicio = null;
    }

    if (!horariosDisponiveis.contains(horaFim)) {
      horaFim = null;
    }

    final salvar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return AlertDialog(
              title: const Text('Editar horário'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: horaInicio,
                    decoration: const InputDecoration(
                      labelText: 'Hora início',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.schedule),
                    ),
                    items: horariosDisponiveis
                        .map<DropdownMenuItem<String>>(
                          (hora) => DropdownMenuItem<String>(
                            value: hora,
                            child: Text(hora),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setStateDialog(() {
                        horaInicio = value;

                        if (horaFim != null && !horarioValido(horaInicio, horaFim)) {
                          horaFim = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: horaFim,
                    decoration: const InputDecoration(
                      labelText: 'Hora fim',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.schedule),
                    ),
                    items: horariosDisponiveis
                        .where((hora) {
                          if (horaInicio == null) {
                            return true;
                          }

                          return horaParaMinutos(hora) > horaParaMinutos(horaInicio!);
                        })
                        .map<DropdownMenuItem<String>>(
                          (hora) => DropdownMenuItem<String>(
                            value: hora,
                            child: Text(hora),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setStateDialog(() {
                        horaFim = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (horaInicio == null || horaFim == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Selecione a hora inicial e final'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    if (!horarioValido(horaInicio, horaFim)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'A hora final deve ser maior que a hora inicial',
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (salvar != true) return;

    try {
      await Supabase.instance.client.from('horarios').update({
        'hora_inicio': formatarHoraBanco(horaInicio!),
        'hora_fim': formatarHoraBanco(horaFim!),
      }).eq('id', horario['id']);

      await buscarHorarios();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Horário atualizado com sucesso'),
          backgroundColor: Colors.green,
        ),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar horário: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  int horaParaMinutos(String hora) {
    final partes = hora.split(':');
    final horas = int.parse(partes[0]);
    final minutos = int.parse(partes[1]);

    return (horas * 60) + minutos;
  }

  bool horarioValido(String? horaInicio, String? horaFim) {
    if (horaInicio == null || horaFim == null) {
      return false;
    }

    return horaParaMinutos(horaFim) > horaParaMinutos(horaInicio);
  }

  String formatarHoraBanco(String hora) {
    return '$hora:00';
  }

  String formatarHoraTexto(String hora) {
    final partes = hora.split(':');

    if (partes.length < 2) {
      return hora;
    }

    return '${partes[0]}:${partes[1]}';
  }

  Widget itemDiaHorario(int dia, List<dynamic> listaHorarios) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.access_time, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nomeDia(dia),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                ...listaHorarios.map((horario) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${formatarHoraTexto(horario['hora_inicio'])} às ${formatarHoraTexto(horario['hora_fim'])}',
                          ),
                        ),
                        IconButton(
                          tooltip: 'Editar',
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.blue,
                            size: 22,
                          ),
                          onPressed: () {
                            editarHorario(horario);
                          },
                        ),
                        IconButton(
                          tooltip: 'Excluir',
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 22,
                          ),
                          onPressed: () {
                            excluirHorario(horario['id']);
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final agrupados = horariosAgrupadosPorBarbeiro();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Horários de Trabalho'),
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : horarios.isEmpty
              ? const Center(
                  child: Text('Nenhum horário cadastrado'),
                )
              : RefreshIndicator(
                  onRefresh: buscarHorarios,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: agrupados.entries.map((entry) {
                      final nomeBarbeiro = entry.key;
                      final listaHorarios = entry.value;
                      final horariosPorDia = horariosAgrupadosPorDia(listaHorarios);
                      final diasOrdenados = horariosPorDia.keys.toList()..sort();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          leading: const Icon(Icons.person),
                          title: Text(nomeBarbeiro),
                          subtitle: Text(
                            '${listaHorarios.length} horário(s) cadastrado(s)',
                          ),
                          children: diasOrdenados.map((dia) {
                            return itemDiaHorario(
                              dia,
                              horariosPorDia[dia]!,
                            );
                          }).toList(),
                        ),
                      );
                    }).toList(),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CadastroHorario(),
            ),
          );

          if (!mounted) return;

          buscarHorarios();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
