import 'package:app_quadras/pesquisa_jogos.dart';
import 'package:flutter/material.dart';

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tela principal"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: Drawer(),
      body: SizedBox.expand(
        child: Column(
          children: [
            Expanded(
              child: Container(
                alignment: Alignment.center,
                child: Text('Você não está participando de nenhum jogo no momento'),
              ),
            ),
            Container(
              color: Theme.of(context).colorScheme.inversePrimary,
              alignment: Alignment.center,
              height: MediaQuery.of(context).size.height * 0.1,
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PesquisaJogos(),
                  ),
                ),
                child: Text('Jogos'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
