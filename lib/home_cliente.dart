import 'package:app_quadras/login_store.dart';
import 'package:app_quadras/meus_agendamentos.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeCliente extends StatefulWidget {
  const HomeCliente({super.key});

  @override
  State<HomeCliente> createState() => _HomeClienteState();
}

class _HomeClienteState extends State<HomeCliente> {
  bool carregando = true;

  List<dynamic> agendamentos = [];

  @override
  void initState() {
    super.initState();

    consultarAgendamentos();
  }

  Future<void> consultarAgendamentos() async {
    try {
      final supabase = Supabase.instance.client;

      final usuario = context.read<LoginStore>().usuario;

      final resposta = await supabase
          .from(
            'agendamento',
          )
          .select(
            '''
                *,
                servico(*),
                profissional(*)
                ''',
          )
          .eq(
            'cliente_id',
            usuario!.id,
          )
          .order(
            'data',
          );

      setState(() {
        agendamentos = resposta;

        carregando = false;
      });
    } catch (e) {
      setState(() {
        carregando = false;
      });
    }
  }

  Widget cardAgendamento(
    Map item,
  ) {
    final data = DateTime.parse(
      item['data'],
    );

    return Card(
      elevation: 5,

      child: Padding(
        padding: const EdgeInsets.all(
          16,
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              item['servico']['nome'] ?? '',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              'Profissional: ${item['profissional']['descricao']}',
            ),

            Text(
              DateFormat(
                'dd/MM/yyyy',
              ).format(
                data,
              ),
            ),

            Text(
              'Status: ${item['status']}',
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
          'Home Cliente',
        ),
      ),

      drawer: const Drawer(),

      body: carregando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: consultarAgendamentos,

              child: agendamentos.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(
                          height: 300,
                        ),

                        Center(
                          child: Text(
                            'Você ainda não possui agendamentos',
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(
                        16,
                      ),

                      itemCount: agendamentos.length,

                      itemBuilder:
                          (
                            context,
                            index,
                          ) {
                            return cardAgendamento(
                              agendamentos[index],
                            );
                          },
                    ),
            ),

      bottomNavigationBar: Container(
        height: 70,

        alignment: Alignment.center,

        child: TextButton(
          onPressed: () {
            Navigator.push(
              context,

              MaterialPageRoute(
                builder:
                    (
                      context,
                    ) => const MeusAgendamentos(),
              ),
            );
          },

          child: const Text(
            'Agendamentos',
          ),
        ),
      ),
    );
  }
}
