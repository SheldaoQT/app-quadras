import 'package:app_barba/cadastro_servico.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TelaServicos extends StatefulWidget {
  const TelaServicos({super.key});

  @override
  State<TelaServicos> createState() => _TelaServicosState();
}

class _TelaServicosState extends State<TelaServicos> {
  bool carregando = true;
  bool podeCadastrar = false;

  List<dynamic> servicos = [];
  List<dynamic> barbeiros = [];

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    await verificarPermissao();
    await buscarBarbeiros();
    await buscarServicos();

    if (!mounted) return;

    setState(() {
      carregando = false;
    });
  }

  Future<void> verificarPermissao() async {
    final usuario = Supabase.instance.client.auth.currentUser;

    if (usuario == null) return;

    final dados = await Supabase.instance.client.from('usuarios').select('perfil').eq('id', usuario.id).single();

    final perfil = dados['perfil'];

    podeCadastrar = perfil == 'funcionario' || perfil == 'admin';
  }

  Future<void> buscarBarbeiros() async {
    final resposta = await Supabase.instance.client.from('usuarios').select().eq('perfil', 'funcionario').eq('ativo', true).order('nome');

    barbeiros = resposta;
  }

  Future<void> buscarServicos() async {
    final resposta = await Supabase.instance.client.from('servicos').select('''
          *,
          barbeiro:usuarios!servicos_barbeiro_id_fkey(*)
        ''').order('nome');

    servicos = resposta;
  }

  Future<void> editarServico(Map item) async {
    final nomeController = TextEditingController(
      text: item['nome'] ?? '',
    );

    final precoController = TextEditingController(
      text: item['preco'].toString(),
    );

    final duracaoController = TextEditingController(
      text: item['duracao'].toString(),
    );

    String? barbeiroSelecionado = item['barbeiro_id'];

    final salvar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Editar serviço'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: barbeiroSelecionado,
                      decoration: const InputDecoration(
                        labelText: 'Barbeiro',
                        border: OutlineInputBorder(),
                      ),
                      items: barbeiros
                          .map<DropdownMenuItem<String>>(
                            (b) => DropdownMenuItem<String>(
                              value: b['id'],
                              child: Text(b['nome']),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setStateDialog(() {
                          barbeiroSelecionado = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: precoController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Preço',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: duracaoController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duração',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (salvar != true) return;

    if (barbeiroSelecionado == null ||
        nomeController.text.trim().isEmpty ||
        precoController.text.trim().isEmpty ||
        duracaoController.text.trim().isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos'),
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    await Supabase.instance.client.from('servicos').update({
      'nome': nomeController.text.trim(),
      'preco': double.parse(
        precoController.text.replaceAll(',', '.'),
      ),
      'duracao': int.parse(
        duracaoController.text,
      ),
      'barbeiro_id': barbeiroSelecionado,
    }).eq('id', item['id']);

    await carregarDados();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Serviço atualizado'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> confirmarExclusao(Map item) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir serviço'),
          content: Text(
            'Deseja excluir o serviço "${item['nome']}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      await excluirServico(item['id']);
    }
  }

  Future<void> excluirServico(int id) async {
    try {
      await Supabase.instance.client.from('servicos').delete().eq('id', id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Serviço excluído'),
          backgroundColor: Colors.green,
        ),
      );

      await carregarDados();
    } on PostgrestException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível excluir: ${e.message}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget cardServico(Map item) {
    final barbeiro = item['barbeiro'];

    return Card(
      child: ListTile(
        leading: const Icon(Icons.content_cut),
        title: Text(item['nome']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Barbeiro: ${barbeiro?['nome'] ?? 'Não informado'}'),
            Text('R\$ ${item['preco']}'),
            Text('${item['duracao']} min'),
          ],
        ),
        trailing: podeCadastrar
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Editar',
                    icon: const Icon(
                      Icons.edit,
                      color: Colors.blue,
                    ),
                    onPressed: () {
                      editarServico(item);
                    },
                  ),
                  IconButton(
                    tooltip: 'Excluir',
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      confirmarExclusao(item);
                    },
                  ),
                ],
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Serviços'),
      ),
      body: carregando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : servicos.isEmpty
              ? const Center(
                  child: Text('Nenhum serviço'),
                )
              : RefreshIndicator(
                  onRefresh: carregarDados,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: servicos.length,
                    itemBuilder: (context, index) {
                      return cardServico(servicos[index]);
                    },
                  ),
                ),
      floatingActionButton: podeCadastrar
          ? FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CadastroServico(),
                  ),
                );

                await carregarDados();
              },
            )
          : null,
    );
  }
}
