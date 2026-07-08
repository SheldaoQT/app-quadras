import 'package:app_barba/cadastro_barbeiro.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TelaBarbeiros extends StatefulWidget {
  const TelaBarbeiros({super.key});

  @override
  State<TelaBarbeiros> createState() => _TelaBarbeirosState();
}

class _TelaBarbeirosState extends State<TelaBarbeiros> {
  bool carregando = true;
  List<dynamic> barbeiros = [];

  @override
  void initState() {
    super.initState();
    buscarBarbeiros();
  }

  Future<void> buscarBarbeiros() async {
    try {
      final resposta = await Supabase.instance.client.from('usuarios').select().eq('perfil', 'funcionario').order('nome');

      if (!mounted) return;

      setState(() {
        barbeiros = resposta;
        carregando = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        carregando = false;
      });
    }
  }

  Future<void> editarBarbeiro(Map barbeiro) async {
    final nomeController = TextEditingController(
      text: barbeiro['nome'] ?? '',
    );

    final especialidadeController = TextEditingController(
      text: barbeiro['especialidade'] ?? '',
    );

    bool ativo = barbeiro['ativo'] ?? true;

    final salvar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Editar barbeiro'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: especialidadeController,
                    decoration: const InputDecoration(
                      labelText: 'Especialidade',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Ativo'),
                    value: ativo,
                    onChanged: (value) {
                      setStateDialog(() {
                        ativo = value;
                      });
                    },
                  ),
                ],
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

    await Supabase.instance.client.from('usuarios').update({
      'nome': nomeController.text.trim(),
      'especialidade': especialidadeController.text.trim(),
      'ativo': ativo,
    }).eq('id', barbeiro['id']);

    await buscarBarbeiros();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Barbeiro atualizado'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<bool> barbeiroPossuiVinculos(String id) async {
    final servicos = await Supabase.instance.client.from('servicos').select('id').eq('barbeiro_id', id);

    final horarios = await Supabase.instance.client.from('horarios').select('id').eq('barbeiro_id', id);

    final agendamentos = await Supabase.instance.client.from('agendamentos').select('id').eq('barbeiro_id', id);

    return servicos.isNotEmpty || horarios.isNotEmpty || agendamentos.isNotEmpty;
  }

  Future<void> confirmarExclusao(Map barbeiro) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir barbeiro'),
          content: Text(
            'Deseja excluir o barbeiro "${barbeiro['nome']}"?',
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
      await excluirBarbeiro(barbeiro);
    }
  }

  Future<void> excluirBarbeiro(Map barbeiro) async {
    final id = barbeiro['id'];

    final possuiVinculos = await barbeiroPossuiVinculos(id);

    if (possuiVinculos) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não é possível excluir: existem serviços, horários ou agendamentos vinculados a este barbeiro.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    try {
      await Supabase.instance.client.from('usuarios').delete().eq('id', id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Barbeiro excluído'),
          backgroundColor: Colors.green,
        ),
      );

      await buscarBarbeiros();
    } on PostgrestException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget cardBarbeiro(Map barbeiro) {
    final ativo = barbeiro['ativo'] ?? true;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: ativo ? null : Colors.grey.shade300,
          child: const Icon(Icons.person),
        ),
        title: Text(barbeiro['nome'] ?? ''),
        subtitle: Text(
          '''
Especialidade: ${barbeiro['especialidade'] ?? 'Não informada'}
Status: ${ativo ? 'Ativo' : 'Inativo'}
''',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(
                Icons.edit,
                color: Colors.blue,
              ),
              onPressed: () {
                editarBarbeiro(barbeiro);
              },
            ),
            IconButton(
              tooltip: 'Excluir',
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
              onPressed: () {
                confirmarExclusao(barbeiro);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barbeiros'),
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : barbeiros.isEmpty
              ? const Center(
                  child: Text('Nenhum barbeiro cadastrado'),
                )
              : RefreshIndicator(
                  onRefresh: buscarBarbeiros,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: barbeiros.length,
                    itemBuilder: (context, index) {
                      return cardBarbeiro(barbeiros[index]);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CadastroBarbeiro(),
            ),
          );

          await buscarBarbeiros();
        },
      ),
    );
  }
}
