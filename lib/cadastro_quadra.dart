import 'package:app_quadras/esporte.dart';
import 'package:app_quadras/quadra.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CadastroQuadra extends StatefulWidget {
  const CadastroQuadra({super.key, this.quadra});

  final Quadra? quadra;

  @override
  State<CadastroQuadra> createState() => _CadastroQuadraState();
}

class _CadastroQuadraState extends State<CadastroQuadra> {
  List<Esporte> esportes = [];
  late TextEditingController descricaoController;
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  Map<Esporte, bool> esportesHabilitados = {};

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    descricaoController = TextEditingController();
    if (widget.quadra != null) {
      descricaoController = TextEditingController(text: widget.quadra!.descricao);
    }
    consultarEsportes();
  }

  void consultarEsportes() async {
    final supabase = Supabase.instance.client;
    final esportesSupabase = await supabase
        .from("esporte") //
        .select();
    // print("esportes: $esportesSupabase");
    setState(() {
      esportes = esportesSupabase.map(
        (e) {
          print("id: $e");
          print("${e["id"]}");
          print("${e["descricao"]}");
          print("${e["numero_jogadores"]}");
          return Esporte(
            id: e["id"],
            descricao: e["descricao"],
            numeroJogadores: e["numero_jogadores"],
          );
        },
      ).toList();
    });
    esportesHabilitados.clear();
    for (var esp in esportes) {
      esportesHabilitados[esp] = false;
    }

    if (widget.quadra != null) {
      if (widget.quadra!.esportesHabilitados.isEmpty) {
        debugPrint('Nenhum esporte habilitado para a quadra "${widget.quadra!.descricao}"');
      } else {
        debugPrint(
          'esportes habilitados para a quadra "${widget.quadra!.descricao}": ${widget.quadra!.esportesHabilitados.map((e) => e.descricao).toList()}',
        );
        for (var esp in esportesHabilitados.entries) {
          // debugPrint("quadra ${widget.quadra!.descricao} contém esporte ${esp.key}? ${widget.quadra!.esportesHabilitados.contains(esp.key)}");
          final list = widget.quadra!.esportesHabilitados.where((element) => element.id == esp.key.id);
          // print('list: $list');
          if (list.isNotEmpty) {
            esportesHabilitados[esp.key] = true;
          }
        }
        // print('esportes habilitados depois for in: $esportesHabilitados');
        setState(() {});
      }
    }
    // print("esportesHabilitados: $esportesHabilitados");
    // if (widget.quadra != null) {
    //   for (var esp in esportesHabilitados.entries) {
    //     print("quadra ${widget.quadra!.descricao} contém esporte ${esp.key}? ${widget.quadra!.esportesHabilitados.contains(esp.key)}");
    //     if (widget.quadra!.esportesHabilitados.contains(esp.key)) {
    //       esportesHabilitados[esp.key] = true;
    //     }
    //   }
    //   setState(() {});
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cadastro Quadra"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Container(
            width: MediaQuery.sizeOf(context).width * 0.35,
            // color: Colors.amber,
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Descrição",
                    ),
                    controller: descricaoController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Campo obrigatório";
                      }
                      return null;
                    },
                  ),
                  ...esportes.map(
                    (e) {
                      return Row(
                        children: [
                          Checkbox.adaptive(
                            value: esportesHabilitados[e],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  esportesHabilitados[e] = value;
                                });
                                print("esportesHabilitados: $esportesHabilitados");
                              }
                            },
                          ),
                          Text(e.descricao),
                        ],
                      );
                    },
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final supabase = Supabase.instance.client;

                      if (widget.quadra != null) {
                        // trata-se de uma edição
                        try {
                          if (descricaoController.text != widget.quadra!.descricao) {
                            await supabase //
                                .from("quadra")
                                .update({"descricao": descricaoController.text})
                                .eq("id", widget.quadra!.id!);
                          }
                          List<Map<String, dynamic>> registros =
                              await supabase //
                                  .from("quadra")
                                  .select()
                                  .eq("descricao", descricaoController.text);
                          var idQuadra = registros.first["id"];
                          for (var element in esportesHabilitados.entries) {
                            if (element.value) {
                              // checkbox está com valor true
                              if (widget.quadra!.esportesHabilitados.where((e) => e.id == element.key.id).isEmpty) {
                                // significa que esse esporte não estava habilitado para essa quadra até a edição
                                await supabase.from("quadra_esporte").insert({
                                  "quadra_id": idQuadra,
                                  "esporte_id": element.key.id,
                                });
                              }
                            } else {
                              // checkbox está com valor false
                              if (widget.quadra!.esportesHabilitados.where((e) => e.id == element.key.id).isNotEmpty) {
                                // significa que esse esporte estava habilitado para essa quadra até a edição
                                await supabase //
                                    .from("quadra_esporte")
                                    .delete()
                                    .eq("quadra_id", idQuadra)
                                    .eq("esporte_id", element.key.id!);
                              }
                            }
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Alteração realizada com sucesso!"),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.of(context).pop();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Ocorreu um erro durante a alteração"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } else {
                        if (formKey.currentState!.validate()) {
                          await supabase.from("quadra").insert({
                            "descricao": descricaoController.text,
                          });
                          List<Map<String, dynamic>> registros =
                              await supabase //
                                  .from("quadra")
                                  .select()
                                  .eq("descricao", descricaoController.text);
                          var idQuadra = registros.first["id"];
                          for (var entry in esportesHabilitados.entries) {
                            print("${entry.key.id}, ${entry.key.descricao}, marcado: ${entry.value}");
                          }
                          try {
                            for (var esporte in esportesHabilitados.entries.where((element) => element.value)) {
                              await supabase.from("quadra_esporte").insert({
                                "quadra_id": idQuadra,
                                "esporte_id": esporte.key.id,
                              });
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Cadastro realizado com sucesso!"),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.of(context).pop();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Ocorreu um erro durante o cadastro"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                    child: Text("Salvar"),
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
