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
            funcionario:usuarios!agendamentos_funcionario_id_fkey(*)
          ''').eq('cliente_id', usuario.id).neq('status', 'cancelado').order('data_hora');

      if (!mounted) return;

      setState(() {
        lista = resposta;
        carregando = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        carregando = false;
      });
    }
  }

  Future<void> cancelar(int id) async {
    await Supabase.instance.client.from('agendamentos').update({
      'status': 'cancelado',
    }).eq('id', id);

    await buscar();
  }

  Widget item(Map agendamento) {
    final data = DateTime.parse(
      agendamento['data_hora'],
    );

    final servico = agendamento['servicos'];
    final funcionario = agendamento['funcionario'];

    return Card(
      child: ListTile(
        leading: const Icon(
          Icons.calendar_month,
        ),
        title: Text(
          servico?['nome'] ?? 'Serviço',
        ),
        subtitle: Text(
          '''
funcionario: ${funcionario?['nome'] ?? 'Não informado'}
${DateFormat('dd/MM/yyyy HH:mm').format(data)}
Status: ${agendamento['status']}
''',
        ),
        trailing: agendamento['status'] == 'pendente'
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
        title: const Text(
          'Meus Agendamentos',
        ),
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
                    itemCount: lista.length,
                    itemBuilder: (context, index) {
                      return item(
                        lista[index],
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(
          Icons.add,
        ),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CadastroAgendamento(),
            ),
          );

          buscar();
        },
      ),
    );
  }
}
