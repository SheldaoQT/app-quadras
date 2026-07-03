import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Cadastrofuncionario extends StatefulWidget {
  const Cadastrofuncionario({
    super.key,
  });

  @override
  State<Cadastrofuncionario> createState() => _CadastrofuncionarioState();
}

class _CadastrofuncionarioState extends State<Cadastrofuncionario> {
  final nomeController = TextEditingController();

  final especialidadeController = TextEditingController();

  Future cadastrar() async {
    final supabase = Supabase.instance.client;

    await supabase.from('usuarios').insert({
      'nome': nomeController.text,
      'perfil': 'funcionario',
      'especialidade': especialidadeController.text,
      'ativo': true,
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cadastrar funcionario',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(
          16,
        ),
        child: Column(
          children: [
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome',
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            TextField(
              controller: especialidadeController,
              decoration: const InputDecoration(
                labelText: 'Especialidade',
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () async {
                await cadastrar();

                if (context.mounted) {
                  Navigator.pop(
                    context,
                  );
                }
              },
              child: const Text(
                'Salvar',
              ),
            )
          ],
        ),
      ),
    );
  }
}
