import 'package:app_quadras/cadastro_jogos.dart';
import 'package:flutter/material.dart';

class PesquisaJogos extends StatefulWidget {
  const PesquisaJogos({super.key});

  @override
  State<PesquisaJogos> createState() => _PesquisaJogosState();
}

class _PesquisaJogosState extends State<PesquisaJogos> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pesquisa de jogos'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Text('Não há nenhum jogo cadastrado'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CadastroJogos(),
          ),
        ),
        child: Icon(Icons.add),
      ),
    );
  }
}
