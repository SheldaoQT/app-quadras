import 'package:app_barba/cadastro_cliente.dart';
import 'package:app_barba/home_cliente.dart';
import 'package:app_barba/home_funcionario.dart';
import 'package:app_barba/recuperar_senha.dart';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({
    super.key,
  });

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  bool obscureText = true;
  bool carregando = false;

  final formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final senhaController = TextEditingController();

  Future<void> autenticar() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      final supabase = Supabase.instance.client;

      final resposta = await supabase.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: senhaController.text,
      );

      if (resposta.user == null) {
        throw Exception('Usuário inválido');
      }

      final dados = await supabase.from('usuarios').select().eq('id', resposta.user!.id).single();

      final perfil = dados['perfil'];

      final isFuncionario = perfil == 'funcionario' || perfil == 'admin';

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => isFuncionario ? const HomeFuncionario() : const HomeCliente(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(e.toString()),
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      carregando = false;
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 350,
          ),
          child: Padding(
            padding: const EdgeInsets.all(
              20,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.content_cut,
                    size: 80,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Barbearia',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obrigatório';
                      }

                      if (!value.contains('@')) {
                        return 'E-mail inválido';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: senhaController,
                    obscureText: obscureText,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      border: const OutlineInputBorder(),
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
                      onPressed: carregando ? null : autenticar,
                      child: carregando ? const CircularProgressIndicator() : const Text('Entrar'),
                    ),
                  ),
                  TextButton(
                    onPressed: carregando
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RecuperarSenha(),
                              ),
                            );
                          },
                    child: const Text('Esqueci minha senha'),
                  ),
                  TextButton(
                    onPressed: carregando
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CadastroCliente(),
                              ),
                            );
                          },
                    child: const Text('Criar conta'),
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
