import 'package:app_barba/dashboard_funcionario.dart';
import 'package:app_barba/tela_agendamentos.dart';
import 'package:app_barba/tela_barbeiros.dart';
import 'package:app_barba/tela_comissao.dart';
import 'package:app_barba/tela_horarios.dart';
import 'package:app_barba/tela_servico.dart';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeFuncionario extends StatelessWidget {
  const HomeFuncionario({
    super.key,
  });

  Future<void> sair(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();

    if (!context.mounted) {
      return;
    }

    Navigator.popUntil(
      context,
      (route) => route.isFirst,
    );
  }

  Widget cabecalhoMenu() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      decoration: BoxDecoration(
        color: Colors.brown.shade600,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.content_cut,
              size: 34,
              color: Colors.brown.shade600,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Barbearia',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Painel Administrativo',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget itemMenu({
    required BuildContext context,
    required IconData icon,
    required String titulo,
    required Widget tela,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(titulo),
      onTap: () {
        Navigator.pop(context);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => tela,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Painel Administrativo',
        ),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            cabecalhoMenu(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.dashboard),
                    title: const Text('Dashboard'),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  itemMenu(
                    context: context,
                    icon: Icons.people,
                    titulo: 'Barbeiros',
                    tela: const TelaBarbeiros(),
                  ),
                  itemMenu(
                    context: context,
                    icon: Icons.content_cut,
                    titulo: 'Serviços',
                    tela: const TelaServicos(),
                  ),
                  itemMenu(
                    context: context,
                    icon: Icons.access_time,
                    titulo: 'Horários',
                    tela: const TelaHorarios(),
                  ),
                  itemMenu(
                    context: context,
                    icon: Icons.calendar_month,
                    titulo: 'Agendamentos',
                    tela: const TelaAgendamentos(),
                  ),
                  itemMenu(
                    context: context,
                    icon: Icons.attach_money,
                    titulo: 'Comissão',
                    tela: const TelaComissao(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            SafeArea(
              top: false,
              child: ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sair'),
                onTap: () {
                  sair(context);
                },
              ),
            ),
          ],
        ),
      ),
      body: const DashboardFuncionario(),
    );
  }
}
