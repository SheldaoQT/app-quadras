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
  bool mostrarCancelados = false;

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

      var consulta = supabase.from('agendamentos').select('''
            *,
            servicos(*),
            barbeiro:usuarios!agendamentos_barbeiro_id_fkey(*)
          ''').eq('cliente_id', usuario.id);

      if (!mostrarCancelados) {
        consulta = consulta.neq('status', 'cancelado');
      }

      final resposta = await consulta.order('data_hora');

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

  Future<void> limparCancelados() async {
    final usuario = Supabase.instance.client.auth.currentUser;

    if (usuario == null) return;

    await Supabase.instance.client.from('agendamentos').delete().eq('cliente_id', usuario.id).eq('status', 'cancelado');

    await buscar();
  }

  Future<void> confirmarLimparCancelados() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Limpar cancelados'),
          content: const Text(
            'Deseja excluir todos os agendamentos cancelados?',
          ),
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
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      await limparCancelados();
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
Status: $status
''',
        ),
        trailing: status == 'pendente'
            ? IconButton(
                icon: const Icon(
                  Icons.cancel,
                  color: Colors.red,
                ),
                onPressed: () {
                  cancelar(
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
        title: const Text('Meus Agendamentos'),
        actions: [
          IconButton(
            tooltip: mostrarCancelados ? 'Ocultar cancelados' : 'Mostrar cancelados',
            icon: Icon(
              mostrarCancelados ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: () async {
              setState(() {
                mostrarCancelados = !mostrarCancelados;
                carregando = true;
              });

              await buscar();
            },
          ),
          IconButton(
            tooltip: 'Limpar cancelados',
            icon: const Icon(Icons.delete_sweep),
            onPressed: confirmarLimparCancelados,
          ),
        ],
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
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
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
