import 'package:app_barba/tela_servicos_profissional.dart';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TelaProfissionais extends StatefulWidget {
  const TelaProfissionais({
    super.key,
  });

  @override
  State<TelaProfissionais> createState() => _TelaProfissionaisState();
}

class _TelaProfissionaisState extends State<TelaProfissionais> {
  bool carregando = true;

  List<dynamic> profissionais = [];

  @override
  void initState() {
    super.initState();
    buscarProfissionais();
  }

  Future<void> buscarProfissionais() async {
    try {
      final resposta = await Supabase.instance.client.from('usuarios').select().eq('perfil', 'funcionario').eq('ativo', true).order('nome');

      if (!mounted) return;

      setState(() {
        profissionais = resposta;
        carregando = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        carregando = false;
      });
    }
  }

  Widget item(Map profissional) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.person),
        ),
        title: Text(
          profissional['nome'] ?? '',
        ),
        subtitle: Text(
          'Especialidade: ${profissional['especialidade'] ?? 'Não informada'}',
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TelaServicosProfissional(
                profissional: profissional,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profissionais'),
      ),
      body: carregando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : profissionais.isEmpty
              ? const Center(
                  child: Text('Nenhum profissional cadastrado'),
                )
              : RefreshIndicator(
                  onRefresh: buscarProfissionais,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: profissionais.length,
                    itemBuilder: (context, index) {
                      return item(profissionais[index]);
                    },
                  ),
                ),
    );
  }
}
