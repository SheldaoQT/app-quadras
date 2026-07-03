import 'package:app_quadras/utils.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CadastroCliente extends StatefulWidget {
  const CadastroCliente({super.key});

  @override
  State<CadastroCliente> createState() => _CadastroClienteState();
}

class _CadastroClienteState extends State<CadastroCliente> {
  bool obscureText = true;

  final formKey = GlobalKey<FormState>();

  final nomeController = TextEditingController();

  final loginController = TextEditingController();

  final senhaController = TextEditingController();

  String? validarSenha(
    String? value,
  ) {
    if (value == null || value.isEmpty) {
      return 'Campo obrigatório!';
    }

    final regex = RegExp(
      r'^(?=.*[a-z])'
      r'(?=.*[A-Z])'
      r'(?=.*\d)'
      r'(?=.*[@$!%*?&\-_#])'
      r'[A-Za-z\d@$!%*?&\-_#]{12,}$',
    );

    if (!regex.hasMatch(value)) {
      return 'A senha precisa ter no mínimo 12 caracteres';
    }

    return null;
  }

  Future<void> cadastrar() async {
    final supabase = Supabase.instance.client;

    await supabase
        .from(
          'cliente',
        )
        .insert({
          'nome': nomeController.text,
          'login': loginController.text,
          'senha': Utils.gerarMd5(
            senhaController.text,
          ),
        });
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cadastro de cliente',
        ),
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 700,
          ),

          child: Padding(
            padding: const EdgeInsets.all(
              16,
            ),

            child: Form(
              key: formKey,

              child: Column(
                spacing: 16,

                children: [
                  TextFormField(
                    controller: nomeController,

                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),

                      labelText: 'Nome',
                    ),

                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obrigatório!';
                      }

                      return null;
                    },
                  ),

                  TextFormField(
                    controller: loginController,

                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),

                      labelText: 'Login',
                    ),

                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obrigatório!';
                      }

                      return null;
                    },
                  ),

                  TextFormField(
                    controller: senhaController,

                    obscureText: obscureText,

                    validator: validarSenha,

                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),

                      labelText: 'Senha',

                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(
                            () {
                              obscureText = !obscureText;
                            },
                          );
                        },

                        icon: Icon(
                          obscureText ? Icons.visibility : Icons.visibility_off,
                        ),
                      ),
                    ),
                  ),

                  ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }

                      try {
                        await cadastrar();

                        if (!context.mounted) {
                          return;
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Cliente cadastrado com sucesso!',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );

                        Navigator.pop(
                          context,
                        );
                      } on PostgrestException catch (e) {
                        if (!context.mounted) {
                          return;
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.code == '23505' ? 'Login já cadastrado' : 'Erro ao cadastrar',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } catch (_) {
                        if (!context.mounted) {
                          return;
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Falha ao realizar cadastro',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },

                    child: const Text(
                      'Cadastrar',
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
