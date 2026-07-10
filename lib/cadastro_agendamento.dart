import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CadastroAgendamento extends StatefulWidget {
  const CadastroAgendamento({super.key});

  @override
  State<CadastroAgendamento> createState() => _CadastroAgendamentoState();
}

class _CadastroAgendamentoState extends State<CadastroAgendamento> {
  bool carregando = true;
  bool salvando = false;

  List<dynamic> barbeiros = [];
  List<dynamic> servicos = [];
  List<TimeOfDay> horariosDisponiveis = [];

  String? barbeiroSelecionado;
  int? servicoSelecionado;
  DateTime? dataSelecionada;
  TimeOfDay? horaSelecionada;

  @override
  void initState() {
    super.initState();
    buscarBarbeiros();
  }

  int diaSemanaBanco(DateTime data) {
    if (data.weekday == 7) {
      return 0;
    }

    return data.weekday;
  }

  Future<void> buscarBarbeiros() async {
    try {
      final resposta = await Supabase.instance.client.from('usuarios').select().eq('perfil', 'funcionario').eq('ativo', true).order('nome');

      if (!mounted) return;

      setState(() {
        barbeiros = resposta;
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

  Future<void> buscarServicosDoBarbeiro() async {
    if (barbeiroSelecionado == null) return;

    final resposta = await Supabase.instance.client.from('servicos').select().eq('barbeiro_id', barbeiroSelecionado!).eq('ativo', true).order('nome');

    if (!mounted) return;

    setState(() {
      servicos = resposta;
      servicoSelecionado = null;
    });
  }

  TimeOfDay converterHora(String hora) {
    final partes = hora.split(':');

    return TimeOfDay(
      hour: int.parse(partes[0]),
      minute: int.parse(partes[1]),
    );
  }

  DateTime juntarDataHora(DateTime data, TimeOfDay hora) {
    return DateTime(
      data.year,
      data.month,
      data.day,
      hora.hour,
      hora.minute,
    );
  }

  String textoHora(TimeOfDay hora) {
    final h = hora.hour.toString().padLeft(2, '0');
    final m = hora.minute.toString().padLeft(2, '0');

    return '$h:$m';
  }

  int duracaoServicoSelecionado() {
    final servico = servicos.where((s) => s['id'] == servicoSelecionado);

    if (servico.isEmpty) {
      return 30;
    }

    final duracao = servico.first['duracao'];

    if (duracao is int) {
      return duracao;
    }

    return int.tryParse(duracao.toString()) ?? 30;
  }

  bool horariosSobrepostos({
    required DateTime inicioA,
    required DateTime fimA,
    required DateTime inicioB,
    required DateTime fimB,
  }) {
    return inicioA.isBefore(fimB) && fimA.isAfter(inicioB);
  }

  Future<void> buscarHorariosDisponiveis() async {
    if (barbeiroSelecionado == null || servicoSelecionado == null || dataSelecionada == null) {
      return;
    }

    final dia = diaSemanaBanco(dataSelecionada!);
    final duracaoServico = duracaoServicoSelecionado();

    final horariosTrabalho =
        await Supabase.instance.client.from('horarios').select().eq('barbeiro_id', barbeiroSelecionado!).eq('dia_semana', dia).order('hora_inicio');

    if (horariosTrabalho.isEmpty) {
      if (!mounted) return;

      setState(() {
        horariosDisponiveis = [];
        horaSelecionada = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este barbeiro não trabalha neste dia'),
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    final inicioDia = DateTime(
      dataSelecionada!.year,
      dataSelecionada!.month,
      dataSelecionada!.day,
      0,
      0,
    );

    final fimDia = DateTime(
      dataSelecionada!.year,
      dataSelecionada!.month,
      dataSelecionada!.day,
      23,
      59,
    );

    final agendamentos = await Supabase.instance.client
        .from('agendamentos')
        .select('data_hora, servicos(duracao)')
        .eq('barbeiro_id', barbeiroSelecionado!)
        .neq('status', 'cancelado')
        .gte('data_hora', inicioDia.toIso8601String())
        .lte('data_hora', fimDia.toIso8601String());

    final Set<String> horariosUnicos = {};
    final List<TimeOfDay> lista = [];

    for (final horario in horariosTrabalho) {
      final inicioTrabalho = converterHora(horario['hora_inicio']);
      final fimTrabalho = converterHora(horario['hora_fim']);

      DateTime atual = juntarDataHora(dataSelecionada!, inicioTrabalho);
      final dataFimTrabalho = juntarDataHora(dataSelecionada!, fimTrabalho);

      while (atual.add(Duration(minutes: duracaoServico)).isAtSameMomentAs(
                dataFimTrabalho,
              ) ||
          atual.add(Duration(minutes: duracaoServico)).isBefore(
                dataFimTrabalho,
              )) {
        final fimAtendimento = atual.add(Duration(minutes: duracaoServico));

        bool ocupado = false;

        for (final agendamento in agendamentos) {
          final inicioAgendamento = DateTime.parse(agendamento['data_hora']);
          final servicoAgendamento = agendamento['servicos'];
          final duracaoAgendamento = int.tryParse('${servicoAgendamento?['duracao'] ?? 30}') ?? 30;
          final fimAgendamento = inicioAgendamento.add(
            Duration(minutes: duracaoAgendamento),
          );

          if (horariosSobrepostos(
            inicioA: atual,
            fimA: fimAtendimento,
            inicioB: inicioAgendamento,
            fimB: fimAgendamento,
          )) {
            ocupado = true;
            break;
          }
        }

        final chave = textoHora(
          TimeOfDay(hour: atual.hour, minute: atual.minute),
        );

        final horarioJaPassou = atual.isBefore(DateTime.now());

        if (!ocupado && !horarioJaPassou && !horariosUnicos.contains(chave)) {
          horariosUnicos.add(chave);

          lista.add(
            TimeOfDay(
              hour: atual.hour,
              minute: atual.minute,
            ),
          );
        }

        atual = atual.add(const Duration(minutes: 30));
      }
    }

    lista.sort((a, b) {
      if (a.hour != b.hour) {
        return a.hour.compareTo(b.hour);
      }

      return a.minute.compareTo(b.minute);
    });

    if (!mounted) return;

    setState(() {
      horariosDisponiveis = lista;
      horaSelecionada = null;
    });
  }

  Future<void> selecionarData() async {
    if (barbeiroSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um barbeiro primeiro'),
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    if (servicoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um serviço primeiro'),
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    final data = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (data == null) return;

    setState(() {
      dataSelecionada = data;
      horaSelecionada = null;
      horariosDisponiveis = [];
    });

    await buscarHorariosDisponiveis();
  }

  Future<bool> horarioAindaDisponivel(DateTime dataHora) async {
    await buscarHorariosDisponiveis();

    final existeNaLista = horariosDisponiveis.any((hora) {
      return hora.hour == dataHora.hour && hora.minute == dataHora.minute;
    });

    return existeNaLista;
  }

  Future<void> salvar() async {
    if (barbeiroSelecionado == null || servicoSelecionado == null || dataSelecionada == null || horaSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos'),
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    final usuario = Supabase.instance.client.auth.currentUser;

    if (usuario == null) return;

    final dataHora = juntarDataHora(
      dataSelecionada!,
      horaSelecionada!,
    );

    if (dataHora.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não é possível agendar em horário passado'),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    setState(() {
      salvando = true;
    });

    try {
      final disponivel = await horarioAindaDisponivel(dataHora);

      if (!disponivel) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Esse horário acabou de ser ocupado'),
            backgroundColor: Colors.orange,
          ),
        );

        return;
      }

      await Supabase.instance.client.from('agendamentos').insert({
        'cliente_id': usuario.id,
        'barbeiro_id': barbeiroSelecionado,
        'servico_id': servicoSelecionado,
        'data_hora': dataHora.toIso8601String(),
        'status': 'pendente',
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agendamento realizado'),
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
          content: Text('Erro ao realizar agendamento: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        salvando = false;
      });
    }
  }

  String nomeBarbeiroSelecionado() {
    final barbeiro = barbeiros.where(
      (b) => b['id'] == barbeiroSelecionado,
    );

    if (barbeiro.isEmpty) {
      return '';
    }

    return barbeiro.first['nome'] ?? '';
  }

  Widget cardHorario(TimeOfDay hora) {
    final selecionado = horaSelecionada?.hour == hora.hour && horaSelecionada?.minute == hora.minute;

    return Card(
      color: selecionado ? Colors.green.shade100 : null,
      child: ListTile(
        leading: Icon(
          selecionado ? Icons.check_circle : Icons.access_time,
          color: selecionado ? Colors.green : null,
        ),
        title: Text(
          textoHora(hora),
          style: TextStyle(
            fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          setState(() {
            horaSelecionada = hora;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Agendamento'),
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: barbeiroSelecionado,
                    decoration: const InputDecoration(
                      labelText: 'Barbeiro',
                      border: OutlineInputBorder(),
                    ),
                    items: barbeiros
                        .map<DropdownMenuItem<String>>(
                          (b) => DropdownMenuItem<String>(
                            value: b['id'],
                            child: Text(b['nome']),
                          ),
                        )
                        .toList(),
                    onChanged: (value) async {
                      setState(() {
                        barbeiroSelecionado = value;
                        servicos = [];
                        servicoSelecionado = null;
                        dataSelecionada = null;
                        horaSelecionada = null;
                        horariosDisponiveis = [];
                      });

                      await buscarServicosDoBarbeiro();
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: servicoSelecionado,
                    decoration: const InputDecoration(
                      labelText: 'Serviço',
                      border: OutlineInputBorder(),
                    ),
                    items: servicos
                        .map<DropdownMenuItem<int>>(
                          (s) => DropdownMenuItem<int>(
                            value: s['id'],
                            child: Text(
                              '${s['nome']} - R\$ ${s['preco']} - ${s['duracao']} min',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) async {
                      setState(() {
                        servicoSelecionado = value;
                        horaSelecionada = null;
                        horariosDisponiveis = [];
                      });

                      if (dataSelecionada != null) {
                        await buscarHorariosDisponiveis();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        dataSelecionada == null
                            ? 'Selecionar data'
                            : DateFormat('dd/MM/yyyy').format(
                                dataSelecionada!,
                              ),
                      ),
                      onPressed: selecionarData,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (dataSelecionada != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${nomeBarbeiroSelecionado()} - ${DateFormat('dd/MM/yyyy').format(dataSelecionada!)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (dataSelecionada != null)
                    Expanded(
                      child: horariosDisponiveis.isEmpty
                          ? const Center(
                              child: Text(
                                'Nenhum horário disponível para este dia',
                              ),
                            )
                          : ListView.builder(
                              itemCount: horariosDisponiveis.length,
                              itemBuilder: (context, index) {
                                return cardHorario(
                                  horariosDisponiveis[index],
                                );
                              },
                            ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: salvando ? null : salvar,
                      child: salvando ? const CircularProgressIndicator() : const Text('Confirmar Agendamento'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
