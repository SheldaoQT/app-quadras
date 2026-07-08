import 'package:app_barba/cadastro_agendamento.dart';
import 'package:app_barba/meus_agendamentos.dart';
import 'package:app_barba/tela_profissionais.dart';
import 'package:app_barba/tela_servico.dart';

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
  Map? proximoAgendamento;

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

    final agendamentos = await supabase.from('agendamentos').select('''
          *,
          servicos(*),
          barbeiro:usuarios!agendamentos_barbeiro_id_fkey(*)
        ''').eq('cliente_id', usuario.id).neq('status', 'cancelado').gte('data_hora', agora.toIso8601String()).order('data_hora').limit(1);

    if (!mounted) return;

    setState(() {
      nomeCliente = dadosUsuario['nome'] ?? '';
      proximoAgendamento = agendamentos.isNotEmpty ? agendamentos.first : null;
      carregando = false;
    });
  }

  Future<void> sair() async {
    await Supabase.instance.client.auth.signOut();

    if (!mounted) return;

    Navigator.popUntil(
      context,
      (route) => route.isFirst,
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

  Widget cardProximoAgendamento() {
    if (proximoAgendamento == null) {
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
          title: const Text('Nenhum agendamento futuro'),
          subtitle: const Text('Clique em Agendar para marcar um horário.'),
        ),
      );
    }

    final data = DateTime.parse(
      proximoAgendamento!['data_hora'],
    );

    final servico = proximoAgendamento!['servicos'];
    final barbeiro = proximoAgendamento!['barbeiro'];

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Próximo atendimento',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_month),
                const SizedBox(width: 8),
                Text(DateFormat('dd/MM/yyyy').format(data)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time),
                const SizedBox(width: 8),
                Text(DateFormat('HH:mm').format(data)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person),
                const SizedBox(width: 8),
                Text(barbeiro?['nome'] ?? 'Barbeiro não informado'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.content_cut),
                const SizedBox(width: 8),
                Text(servico?['nome'] ?? 'Serviço não informado'),
              ],
            ),
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
              'Olá, $nomeCliente 👋',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Bem-vindo à Barbearia',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            cardProximoAgendamento(),
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
              titulo: 'Meus Agendamentos',
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
            botaoMenu(
              icon: Icons.people,
              titulo: 'Barbeiros',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TelaProfissionais(),
                  ),
                );
              },
            ),
            botaoMenu(
              icon: Icons.content_cut,
              titulo: 'Serviços',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TelaServicos(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
