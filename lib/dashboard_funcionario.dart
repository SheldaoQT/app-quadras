import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardFuncionario extends StatefulWidget {
  const DashboardFuncionario({super.key});

  @override
  State<DashboardFuncionario> createState() => _DashboardFuncionarioState();
}

class _DashboardFuncionarioState extends State<DashboardFuncionario> {
  bool carregando = true;

  String nomeUsuario = '';

  int totalBarbeiros = 0;
  int totalServicos = 0;
  int totalHorarios = 0;
  int agendamentosHoje = 0;

  double receitaHoje = 0;

  String barbeiroDoMes = 'Nenhum';
  int atendimentosBarbeiroMes = 0;

  String servicoMaisVendido = 'Nenhum';
  int quantidadeServicoMaisVendido = 0;

  List<dynamic> agendamentosHojeLista = [];

  @override
  void initState() {
    super.initState();
    carregarDashboard();
  }

  Future<void> carregarDashboard() async {
    setState(() {
      carregando = true;
    });

    final supabase = Supabase.instance.client;
    final usuario = supabase.auth.currentUser;

    String nomeLogado = '';

    if (usuario != null) {
      final dadosUsuario = await supabase.from('usuarios').select('nome').eq('id', usuario.id).maybeSingle();

      nomeLogado = dadosUsuario?['nome'] ?? '';
    }

    final agora = DateTime.now();

    final inicioHoje = DateTime(
      agora.year,
      agora.month,
      agora.day,
    );

    final fimHoje = DateTime(
      agora.year,
      agora.month,
      agora.day,
      23,
      59,
      59,
    );

    final inicioMes = DateTime(
      agora.year,
      agora.month,
      1,
    );

    final fimMes = DateTime(
      agora.year,
      agora.month + 1,
      0,
      23,
      59,
      59,
    );

    final barbeiros = await supabase.from('usuarios').select().eq('perfil', 'funcionario').eq('ativo', true);

    final servicos = await supabase.from('servicos').select();

    final horarios = await supabase.from('horarios').select();

    final agendamentosHojeResposta = await supabase
        .from('agendamentos')
        .select('''
          *,
          servicos(*),
          cliente:usuarios!agendamentos_cliente_id_fkey(*),
          barbeiro:usuarios!agendamentos_barbeiro_id_fkey(*)
        ''')
        .gte('data_hora', inicioHoje.toIso8601String())
        .lte(
          'data_hora',
          fimHoje.toIso8601String(),
        )
        .order('data_hora');

    final agendamentosMes = await supabase
        .from('agendamentos')
        .select('''
          *,
          servicos(*),
          barbeiro:usuarios!agendamentos_barbeiro_id_fkey(*)
        ''')
        .eq('status', 'concluido')
        .gte(
          'data_hora',
          inicioMes.toIso8601String(),
        )
        .lte(
          'data_hora',
          fimMes.toIso8601String(),
        );

    double totalDia = 0;

    for (final agendamento in agendamentosHojeResposta) {
      if (agendamento['status'] == 'concluido') {
        final servico = agendamento['servicos'];

        if (servico != null && servico['preco'] != null) {
          totalDia += double.parse(servico['preco'].toString());
        }
      }
    }

    final Map<String, int> atendimentosPorBarbeiro = {};
    final Map<String, int> servicosVendidos = {};

    for (final agendamento in agendamentosMes) {
      final barbeiro = agendamento['barbeiro'];
      final servico = agendamento['servicos'];

      final nomeBarbeiro = barbeiro?['nome'] ?? 'Sem barbeiro';
      final nomeServico = servico?['nome'] ?? 'Serviço';

      atendimentosPorBarbeiro[nomeBarbeiro] = (atendimentosPorBarbeiro[nomeBarbeiro] ?? 0) + 1;

      servicosVendidos[nomeServico] = (servicosVendidos[nomeServico] ?? 0) + 1;
    }

    String melhorBarbeiro = 'Nenhum';
    int maiorAtendimentos = 0;

    atendimentosPorBarbeiro.forEach((nome, quantidade) {
      if (quantidade > maiorAtendimentos) {
        melhorBarbeiro = nome;
        maiorAtendimentos = quantidade;
      }
    });

    String melhorServico = 'Nenhum';
    int maiorServico = 0;

    servicosVendidos.forEach((nome, quantidade) {
      if (quantidade > maiorServico) {
        melhorServico = nome;
        maiorServico = quantidade;
      }
    });

    if (!mounted) return;

    setState(() {
      nomeUsuario = nomeLogado;

      totalBarbeiros = barbeiros.length;
      totalServicos = servicos.length;
      totalHorarios = horarios.length;
      agendamentosHoje = agendamentosHojeResposta.length;
      receitaHoje = totalDia;

      barbeiroDoMes = melhorBarbeiro;
      atendimentosBarbeiroMes = maiorAtendimentos;

      servicoMaisVendido = melhorServico;
      quantidadeServicoMaisVendido = maiorServico;

      agendamentosHojeLista = agendamentosHojeResposta.take(5).toList();

      carregando = false;
    });
  }

