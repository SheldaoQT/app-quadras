import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

class TelaAgendamentos extends StatefulWidget {
  const TelaAgendamentos({super.key});

  @override
  State<TelaAgendamentos> createState() => _TelaAgendamentosState();
}

class _TelaAgendamentosState extends State<TelaAgendamentos> {
  bool carregando = true;

  DateTime dataSelecionada = DateTime.now();
  DateTime dataFocada = DateTime.now();

  List<dynamic> agendamentos = [];
  Set<String> diasComAgendamentoPendente = {};

  String? usuarioLogadoId;
  String perfilUsuario = '';

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    setState(() {
      carregando = true;
    });

    await carregarUsuarioLogado();
    await buscarDiasComAgendamentoPendente();
    await buscarAgendamentos();
  }

  Future<void> carregarUsuarioLogado() async {
    final usuario = Supabase.instance.client.auth.currentUser;

    if (usuario == null) return;

    usuarioLogadoId = usuario.id;

    final dados = await Supabase.instance.client.from('usuarios').select('perfil').eq('id', usuario.id).single();

    perfilUsuario = dados['perfil'].toString().toLowerCase().trim();
  }

  bool get usuarioAdmin {
    return perfilUsuario.contains('admin');
  }

  DateTime inicioDoDia(DateTime data) {
    return DateTime(data.year, data.month, data.day);
  }

  DateTime fimDoDia(DateTime data) {
    return DateTime(data.year, data.month, data.day, 23, 59, 59);
  }

  DateTime inicioDoMes(DateTime data) {
    return DateTime(data.year, data.month, 1);
  }

  DateTime fimDoMes(DateTime data) {
    return DateTime(data.year, data.month + 1, 0, 23, 59, 59);
  }

  String chaveDia(DateTime data) {
    return DateFormat('yyyy-MM-dd').format(data);
  }

  bool mesmoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool diaJaPassou(DateTime data) {
    final hoje = DateTime.now();
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
    final dataSemHora = DateTime(data.year, data.month, data.day);

    return dataSemHora.isBefore(hojeSemHora);
  }

  bool podeAlterarAgendamento(Map agendamento) {
    if (usuarioAdmin) {
      return true;
    }

    return agendamento['barbeiro_id'] == usuarioLogadoId;
  }

  Future<void> buscarDiasComAgendamentoPendente() async {
    try {
      final inicio = inicioDoMes(dataFocada);
      final fim = fimDoMes(dataFocada);

      var consulta = Supabase.instance.client
          .from('agendamentos')
          .select('data_hora')
          .eq('status', 'pendente')
          .gte('data_hora', inicio.toIso8601String())
          .lte('data_hora', fim.toIso8601String());

      if (!usuarioAdmin && usuarioLogadoId != null) {
        consulta = consulta.eq('barbeiro_id', usuarioLogadoId!);
      }

      final resposta = await consulta;

      final Set<String> dias = {};

      for (final item in resposta) {
        final data = DateTime.parse(item['data_hora']);

        if (!diaJaPassou(data)) {
          dias.add(chaveDia(data));
        }
      }

      if (!mounted) return;

      setState(() {
        diasComAgendamentoPendente = dias;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao buscar dias com agendamento: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> buscarAgendamentos() async {
    try {
      final inicio = inicioDoDia(dataSelecionada);
      final fim = fimDoDia(dataSelecionada);

      var consulta = Supabase.instance.client.from('agendamentos').select('''
            *,
            servicos(*),
            cliente:usuarios!agendamentos_cliente_id_fkey(*),
            barbeiro:usuarios!agendamentos_barbeiro_id_fkey(*)
          ''').gte('data_hora', inicio.toIso8601String()).lte('data_hora', fim.toIso8601String());

      if (!usuarioAdmin && usuarioLogadoId != null) {
        consulta = consulta.eq('barbeiro_id', usuarioLogadoId!);
      }

      final resposta = await consulta.order('data_hora');

      if (!mounted) return;

      setState(() {
        agendamentos = resposta;
        carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        carregando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> concluirAgendamento(Map agendamento) async {
    if (!podeAlterarAgendamento(agendamento)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você não pode alterar agendamentos de outro barbeiro.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await Supabase.instance.client.from('agendamentos').update({
      'status': 'concluido',
    }).eq('id', agendamento['id']);

    await buscarDiasComAgendamentoPendente();
    await buscarAgendamentos();
  }

  Future<void> cancelarAgendamento(Map agendamento) async {
    if (!podeAlterarAgendamento(agendamento)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você não pode alterar agendamentos de outro barbeiro.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await Supabase.instance.client.from('agendamentos').update({
      'status': 'cancelado',
    }).eq('id', agendamento['id']);

    await buscarDiasComAgendamentoPendente();
    await buscarAgendamentos();
  }

  Map<String, List<dynamic>> agruparPorBarbeiro() {
    final Map<String, List<dynamic>> agrupados = {};

    for (final agendamento in agendamentos) {
      final barbeiro = agendamento['barbeiro'];
      final nome = barbeiro?['nome'] ?? 'Sem barbeiro';

      if (!agrupados.containsKey(nome)) {
        agrupados[nome] = [];
      }

      agrupados[nome]!.add(agendamento);
    }

    return agrupados;
  }

  Color corStatus(String status) {
    switch (status) {
      case 'concluido':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String textoStatus(String status) {
    switch (status) {
      case 'concluido':
        return 'Concluído';
      case 'cancelado':
        return 'Cancelado';
      default:
        return 'Pendente';
    }
  }

  Widget diaCalendario({
    required DateTime dia,
    required Color? cor,
    required Color corTexto,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return Center(
      child: Container(
        width: 36,
        height: 36,
        decoration: cor == null
            ? null
            : BoxDecoration(
                color: cor,
                shape: BoxShape.circle,
              ),
        alignment: Alignment.center,
        child: Text(
          '${dia.day}',
          style: TextStyle(
            color: corTexto,
            fontWeight: fontWeight,
          ),
        ),
      ),
    );
  }

  Widget? montarDiaCalendario(DateTime dia) {
    final passou = diaJaPassou(dia);
    final temPendente = diasComAgendamentoPendente.contains(chaveDia(dia));

    if (passou) {
      return diaCalendario(
        dia: dia,
        cor: null,
        corTexto: Colors.grey,
      );
    }

    if (temPendente) {
      return diaCalendario(
        dia: dia,
        cor: Colors.green,
        corTexto: Colors.white,
        fontWeight: FontWeight.bold,
      );
    }

    return null;
  }

  Widget calendarioAgendamentos() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: TableCalendar(
        locale: 'pt_BR',
        firstDay: DateTime(2024),
        lastDay: DateTime(2100),
        focusedDay: dataFocada,
        selectedDayPredicate: (day) {
          return mesmoDia(day, dataSelecionada);
        },
        calendarFormat: CalendarFormat.month,
        availableCalendarFormats: const {
          CalendarFormat.month: 'Mês',
        },
        headerStyle: const HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Colors.brown.shade200,
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Colors.brown.shade700,
            shape: BoxShape.circle,
          ),
          outsideTextStyle: const TextStyle(
            color: Colors.grey,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            return montarDiaCalendario(day);
          },
          outsideBuilder: (context, day, focusedDay) {
            return diaCalendario(
              dia: day,
              cor: null,
              corTexto: Colors.grey,
            );
          },
          todayBuilder: (context, day, focusedDay) {
            final temPendente = diasComAgendamentoPendente.contains(chaveDia(day));

            if (temPendente) {
              return diaCalendario(
                dia: day,
                cor: Colors.green,
                corTexto: Colors.white,
                fontWeight: FontWeight.bold,
              );
            }

            return diaCalendario(
              dia: day,
              cor: Colors.brown.shade200,
              corTexto: Colors.white,
              fontWeight: FontWeight.bold,
            );
          },
          selectedBuilder: (context, day, focusedDay) {
            return diaCalendario(
              dia: day,
              cor: Colors.brown.shade700,
              corTexto: Colors.white,
              fontWeight: FontWeight.bold,
            );
          },
        ),
        onDaySelected: (selectedDay, focusedDay) async {
          setState(() {
            dataSelecionada = selectedDay;
            dataFocada = focusedDay;
            carregando = true;
          });

          await buscarAgendamentos();
        },
        onPageChanged: (focusedDay) async {
          setState(() {
            dataFocada = focusedDay;
          });

          await buscarDiasComAgendamentoPendente();
        },
      ),
    );
  }

  Widget cardAgendamento(Map agendamento) {
    final data = DateTime.parse(agendamento['data_hora']);
    final servico = agendamento['servicos'];
    final cliente = agendamento['cliente'];
    final status = agendamento['status'] ?? 'pendente';
    final podeAlterar = podeAlterarAgendamento(agendamento);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            DateFormat('HH:mm').format(data),
            style: const TextStyle(fontSize: 12),
          ),
        ),
        title: Text(
          cliente?['nome'] ?? 'Cliente',
        ),
        subtitle: Text(
          '''
Serviço: ${servico?['nome'] ?? 'Serviço'}
Status: ${textoStatus(status)}
''',
        ),
        trailing: status == 'pendente' && podeAlterar
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Concluir',
                    icon: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                    onPressed: () {
                      concluirAgendamento(agendamento);
                    },
                  ),
                  IconButton(
                    tooltip: 'Cancelar',
                    icon: const Icon(
                      Icons.cancel,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      cancelarAgendamento(agendamento);
                    },
                  ),
                ],
              )
            : Icon(
                Icons.circle,
                color: corStatus(status),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final agrupados = agruparPorBarbeiro();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendamentos'),
      ),
      body: Column(
        children: [
          calendarioAgendamentos(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListTile(
              leading: const Icon(Icons.today),
              title: const Text('Data selecionada'),
              subtitle: Text(
                DateFormat('dd/MM/yyyy').format(dataSelecionada),
              ),
            ),
          ),
          Expanded(
            child: carregando
                ? const Center(child: CircularProgressIndicator())
                : agendamentos.isEmpty
                    ? const Center(
                        child: Text('Nenhum agendamento neste dia'),
                      )
                    : RefreshIndicator(
                        onRefresh: carregarDados,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: agrupados.entries.map((entry) {
                            final nomeBarbeiro = entry.key;
                            final lista = entry.value;

                            return Card(
                              child: ExpansionTile(
                                initiallyExpanded: true,
                                leading: const Icon(Icons.person),
                                title: Text(nomeBarbeiro),
                                subtitle: Text(
                                  '${lista.length} agendamento(s)',
                                ),
                                children: lista.map((agendamento) {
                                  return cardAgendamento(agendamento);
                                }).toList(),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
