import 'package:app_barba/tela_servico.dart';
import 'package:app_barba/meus_agendamentos.dart';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeFuncionario extends StatelessWidget {
  const HomeFuncionario({
    super.key,
  });

  Future<void> sair(
    BuildContext context,
  ) async {
    await Supabase.instance.client.auth.signOut();

    if (!context.mounted) {
      return;
    }

    Navigator.popUntil(
      context,
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Painel Administrativo',
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Barbearia',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    'Administrador',
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.content_cut,
              ),
              title: const Text(
                'Serviços',
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TelaServicos(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.calendar_month,
              ),
              title: const Text(
                'Agendamentos',
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MeusAgendamentos(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.logout,
              ),
              title: const Text(
                'Sair',
              ),
              onTap: () {
                sair(
                  context,
                );
              },
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text(
          'Bem-vindo ao painel administrativo',
        ),
      ),
    );
  }
}
