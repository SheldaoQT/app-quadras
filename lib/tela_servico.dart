import 'package:app_barba/cadastro_servico.dart';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TelaServicos extends StatefulWidget {
  const TelaServicos({
    super.key,
  });

  @override
  State<TelaServicos> createState() => _TelaServicosState();
}

class _TelaServicosState extends State<TelaServicos> {
  bool carregando = true;

  List<dynamic> servicos = [];

  @override
  void initState() {
    super.initState();

    buscarServicos();
  }

  Future<void> buscarServicos() async {
    try {
      final resposta = await Supabase.instance.client
          .from(
            'servicos',
          )
          .select()
          .order(
            'nome',
          );

      if (!mounted) return;

      setState(() {
        servicos = resposta;

        carregando = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        carregando = false;
      });
    }
  }

  Widget cardServico(
    Map item,
  ) {
    return Card(
      child: ListTile(
        leading: const Icon(
          Icons.content_cut,
        ),
        title: Text(
          item['nome'],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'R\$ ${item['preco']}',
            ),
            Text(
              '${item['duracao']} min',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Serviços',
        ),
      ),
      body: carregando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : servicos.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum serviço',
                  ),
                )
              : RefreshIndicator(
                  onRefresh: buscarServicos,
                  child: ListView.builder(
                    itemCount: servicos.length,
                    itemBuilder: (
                      context,
                      index,
                    ) {
                      return cardServico(
                        servicos[index],
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(
          Icons.add,
        ),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CadastroServico(),
            ),
          );

          buscarServicos();
        },
      ),
    );
  }
}
