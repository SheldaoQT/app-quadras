import 'package:app_quadras/cadastro_agendamento.dart';
import 'package:flutter/material.dart';

class MeusAgendamentos extends StatefulWidget {
  const MeusAgendamentos({super.key});

  @override
  State<MeusAgendamentos> createState() => _MeusAgendamentosState();
}

class _MeusAgendamentosState extends State<MeusAgendamentos> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meus agendamentos',
        ),

        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),

      body: const Center(
        child: Text(
          'Nenhum agendamento encontrado',
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(
            context,
          ).push(
            MaterialPageRoute(
              builder: (context) => const CadastroAgendamento(),
            ),
          );
        },

        child: const Icon(
          Icons.add,
        ),
      ),
    );
  }
}
