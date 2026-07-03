import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TelaServicosProfissional extends StatefulWidget {
  final Map profissional;

  const TelaServicosProfissional({
    super.key,
    required this.profissional,
  });

  @override
  State<TelaServicosProfissional> createState() => _TelaServicosProfissionalState();
}

class _TelaServicosProfissionalState extends State<TelaServicosProfissional> {
  bool carregando = true;
  List<dynamic> servicos = [];

  @override
  void initState() {
    super.initState();
    buscarServicos();
  }

  Future<void> buscarServicos() async {
    final resposta = await Supabase.instance.client.from('servicos').select().eq('barbeiro_id', widget.profissional['id']).order('nome');

    if (!mounted) return;

    setState(() {
      servicos = resposta;
      carregando = false;
    });
  }

  Widget item(Map servico) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.content_cut),
        title: Text(servico['nome']),
        subtitle: Text(
          'Preço: R\$ ${servico['preco']} | Duração: ${servico['duracao']} min',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Serviços - ${widget.profissional['nome']}'),
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : servicos.isEmpty
              ? const Center(
                  child: Text('Nenhum serviço cadastrado para este funcionario'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: servicos.length,
                  itemBuilder: (context, index) {
                    return item(servicos[index]);
                  },
                ),
    );
  }
}
