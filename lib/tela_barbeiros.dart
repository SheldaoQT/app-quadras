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
                    title: Text(
                      ativo ? 'Ativado' : 'Desativado',
                    ),
                    subtitle: Text(
                      ativo ? 'Barbeiro disponível no sistema' : 'Barbeiro oculto para novos agendamentos',
                    ),
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
      SnackBar(
        content: Text(
          ativo ? 'Barbeiro ativado' : 'Barbeiro desativado',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> alterarStatusBarbeiro(Map barbeiro) async {
    final ativoAtual = barbeiro['ativo'] ?? true;
    final novoStatus = !ativoAtual;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            novoStatus ? 'Ativar barbeiro' : 'Desativar barbeiro',
          ),
          content: Text(
            novoStatus
                ? 'Deseja ativar o barbeiro "${barbeiro['nome']}"?'
                : 'Deseja desativar o barbeiro "${barbeiro['nome']}"? Ele não aparecerá para novos agendamentos.',
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
              child: Text(
                novoStatus ? 'Ativar' : 'Desativar',
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    await Supabase.instance.client.from('usuarios').update({
      'ativo': novoStatus,
    }).eq('id', barbeiro['id']);

    await buscarBarbeiros();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          novoStatus ? 'Barbeiro ativado' : 'Barbeiro desativado',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget cardBarbeiro(Map barbeiro) {
    final ativo = barbeiro['ativo'] ?? true;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: ativo ? Colors.brown.shade100 : Colors.grey.shade300,
          child: Icon(
            Icons.person,
            color: ativo ? Colors.brown : Colors.grey,
          ),
        ),
        title: Text(
          barbeiro['nome'] ?? '',
          style: TextStyle(
            color: ativo ? null : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '''
Especialidade: ${barbeiro['especialidade'] ?? 'Não informada'}
Status: ${ativo ? 'Ativado' : 'Desativado'}
''',
        ),
        trailing: Row(
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
                alterarStatusBarbeiro(barbeiro);
              },
            ),
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
