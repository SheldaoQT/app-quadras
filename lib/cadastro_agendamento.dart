import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CadastroAgendamento extends StatefulWidget {
  const CadastroAgendamento({
    super.key,
  });

  @override
  State<CadastroAgendamento> createState() => _CadastroAgendamentoState();
}

class _CadastroAgendamentoState extends State<CadastroAgendamento> {
  bool carregando = true;

  List<dynamic> servicos = [];
  List<dynamic> funcionarios = [];

  int? servicoSelecionado;
  String? funcionarioSelecionado;
  DateTime? dataSelecionada;

  @override
  void initState() {
    super.initState();

    carregarDados();
  }

  Future<void> carregarDados() async {
    await buscarServicos();
    await buscarfuncionarios();

    if (!mounted) return;

    setState(() {
      carregando = false;
    });
  }

  Future<void> buscarServicos() async {
    final resposta = await Supabase.instance.client
        .from(
          'servicos',
        )
        .select();

    servicos = resposta;
  }

  Future<void> buscarfuncionarios() async {
    final resposta = await Supabase.instance.client
        .from(
          'usuarios',
        )
        .select()
        .eq(
          'perfil',
          'funcionario',
        );

    funcionarios = resposta;
  }

  Future<void> salvar() async {
    if (servicoSelecionado == null || funcionarioSelecionado == null || dataSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Preencha todos os campos',
          ),
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    try {
      final usuario = Supabase.instance.client.auth.currentUser;

      if (usuario == null) {
        return;
      }

      await Supabase.instance.client
          .from(
        'agendamentos',
      )
          .insert({
        'cliente_id': usuario.id,
        'servico_id': servicoSelecionado,
        'barbeiro_id': funcionarioSelecionado,
        'data_hora': dataSelecionada!.toIso8601String(),
        'status': 'pendente',
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Agendamento realizado',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Erro ao salvar',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Novo Agendamento',
        ),
      ),
      body: carregando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(
                16,
              ),
              child: Column(
                children: [
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Serviço',
                      border: OutlineInputBorder(),
                    ),
                    items: servicos
                        .map<DropdownMenuItem<int>>(
                          (s) => DropdownMenuItem<int>(
                            value: s['id'] as int,
                            child: Text(
                              s['nome'],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        servicoSelecionado = value;
                      });
                    },
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'funcionario',
                      border: OutlineInputBorder(),
                    ),
                    items: funcionarios
                        .map<DropdownMenuItem<String>>(
                          (b) => DropdownMenuItem<String>(
                            value: b['id'],
                            child: Text(
                              b['nome'],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        funcionarioSelecionado = value;
                      });
                    },
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final data = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(
                          2100,
                        ),
                        initialDate: DateTime.now(),
                      );

                      if (data == null) {
                        return;
                      }

                      if (!context.mounted) {
                        return;
                      }

                      final hora = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );

                      if (hora == null) {
                        return;
                      }

                      setState(() {
                        dataSelecionada = DateTime(
                          data.year,
                          data.month,
                          data.day,
                          hora.hour,
                          hora.minute,
                        );
                      });
                    },
                    child: const Text(
                      'Selecionar Data e Hora',
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  if (dataSelecionada != null)
                    Text(
                      DateFormat(
                        'dd/MM/yyyy HH:mm',
                      ).format(
                        dataSelecionada!,
                      ),
                    ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: salvar,
                      child: const Text(
                        'Confirmar',
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
