import 'package:app_quadras/cadastro_esporte.dart';
import 'package:app_quadras/cadastro_quadra.dart';
import 'package:app_quadras/esporte.dart';
import 'package:app_quadras/quadra.dart';
import 'package:app_quadras/quadra_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TelaQuadras extends StatefulWidget {
  const TelaQuadras({super.key});

  @override
  State<TelaQuadras> createState() => _TelaQuadrasState();
}

class _TelaQuadrasState extends State<TelaQuadras> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    context.read<QuadraStore>().buscarQuadras();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<QuadraStore>();
    return Scaffold(
      appBar: AppBar(
        title: Text("Tela Quadras"),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 500,
          ),
          child: ListenableBuilder(
            listenable: store,
            builder: (context, child) {
              return ListView.builder(
                itemCount: store.quadras.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (context) {
                                return CadastroQuadra(
                                  quadra: store.quadras[index],
                                );
                              },
                            ),
                          )
                          .then(
                            (value) {
                              store.buscarQuadras();
                            },
                          );
                    },
                    child: Card(
                      elevation: 8,
                      child: ListTile(
                        title: Text(store.quadras[index].descricao),
                        subtitle: Text("Esportes habilitados: ${store.quadras[index].esportesHabilitados.length}"),
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
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (context) {
                    return CadastroQuadra();
                  },
                ),
              )
              .then(
                (value) {
                  if (value != null) {
                    print("value: $value");
                  }
                  store.buscarQuadras();
                },
              );
        },
      ),
    );
  }
}
