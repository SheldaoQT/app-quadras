import 'package:app_quadras/cadastro_profissional.dart';
import 'package:app_quadras/profissional.dart';
import 'package:app_quadras/profissional_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TelaProfissionais extends StatefulWidget {
  const TelaProfissionais({
    super.key,
  });

  @override
  State<TelaProfissionais> createState() => _TelaProfissionaisState();
}

class _TelaProfissionaisState extends State<TelaProfissionais> {
  @override
  void initState() {
    super.initState();

    context.read<ProfissionalStore>().buscarProfissionais();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final store = context.read<ProfissionalStore>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profissionais',
        ),
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 600,
          ),

          child: ListenableBuilder(
            listenable: store,

            builder:
                (
                  context,
                  child,
                ) {
                  if (store.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (store.profissionais.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nenhum profissional cadastrado',
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: store.profissionais.length,

                    itemBuilder:
                        (
                          context,
                          index,
                        ) {
                          final Profissional profissional = store.profissionais[index];

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,

                                MaterialPageRoute(
                                  builder:
                                      (
                                        context,
                                      ) => CadastroProfissional(
                                        profissional: profissional,
                                      ),
                                ),
                              ).then(
                                (_) {
                                  store.buscarProfissionais();
                                },
                              );
                            },

                            child: Card(
                              elevation: 8,

                              child: ListTile(
                                leading: const Icon(
                                  Icons.person,
                                ),

                                title: Text(
                                  profissional.descricao,
                                ),

                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [
                                    Text(
                                      'Comissão: ${profissional.comissao.toStringAsFixed(1)}%',
                                    ),

                                    Text(
                                      'Serviços: ${profissional.servicosHabilitados.length}',
                                    ),
                                  ],
                                ),
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
                  ) => const CadastroProfissional(),
            ),
          ).then(
            (_) {
              store.buscarProfissionais();
            },
          );
        },
      ),
    );
  }
}
