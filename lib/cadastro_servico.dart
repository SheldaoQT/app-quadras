import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CadastroServico extends StatefulWidget {
  const CadastroServico({
    super.key,
  });

  @override
  State<CadastroServico> createState() => _CadastroServicoState();
}

class _CadastroServicoState extends State<CadastroServico> {
  final formKey = GlobalKey<FormState>();

  final nomeController = TextEditingController();
  final precoController = TextEditingController();
  final duracaoController = TextEditingController();

  bool carregando = false;
  bool carregandoFuncionarios = true;

  List<dynamic> funcionarios = [];
  String? funcionarioSelecionado;

  @override
  void initState() {
    super.initState();
    buscarFuncionarios();
  }

  Future<void> buscarFuncionarios() async {
    try {
      final resposta = await Supabase.instance.client.from('usuarios').select().eq('perfil', 'funcionario').eq('ativo', true).order('nome');

      if (!mounted) return;

      setState(() {
        funcionarios = resposta;
        carregandoFuncionarios = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        carregandoFuncionarios = false;
      });

      print(e);
    }
  }

  Future<void> cadastrar() async {
    if (funcionarioSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um funcionário'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      await Supabase.instance.client.from('servicos').insert({
        'nome': nomeController.text.trim(),
        'preco': double.parse(
          precoController.text.replaceAll(',', '.'),
        ),
        'duracao': int.parse(
          duracaoController.text,
        ),
        'barbeiro_id': funcionarioSelecionado,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Serviço cadastrado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } on PostgrestException catch (e) {
      print('Erro Supabase: ${e.message}');
      print('Código: ${e.code}');
      print('Detalhes: ${e.details}');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      print(e);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Serviço'),
      ),
      body: carregandoFuncionarios
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: funcionarioSelecionado,
                      decoration: const InputDecoration(
                        labelText: 'Funcionário',
                        border: OutlineInputBorder(),
                      ),
                      items: funcionarios
                          .map<DropdownMenuItem<String>>(
                            (funcionario) => DropdownMenuItem<String>(
                              value: funcionario['id'],
                              child: Text(
                                funcionario['nome'],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          funcionarioSelecionado = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Selecione um funcionário';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo obrigatório';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: precoController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Preço',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo obrigatório';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: duracaoController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duração (min)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo obrigatório';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: carregando
                            ? null
                            : () {
                                if (formKey.currentState!.validate()) {
                                  cadastrar();
                                }
                              },
                        child: carregando ? const CircularProgressIndicator() : const Text('Salvar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
