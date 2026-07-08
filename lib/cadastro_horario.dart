import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CadastroHorario extends StatefulWidget {
  const CadastroHorario({super.key});

  @override
  State<CadastroHorario> createState() => _CadastroHorarioState();
}

class _CadastroHorarioState extends State<CadastroHorario> {
  bool carregando = true;
  bool salvando = false;

  List<dynamic> funcionarios = [];

  String? funcionarioSelecionado;
  List<int> diasSelecionados = [];

  String? horaInicio;
  String? horaFim;

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
    buscarFuncionarios();
  }

  Future<void> buscarFuncionarios() async {
    try {
      final resposta = await Supabase.instance.client.from('usuarios').select().eq('perfil', 'funcionario').eq('ativo', true).order('nome');

      if (!mounted) return;

      setState(() {
        funcionarios = resposta;
        carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        carregando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao buscar barbeiros: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  int horaParaMinutos(String hora) {
    final partes = hora.split(':');
    final horas = int.parse(partes[0]);
    final minutos = int.parse(partes[1]);

    return (horas * 60) + minutos;
  }

  void marcarDia(int dia, bool marcado) {
    setState(() {
      if (marcado) {
        diasSelecionados.add(dia);
      } else {
        diasSelecionados.remove(dia);
      }

      diasSelecionados.sort();
    });
  }

  bool horarioValido() {
    if (horaInicio == null || horaFim == null) {
      return false;
    }

    return horaParaMinutos(horaFim!) > horaParaMinutos(horaInicio!);
  }

  bool horariosSobrepostos({
    required String inicioExistente,
    required String fimExistente,
    required String novoInicio,
    required String novoFim,
  }) {
    final inicioExistenteMinutos = horaParaMinutos(formatarHoraTexto(inicioExistente));
    final fimExistenteMinutos = horaParaMinutos(formatarHoraTexto(fimExistente));
    final novoInicioMinutos = horaParaMinutos(novoInicio);
    final novoFimMinutos = horaParaMinutos(novoFim);

    return novoInicioMinutos < fimExistenteMinutos && novoFimMinutos > inicioExistenteMinutos;
  }

  Future<List<String>> buscarDiasComConflito() async {
    final resposta =
        await Supabase.instance.client.from('horarios').select().eq('barbeiro_id', funcionarioSelecionado!).inFilter('dia_semana', diasSelecionados);

    final List<String> diasComConflito = [];

    for (final horario in resposta) {
      final temConflito = horariosSobrepostos(
        inicioExistente: horario['hora_inicio'],
        fimExistente: horario['hora_fim'],
        novoInicio: horaInicio!,
        novoFim: horaFim!,
      );

      if (temConflito) {
        final dia = horario['dia_semana'];

        if (!diasComConflito.contains(nomeDia(dia))) {
          diasComConflito.add(nomeDia(dia));
        }
      }
    }

    return diasComConflito;
  }

  Future<void> salvar() async {
    if (funcionarioSelecionado == null || diasSelecionados.isEmpty || horaInicio == null || horaFim == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!horarioValido()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A hora final deve ser maior que a hora inicial'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      salvando = true;
    });

    try {
      final diasComConflito = await buscarDiasComConflito();

      if (diasComConflito.isNotEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Já existe horário cadastrado para: ${diasComConflito.join(', ')}',
            ),
            backgroundColor: Colors.orange,
          ),
        );

        setState(() {
          salvando = false;
        });

        return;
      }

      final registros = diasSelecionados.map((dia) {
        return {
          'barbeiro_id': funcionarioSelecionado,
          'dia_semana': dia,
          'hora_inicio': formatarHoraBanco(horaInicio!),
          'hora_fim': formatarHoraBanco(horaFim!),
        };
      }).toList();

      await Supabase.instance.client.from('horarios').insert(registros);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Horários cadastrados com sucesso'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
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
          content: Text('Erro ao cadastrar horários: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      salvando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dias = [0, 1, 2, 3, 4, 5, 6];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar Horário'),
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<String>(
                  value: funcionarioSelecionado,
                  decoration: const InputDecoration(
                    labelText: 'Barbeiro',
                    border: OutlineInputBorder(),
                  ),
                  items: funcionarios
                      .map<DropdownMenuItem<String>>(
                        (f) => DropdownMenuItem<String>(
                          value: f['id'],
                          child: Text(f['nome']),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      funcionarioSelecionado = value;
                    });
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Dias da semana',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ...dias.map((dia) {
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(nomeDia(dia)),
                    value: diasSelecionados.contains(dia),
                    onChanged: (value) {
                      marcarDia(dia, value ?? false);
                    },
                  );
                }),
                const SizedBox(height: 20),
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
                    setState(() {
                      horaInicio = value;

                      if (horaFim != null && !horarioValido()) {
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
                    setState(() {
                      horaFim = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: salvando ? null : salvar,
                    child: salvando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Salvar'),
                  ),
                ),
              ],
            ),
    );
  }
}
