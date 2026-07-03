import 'package:app_quadras/cadastro_servico.dart';
import 'package:app_quadras/servico.dart';
import 'package:app_quadras/servico_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TelaServicos extends StatefulWidget {
  const TelaServicos({
    super.key,
  });

  @override
  State<TelaServicos> createState() => _TelaServicosState();
}

class _TelaServicosState extends State<TelaServicos> {
  @override
  void initState() {
    super.initState();

    context.read<ServicoStore>().buscarServicos();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final servicoStore = context.read<ServicoStore>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Serviços',
        ),
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 600,
          ),

          child: ListenableBuilder(
            listenable: servicoStore,

            builder:
                (
                  context,
                  child,
                ) {
                  if (servicoStore.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (servicoStore.servicos.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nenhum serviço cadastrado',
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: servicoStore.servicos.length,

                    itemBuilder:
                        (
                          context,
                          index,
                        ) {
                          final Servico servico = servicoStore.servicos[index];

                          return Card(
                            elevation: 6,

                            child: ListTile(
                              leading: const Icon(
                                Icons.content_cut,
                              ),

                              title: Text(
                                servico.nome,
                              ),

                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  Text(
                                    'Preço: R\$ ${servico.preco.toStringAsFixed(2)}',
                                  ),

                                  Text(
                                    'Duração: ${servico.duracao} min',
                                  ),
                                ],
                              ),

                              trailing: Text(
                                '#${index + 1}',
                              ),
                            ),
                          );
                        },
                  );
                },
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        child: const Icon(
          Icons.add,
        ),

        onPressed: () {
          Navigator.push(
            context,

            MaterialPageRoute(
              builder:
                  (
                    context,
                  ) => const CadastroServico(),
            ),
          ).then(
            (_) {
              servicoStore.buscarServicos();
            },
          );
        },
      ),
    );
  }
}
