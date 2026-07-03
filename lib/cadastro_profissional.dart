import 'package:app_quadras/servico.dart';
import 'package:app_quadras/profissional.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CadastroProfissional extends StatefulWidget {
  const CadastroProfissional({
    super.key,
    this.profissional,
  });

  final Profissional? profissional;

  @override
  State<CadastroProfissional> createState() => _CadastroProfissionalState();
}

class _CadastroProfissionalState extends State<CadastroProfissional> {
  List<Servico> servicos = [];

  late TextEditingController descricaoController;

  final formKey = GlobalKey<FormState>();

  Map<Servico, bool> servicosHabilitados = {};

  @override
  void initState() {
    super.initState();

    descricaoController = TextEditingController(
      text: widget.profissional?.descricao ?? '',
    );

    consultarServicos();
  }

  Future<void> consultarServicos() async {
    final supabase = Supabase.instance.client;

    final resposta = await supabase.from('servico').select();

    servicos = resposta.map<Servico>(
      (json) {
        return Servico(
          id: json['id'].toString(),
          nome: json['nome'],
          preco: (json['preco'] as num).toDouble(),
          duracao: json['duracao'],
          profissionalId: json['profissional_id']?.toString() ?? '',
        );
      },
    ).toList();

    servicosHabilitados.clear();

    for (final s in servicos) {
      servicosHabilitados[s] = false;
    }

    if (widget.profissional != null) {
      for (final item in servicosHabilitados.entries) {
        final existe = widget.profissional!.servicosHabilitados
            .where(
              (e) => e.id == item.key.id,
            )
            .isNotEmpty;

        servicosHabilitados[item.key] = existe;
      }
    }

    setState(() {});
  }

  Future<void> salvar() async {
    final supabase = Supabase.instance.client;

    try {
      String idProfissional;

      if (widget.profissional != null) {
        idProfissional = widget.profissional!.id.toString();

        await supabase
            .from('profissional')
            .update({
              'descricao': descricaoController.text,
            })
            .eq(
              'id',
              idProfissional,
            );

        await supabase
            .from('profissional_servico')
            .delete()
            .eq(
              'profissional_id',
              idProfissional,
            );
      } else {
        final resultado = await supabase.from('profissional').insert({
          'descricao': descricaoController.text,
        }).select();

        idProfissional = resultado.first['id'].toString();
      }

      for (final item in servicosHabilitados.entries.where(
        (
          e,
        ) => e.value,
      )) {
        await supabase.from('profissional_servico').insert({
          'profissional_id': idProfissional,
          'servico_id': item.key.id,
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.profissional == null ? 'Cadastro realizado' : 'Alteração realizada',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
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
        title: Text(
          widget.profissional == null ? 'Cadastro profissional' : 'Editar profissional',
        ),
      ),
      body: Center(
        child: SizedBox(
          width:
              MediaQuery.of(
                context,
              ).size.width *
              0.35,
          child: Padding(
            padding: const EdgeInsets.all(
              16,
            ),
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: descricaoController,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        (
                          value,
                        ) {
                          if (value == null || value.isEmpty) {
                            return 'Campo obrigatório';
                          }

                          return null;
                        },
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  ...servicos.map(
                    (
                      servico,
                    ) {
                      return CheckboxListTile(
                        value: servicosHabilitados[servico],
                        title: Text(
                          servico.nome,
                        ),
                        onChanged:
                            (
                              value,
                            ) {
                              setState(
                                () {
                                  servicosHabilitados[servico] = value ?? false;
                                },
                              );
                            },
                      );
                    },
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        salvar();
                      }
                    },
                    child: const Text(
                      'Salvar',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
