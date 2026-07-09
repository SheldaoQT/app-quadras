import 'package:app_barba/cadastro_agendamento.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MeusAgendamentos extends StatefulWidget {
  const MeusAgendamentos({super.key});

  @override
  State<MeusAgendamentos> createState() => _MeusAgendamentosState();
}

class _MeusAgendamentosState extends State<MeusAgendamentos> {
  bool carregando = true;

  List<dynamic> lista = [];

  @override
  void initState() {
    super.initState();
    buscar();
  }

  Future<void> buscar() async {
    try {
      final supabase = Supabase.instance.client;
      final usuario = supabase.auth.currentUser;

      if (usuario == null) {
        return;
      }

      final resposta = await supabase.from('agendamentos').select('''
            *,
            servicos(*),
            barbeiro:usuarios!agendamentos_barbeiro_id_fkey(*)
          ''').eq('cliente_id', usuario.id).order('data_hora', ascending: false);

      if (!mounted) return;

      setState(() {
        lista = resposta;
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

  Future<void> cancelar(int id) async {
    await Supabase.instance.client.from('agendamentos').update({
      'status': 'cancelado',
    }).eq('id', id);

    await buscar();
  }

  Future<void> confirmarCancelamento(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancelar agendamento'),
          content: const Text(
            'Deseja realmente cancelar este agendamento?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Não'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Sim, cancelar'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      await cancelar(id);
    }
  }

  Color corStatus(String status) {
    if (status == 'concluido') {
      return Colors.green;
    }

    if (status == 'cancelado') {
      return Colors.red;
    }

    return Colors.orange;
  }

  String textoStatus(String status) {
    if (status == 'concluido') {
      return 'Concluído';
    }

    if (status == 'cancelado') {
      return 'Cancelado';
    }

    return 'Pendente';
  }

  bool podeCancelar(Map agendamento) {
    final status = agendamento['status'] ?? 'pendente';
    final data = DateTime.parse(agendamento['data_hora']);

    return status == 'pendente' && data.isAfter(DateTime.now());
  }

  Widget item(Map agendamento) {
    final data = DateTime.parse(
      agendamento['data_hora'],
    );

    final servico = agendamento['servicos'];
    final barbeiro = agendamento['barbeiro'];
    final status = agendamento['status'] ?? 'pendente';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: corStatus(status),
          child: const Icon(
            Icons.calendar_month,
            color: Colors.white,
          ),
        ),
        title: Text(
          servico?['nome'] ?? 'Serviço',
        ),
        subtitle: Text(
          '''
Barbeiro: ${barbeiro?['nome'] ?? 'Não informado'}
Data: ${DateFormat('dd/MM/yyyy HH:mm').format(data)}
Status: ${textoStatus(status)}
''',
        ),
        trailing: podeCancelar(agendamento)
            ? IconButton(
                tooltip: 'Cancelar agendamento',
                icon: const Icon(
                  Icons.cancel,
                  color: Colors.red,
                ),
                onPressed: () {
                  confirmarCancelamento(
                    agendamento['id'],
                  );
                },
              )
            : null,
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Agendamentos'),
      ),
      body: carregando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : lista.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum agendamento',
                  ),
                )
              : RefreshIndicator(
                  onRefresh: buscar,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: lista.length,
                    itemBuilder: (context, index) {
                      return item(lista[index]);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Novo agendamento'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CadastroAgendamento(),
            ),
          );

          await buscar();
        },
      ),
    );
  }
}
