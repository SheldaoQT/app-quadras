import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TelaComissao extends StatefulWidget {
  const TelaComissao({super.key});

  @override
  State<TelaComissao> createState() => _TelaComissaoState();
}

class _TelaComissaoState extends State<TelaComissao> {
  bool carregando = true;

  List<dynamic> barbeiros = [];
  String? barbeiroSelecionado;

  int totalAtendimentos = 0;
  double totalVendido = 0;
  double porcentagemComissao = 40;

  @override
  void initState() {
    super.initState();
    buscarBarbeiros();
  }

  Future<void> buscarBarbeiros() async {
    final resposta = await Supabase.instance.client.from('usuarios').select().eq('perfil', 'funcionario').eq('ativo', true).order('nome');

    if (!mounted) return;

    setState(() {
      barbeiros = resposta;
      carregando = false;
    });
  }

  Future<void> calcularComissao() async {
    if (barbeiroSelecionado == null) {
      return;
    }

    setState(() {
      carregando = true;
    });

    final agora = DateTime.now();

    final inicioMes = DateTime(
      agora.year,
      agora.month,
      1,
    );

    final fimMes = DateTime(
      agora.year,
      agora.month + 1,
      0,
      23,
      59,
      59,
    );

    final resposta = await Supabase.instance.client
        .from('agendamentos')
        .select('''
          *,
          servicos(*)
        ''')
        .eq('barbeiro_id', barbeiroSelecionado!)
        .eq('status', 'concluido')
        .gte('data_hora', inicioMes.toIso8601String())
        .lte('data_hora', fimMes.toIso8601String());

    double total = 0;

    for (final item in resposta) {
      final servico = item['servicos'];

      if (servico != null && servico['preco'] != null) {
        total += double.parse(
          servico['preco'].toString(),
        );
      }
    }

    if (!mounted) return;

    setState(() {
      totalAtendimentos = resposta.length;
      totalVendido = total;
      carregando = false;
    });
  }

  double get valorComissao {
    return totalVendido * (porcentagemComissao / 100);
  }

  String dinheiro(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Widget cardResumo({
    required IconData icon,
    required String titulo,
    required String valor,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(titulo),
        subtitle: Text(
          valor,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comissão Mensal'),
      ),
      body: carregando && barbeiros.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
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
                    onChanged: (value) async {
                      setState(() {
                        barbeiroSelecionado = value;
                        totalAtendimentos = 0;
                        totalVendido = 0;
                      });

                      await calcularComissao();
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: porcentagemComissao.toStringAsFixed(0),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Porcentagem da comissão (%)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        porcentagemComissao = double.tryParse(value.replaceAll(',', '.')) ?? 40;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  if (carregando)
                    const CircularProgressIndicator()
                  else ...[
                    cardResumo(
                      icon: Icons.check_circle,
                      titulo: 'Atendimentos concluídos no mês',
                      valor: totalAtendimentos.toString(),
                    ),
                    cardResumo(
                      icon: Icons.attach_money,
                      titulo: 'Total vendido',
                      valor: dinheiro(totalVendido),
                    ),
                    cardResumo(
                      icon: Icons.percent,
                      titulo: 'Comissão',
                      valor: dinheiro(valorComissao),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