  String dinheiro(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
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

  String saudacao() {
    final hora = DateTime.now().hour;

    if (hora < 12) {
      return 'Bom dia';
    }

    if (hora < 18) {
      return 'Boa tarde';
    }

    return 'Boa noite';
  }

  String textoSaudacao() {
    if (nomeUsuario.trim().isEmpty) {
      return saudacao();
    }

    return '${saudacao()}, $nomeUsuario';
  }

  Widget cardResumo({
    required IconData icon,
    required String titulo,
    required String valor,
  }) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 34,
                color: Colors.brown,
              ),
              const SizedBox(height: 8),
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                titulo,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget cardDestaque({
    required IconData icon,
    required String titulo,
    required String principal,
    required String subtitulo,
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
        title: Text(titulo),
        subtitle: Text(
          principal,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Text(subtitulo),
      ),
    );
  }

  Widget cardAgendamento(Map agendamento) {
    final data = DateTime.parse(agendamento['data_hora']);

    final cliente = agendamento['cliente'];
    final barbeiro = agendamento['barbeiro'];
    final servico = agendamento['servicos'];
    final status = agendamento['status'] ?? 'pendente';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: corStatus(status),
          child: Text(
            DateFormat('HH:mm').format(data),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          cliente?['nome'] ?? 'Cliente',
        ),
        subtitle: Text(
          '${servico?['nome'] ?? 'Serviço'} • ${barbeiro?['nome'] ?? 'Barbeiro'}',
        ),
        trailing: Text(textoStatus(status)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final dataHoje = DateFormat('dd/MM/yyyy').format(DateTime.now());

    return RefreshIndicator(
      onRefresh: carregarDashboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            textoSaudacao(),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Resumo da Barbearia FM em $dataHoje',
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              cardResumo(
                icon: Icons.people,
                titulo: 'Barbeiros',
                valor: totalBarbeiros.toString(),
              ),
              cardResumo(
                icon: Icons.content_cut,
                titulo: 'Serviços',
                valor: totalServicos.toString(),
              ),
            ],
          ),
          Row(
            children: [
              cardResumo(
                icon: Icons.calendar_month,
                titulo: 'Hoje',
                valor: agendamentosHoje.toString(),
              ),
              cardResumo(
                icon: Icons.access_time,
                titulo: 'Horários',
                valor: totalHorarios.toString(),
              ),
            ],
          ),
          Card(
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: const Icon(
                  Icons.attach_money,
                  color: Colors.green,
                ),
              ),
              title: const Text('Receita de hoje'),
              subtitle: Text(
                dinheiro(receitaHoje),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          cardDestaque(
            icon: Icons.emoji_events,
            titulo: 'Barbeiro do mês',
            principal: barbeiroDoMes,
            subtitulo: '$atendimentosBarbeiroMes atend.',
          ),
          cardDestaque(
            icon: Icons.star,
            titulo: 'Serviço mais vendido',
            principal: servicoMaisVendido,
            subtitulo: '$quantidadeServicoMaisVendido vendas',
          ),
          const SizedBox(height: 20),
          const Text(
            'Agendamentos de hoje',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (agendamentosHojeLista.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nenhum agendamento para hoje'),
              ),
            )
          else
            ...agendamentosHojeLista.map(
              (agendamento) => cardAgendamento(agendamento),
            ),
        ],
      ),
    );
  }
}
