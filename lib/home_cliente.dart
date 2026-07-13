import 'package:app_barba/cadastro_agendamento.dart';
import 'package:app_barba/meus_agendamentos.dart';
import 'package:app_barba/login.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeCliente extends StatefulWidget {
  const HomeCliente({super.key});

  @override
  State<HomeCliente> createState() => _HomeClienteState();
}

class _HomeClienteState extends State<HomeCliente> {
  bool carregando = true;

  String nomeCliente = '';
  List<dynamic> agendamentosPendentes = [];

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    final supabase = Supabase.instance.client;
    final usuario = supabase.auth.currentUser;

    if (usuario == null) return;

    final dadosUsuario = await supabase.from('usuarios').select().eq('id', usuario.id).single();

    final agora = DateTime.now();

    final agendamentos = await supabase
        .from('agendamentos')
        .select()
        .eq('cliente_id', usuario.id)
        .eq('status', 'pendente')
        .gte('data_hora', agora.toIso8601String())
        .order('data_hora');

    if (!mounted) return;

    setState(() {
      nomeCliente = dadosUsuario['nome'] ?? '';
      agendamentosPendentes = agendamentos;
      carregando = false;
    });
  }

  Future<void> sair() async {
    await Supabase.instance.client.auth.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const TelaLogin(),
      ),
      (route) => false,
    );
  }

  Future<void> cancelarAgendamento(Map agendamento) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancelar atendimento'),
          content: const Text(
            'Deseja realmente cancelar este atendimento?',
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

    if (confirmar != true) return;

    await Supabase.instance.client.from('agendamentos').update({
      'status': 'cancelado',
    }).eq('id', agendamento['id']);

    await carregarDados();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Atendimento cancelado'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget botaoMenu({
    required IconData icon,
    required String titulo,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.brown.shade100,
          child: Icon(
            icon,
            color: Colors.brown,
          ),
        ),
        title: Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  Widget listaAtendimentosPendentes() {
    if (agendamentosPendentes.isEmpty) {
      return Card(
        elevation: 2,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.orange.shade100,
            child: const Icon(
              Icons.event_busy,
              color: Colors.orange,
            ),
          ),
          title: const Text('Nenhum atendimento pendente'),
          subtitle: const Text('Clique em Agendar para marcar um horário.'),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Atendimentos pendentes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            ...agendamentosPendentes.map((agendamento) {
              final data = DateTime.parse(
                agendamento['data_hora'],
              );

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.brown.shade100,
                  child: const Icon(
                    Icons.event,
                    color: Colors.brown,
                  ),
                ),
                title: Text(
                  DateFormat('dd/MM/yyyy').format(data),
                ),
                subtitle: Text(
                  DateFormat('HH:mm').format(data),
                ),
                trailing: IconButton(
                  tooltip: 'Cancelar atendimento',
                  icon: const Icon(
                    Icons.cancel,
                    color: Colors.red,
                  ),
                  onPressed: () {
                    cancelarAgendamento(agendamento);
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Área do Cliente'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
            onPressed: carregarDados,
          ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: sair,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: carregarDados,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Olá, $nomeCliente',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Bem-vindo à Barbearia FM',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            listaAtendimentosPendentes(),
            const SizedBox(height: 20),
            botaoMenu(
              icon: Icons.add_circle,
              titulo: 'Agendar horário',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CadastroAgendamento(),
                  ),
                );

                await carregarDados();
              },
            ),
            botaoMenu(
              icon: Icons.calendar_month,
              titulo: 'Histórico de Agendamentos',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MeusAgendamentos(),
                  ),
                );

                await carregarDados();
              },
            ),
          ],
        ),
      ),
    );
  }
}
