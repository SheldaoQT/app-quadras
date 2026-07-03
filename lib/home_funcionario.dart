import 'package:app_barba/tela_horarios.dart';
import 'package:app_barba/tela_profissionais.dart';
import 'package:app_barba/tela_servicos.dart';
import 'package:flutter/material.dart';

class HomeFuncionario extends StatefulWidget {
  const HomeFuncionario({
    super.key,
  });

  @override
  State<HomeFuncionario> createState() => _HomeFuncionarioState();
}

class _HomeFuncionarioState extends State<HomeFuncionario> {
  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Painel da Barbearia',
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
                    'Área Administrativa',

                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(
                    height: 8,
                  ),

                  Text(
                    'Gerenciamento',
                  ),
                ],
              ),
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

            ListTile(
              leading: const Icon(
                Icons.schedule,
              ),

              title: const Text(
                'Horários',
              ),

              onTap: () {
                Navigator.push(
                  context,

                  MaterialPageRoute(
                    builder: (_) => const TelaHorarios(),
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
                Navigator.popUntil(
                  context,
                  (route) => route.isFirst,
                );
              },
            ),
          ],
        ),
      ),

      body: const Center(
        child: Text(
          'Bem-vindo ao painel do funcionário',
        ),
      ),
    );
  }
}
