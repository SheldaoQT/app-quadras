import 'package:app_quadras/esporte.dart';
import 'package:app_quadras/esporte_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CadastroEsporte extends StatefulWidget {
  const CadastroEsporte({super.key});

  @override
  State<CadastroEsporte> createState() => _CadastroEsporteState();
}

class _CadastroEsporteState extends State<CadastroEsporte> {
  final formKey = GlobalKey<FormState>();
  final descricaoController = TextEditingController();
  final numeroJogadoresController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cadastro de esporte"),
      ),
      body: Form(
        key: formKey,
        child: Column(
          spacing: 16,
          children: [
            TextFormField(
              controller: descricaoController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Descrição",
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Campo obrigatório!";
                }
                return null;
              },
            ),
            TextFormField(
              controller: numeroJogadoresController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Nº de jogadores",
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Campo obrigatório!";
                }
                final int? numeroJogadores = int.tryParse(value);
                if (numeroJogadores == null) {
                  return "Valor deve ser um número inteiro!";
                }
                if (numeroJogadores == 0) {
                  return "Valor deve ser um número inteiro maior que zero!";
                }
                return null;
              },
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    // final supabase = Supabase.instance.client;
                    // await supabase.from('esporte').insert({
                    //   'descricao': descricaoController.text,
                    //   'numero_jogadores': numeroJogadoresController.text,
                    // });
                    context.read<EsporteStore>().cadastrarEsporte(
                      Esporte(
                        descricao: descricaoController.text,
                        numeroJogadores: int.parse(numeroJogadoresController.text),
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Cadastro realizado com sucesso!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.of(context).pop(12);
                  } on PostgrestException catch (e) {
                    if (e.code != null && e.code == "23505") {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Esporte já cadastrado"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Falha ao realizar cadastro"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text("Cadastrar"),
            ),
          ],
        ),
      ),
    );
  }
}
