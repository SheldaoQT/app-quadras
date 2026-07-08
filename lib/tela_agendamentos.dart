import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TelaAgendamentos extends StatefulWidget {
  const TelaAgendamentos({super.key});

  @override
  State<TelaAgendamentos> createState() => _TelaAgendamentosState();
}

class _TelaAgendamentosState extends State<TelaAgendamentos> {
  bool carregando = true;

  DateTime dataSelecionada = DateTime.now();

  List<dynamic> agendamentos = [];

  @override
  void initState() {
    super.initState();
    buscarAgendamentos();
  }

  DateTime inicioDoDia(DateTime data) {
    return DateTime(data.year, data.month, data.day);
  }

  DateTime fimDoDia(DateTime data) {
    return DateTime(data.year, data.month, data.day, 23, 59, 59);
  }

  Future<void> selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: dataSelecionada,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (data == null) return;

    setState(() {
      dataSelecionada = data;
      carregando = true;
    });

    await buscarAgendamentos();
  }

  Future<void> buscarAgendamentos() async {
    try {
      final inicio = inicioDoDia(dataSelecionada);
      final fim = fimDoDia(dataSelecionada);

      final resposta = await Supabase.instance.client.from('agendamentos').select('''
            *,
            servicos(*),
            cliente:usuarios!agendamentos_cliente_id_fkey(*),
            barbeiro:usuarios!agendamentos_barbeiro_id_fkey(*)
          ''').gte('data_hora', inicio.toIso8601String()).lte('data_hora', fim.toIso8601String()).order('data_hora');

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

  Future<void> concluirAgendamento(int id) async {
    await Supabase.instance.client.from('agendamentos').update({
      'status': 'concluido',
    }).eq('id', id);

    await buscarAgendamentos();
  }

  Future<void> cancelarAgendamento(int id) async {
    await Supabase.instance.client.from('agendamentos').update({
      'status': 'cancelado',
    }).eq('id', id);

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

  Widget cardAgendamento(Map agendamento) {
    final data = DateTime.parse(agendamento['data_hora']);

    final servico = agendamento['servicos'];
    final cliente = agendamento['cliente'];

    final status = agendamento['status'] ?? 'pendente';

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
Status: $status
''',
        ),
        trailing: status == 'pendente'
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
                      concluirAgendamento(
                        agendamento['id'],
                      );
                    },
                  ),
                  IconButton(
                    tooltip: 'Cancelar',
                    icon: const Icon(
                      Icons.cancel,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      cancelarAgendamento(
                        agendamento['id'],
                      );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: selecionarData,
          ),
        ],
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.today),
                      title: const Text('Data selecionada'),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy').format(dataSelecionada),
                      ),
                      trailing: const Icon(Icons.edit_calendar),
                      onTap: selecionarData,
                    ),
                  ),
                ),
                Expanded(
                  child: agendamentos.isEmpty
                      ? const Center(
                          child: Text('Nenhum agendamento neste dia'),
                        )
                      : RefreshIndicator(
                          onRefresh: buscarAgendamentos,
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
