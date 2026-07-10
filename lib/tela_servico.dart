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
  bool podeGerenciar = false;

  List<dynamic> servicos = [];
  List<dynamic> barbeiros = [];

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    setState(() {
      carregando = true;
    });

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

    if (usuario == null) {
      podeGerenciar = false;
      return;
    }

    final dados = await Supabase.instance.client.from('usuarios').select('perfil').eq('id', usuario.id).single();

    final perfil = dados['perfil'].toString().toLowerCase().trim();

    podeGerenciar = perfil.contains('admin') || perfil.contains('funcionario');
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

  Future<bool> servicoPossuiAgendamentos(int id) async {
    final resposta = await Supabase.instance.client.from('agendamentos').select('id').eq('servico_id', id).limit(1);

    return resposta.isNotEmpty;
  }

  Future<bool> servicoPossuiAgendamentosPendentes(int id) async {
    final resposta = await Supabase.instance.client.from('agendamentos').select('id').eq('servico_id', id).eq('status', 'pendente').limit(1);

    return resposta.isNotEmpty;
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
    bool ativo = item['ativo'] ?? true;

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
                        labelText: 'Duração em minutos',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(ativo ? 'Ativado' : 'Desativado'),
                      value: ativo,
                      onChanged: (value) {
                        setStateDialog(() {
                          ativo = value;
                        });
                      },
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

    try {
      await Supabase.instance.client.from('servicos').update({
        'nome': nomeController.text.trim(),
        'preco': double.parse(
          precoController.text.replaceAll(',', '.'),
        ),
        'duracao': int.parse(
          duracaoController.text,
        ),
        'barbeiro_id': barbeiroSelecionado,
        'ativo': ativo,
      }).eq('id', item['id']);

      await carregarDados();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Serviço atualizado com sucesso'),
          backgroundColor: Colors.green,
        ),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> confirmarRemocao(Map item) async {
    final possuiPendentes = await servicoPossuiAgendamentosPendentes(item['id']);

    if (possuiPendentes) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não é possível remover este serviço porque ele possui agendamentos pendentes.',
          ),
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    final possuiHistorico = await servicoPossuiAgendamentos(item['id']);

    if (!mounted) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(possuiHistorico ? 'Desativar serviço' : 'Excluir serviço'),
          content: Text(
            possuiHistorico
                ? 'Este serviço possui histórico de agendamentos. Deseja desativá-lo para novos agendamentos?'
                : 'Deseja excluir o serviço "${item['nome']}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: possuiHistorico ? Colors.orange : Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text(possuiHistorico ? 'Desativar' : 'Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    if (possuiHistorico) {
      await desativarServico(item['id']);
    } else {
      await excluirServico(item['id']);
    }
  }

  Future<void> desativarServico(int id) async {
    try {
      await Supabase.instance.client.from('servicos').update({
        'ativo': false,
      }).eq('id', id);

      await carregarDados();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Serviço desativado com sucesso'),
          backgroundColor: Colors.green,
        ),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> excluirServico(int id) async {
    try {
      await Supabase.instance.client.from('servicos').delete().eq('id', id);

      await carregarDados();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Serviço excluído com sucesso'),
          backgroundColor: Colors.green,
        ),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;

      final mensagem = e.message.contains('foreign key')
          ? 'Não é possível excluir este serviço porque ele possui histórico de agendamentos. Desative o serviço.'
          : 'Não foi possível excluir: ${e.message}';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> alterarStatusServico(Map item) async {
    final ativoAtual = item['ativo'] ?? true;
    final novoStatus = !ativoAtual;

    if (!novoStatus) {
      final possuiPendentes = await servicoPossuiAgendamentosPendentes(item['id']);

      if (possuiPendentes) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não é possível desativar este serviço porque ele possui agendamentos pendentes.',
            ),
            backgroundColor: Colors.orange,
          ),
        );

        return;
      }
    }

    await Supabase.instance.client.from('servicos').update({
      'ativo': novoStatus,
    }).eq('id', item['id']);

    await carregarDados();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          novoStatus ? 'Serviço ativado' : 'Serviço desativado',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget cardServico(Map item) {
    final barbeiro = item['barbeiro'];
    final ativo = item['ativo'] ?? true;

    return Card(
      color: ativo ? null : Colors.grey.shade100,
      child: ListTile(
        leading: Icon(
          Icons.content_cut,
          color: ativo ? null : Colors.grey,
        ),
        title: Text(
          item['nome'],
          style: TextStyle(
            color: ativo ? null : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Barbeiro: ${barbeiro?['nome'] ?? 'Não informado'}'),
            Text('R\$ ${item['preco']}'),
            Text('${item['duracao']} min'),
            Text('Status: ${ativo ? 'Ativado' : 'Desativado'}'),
          ],
        ),
        trailing: podeGerenciar
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: ativo ? 'Desativar' : 'Ativar',
                    icon: Icon(
                      ativo ? Icons.toggle_on : Icons.toggle_off,
                      color: ativo ? Colors.green : Colors.grey,
                      size: 32,
                    ),
                    onPressed: () {
                      alterarStatusServico(item);
                    },
                  ),
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
                    tooltip: ativo ? 'Remover' : 'Excluir',
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      confirmarRemocao(item);
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
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
            onPressed: carregarDados,
          ),
        ],
      ),
      body: carregando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : servicos.isEmpty
              ? const Center(
                  child: Text('Nenhum serviço cadastrado'),
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
      floatingActionButton: podeGerenciar
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('Novo serviço'),
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
