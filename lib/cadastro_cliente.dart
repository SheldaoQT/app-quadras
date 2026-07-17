import 'package:app_barba/home_cliente.dart';
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
  final emailController = TextEditingController();
  final senhaController = TextEditingController();

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    senhaController.dispose();

    super.dispose();
  }

  String? validarSenha(String? value) {
    if (value == null || value.isEmpty) {
      return 'Campo obrigatório';
    }

    if (value.length < 6) {
      return 'Mínimo de 6 caracteres';
    }

    return null;
  }

  Future<void> cadastrar() async {
    final supabase = Supabase.instance.client;

    final auth = await supabase.auth.signUp(
      email: emailController.text.trim(),
      password: senhaController.text,
    );

    if (auth.user == null) {
      throw Exception(
        'Falha ao criar usuário',
      );
    }

    /*
     * Quando a confirmação de e-mail está desativada,
     * o cadastro já retorna uma sessão autenticada.
     */
    if (auth.session == null) {
      throw const AuthException(
        'Confirme seu e-mail antes de entrar.',
      );
    }

    await supabase.from('usuarios').insert({
      'id': auth.user!.id,
      'nome': nomeController.text.trim(),
      'perfil': 'cliente',
    });
  }

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.all(16),
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
                      if (value == null || value.trim().isEmpty) {
                        return 'Campo obrigatório!';
                      }

                      return null;
                    },
                  ),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'E-mail',
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';

                      if (email.isEmpty) {
                        return 'Campo obrigatório!';
                      }

                      if (!email.contains('@')) {
                        return 'E-mail inválido';
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
                          setState(() {
                            obscureText = !obscureText;
                          });
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

                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Cliente cadastrado com sucesso!',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );

                        /*
                         * Abre a HomeCliente e remove as telas
                         * de cadastro e login do histórico.
                         */
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HomeCliente(),
                          ),
                          (route) => false,
                        );
                      } on AuthException catch (e) {
                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.message),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } on PostgrestException catch (e) {
                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.code == '23505' ? 'Login já cadastrado' : 'Erro ao cadastrar cliente',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Falha ao realizar cadastro: $e',
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
