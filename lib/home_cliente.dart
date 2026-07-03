import 'package:app_barba/meus_agendamentos.dart';
import 'package:app_barba/tela_profissionais.dart';
import 'package:app_barba/tela_servico.dart';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeCliente extends StatelessWidget {
  const HomeCliente({
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
          'Área do Cliente',
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
                    'Cliente',
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.calendar_month,
              ),
              title: const Text(
                'Meus Agendamentos',
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
            ListTile(
              leading: const Icon(
                Icons.people,
              ),
              title: const Text(
                'Profissionais',
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TelaProfissionais(),
                  ),
                );
              },
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(
            16,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.content_cut,
                size: 80,
              ),
              const SizedBox(
                height: 20,
              ),
              const Text(
                'Bem-vindo à Barbearia',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              SizedBox(
                width: 300,
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.calendar_month,
                  ),
                  label: const Text(
                    'Meus Agendamentos',
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MeusAgendamentos(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              SizedBox(
                width: 300,
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.people,
                  ),
                  label: const Text(
                    'Profissionais',
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TelaProfissionais(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              SizedBox(
                width: 300,
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.content_cut,
                  ),
                  label: const Text(
                    'Serviços',
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TelaServicos(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
