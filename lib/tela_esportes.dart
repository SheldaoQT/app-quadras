import 'package:app_quadras/cadastro_esporte.dart';
import 'package:app_quadras/esporte.dart';
import 'package:app_quadras/esporte_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TelaEsportes extends StatefulWidget {
  const TelaEsportes({super.key});

  @override
  State<TelaEsportes> createState() => _TelaEsportesState();
}

class _TelaEsportesState extends State<TelaEsportes> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    context.read<EsporteStore>().buscarEsportes();
  }

  @override
  Widget build(BuildContext context) {
    final esporteStore = context.read<EsporteStore>();
    return Scaffold(
      appBar: AppBar(
        title: Text("Tela Esportes"),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 500,
          ),
          child: ListenableBuilder(
            listenable: esporteStore,
            builder: (context, child) {
              if (esporteStore.isLoading) {
                return CircularProgressIndicator.adaptive();
              }

              return ListView.builder(
                itemCount: esporteStore.esportes.length,
                itemBuilder: (context, index) {
                  final Esporte esporteCorrente = esporteStore.esportes[index];
                  return Card(
                    elevation: 8.0,
                    child: ListTile(
                      leading: Icon(Icons.sports_basketball),
                      title: Text(esporteCorrente.descricao),
                      subtitle: Text("Nº de jogadores: ${esporteCorrente.numeroJogadores}"),
                      trailing: Text(index.toString()),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (context) {
                    return CadastroEsporte();
                  },
                ),
              )
              .then(
                (value) {
                  if (value != null) {
                    print("value: $value");
                  }
                  esporteStore.buscarEsportes();
                },
              );
        },
      ),
    );
  }
}
