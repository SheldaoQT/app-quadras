import 'package:app_quadras/cadastro_cliente.dart';
import 'package:app_quadras/home_cliente.dart';
import 'package:app_quadras/home_funcionario.dart';
import 'package:app_quadras/login_store.dart';
import 'package:app_quadras/usuario.dart';
import 'package:app_quadras/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  final formKey = GlobalKey<FormState>();

  final loginController = TextEditingController();

  final senhaController = TextEditingController();

  Future<void> autenticar() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    try {
      final supabase = Supabase.instance.client;

      final usuarios = await supabase
          .from(
            'usuario',
          )
          .select()
          .eq(
            'login',
            loginController.text,
          )
          .eq(
            'senha',
            Utils.gerarMd5(
              senhaController.text,
            ),
          );

      if (usuarios.isEmpty) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content: Text(
              'Credenciais inválidas',
            ),

            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      final usuario = Usuario(
        id: usuarios.first['id'],

        nomeCompleto: usuarios.first['nome_completo'],

        login: usuarios.first['login'],

        senha: usuarios.first['senha'],

        isAdm: usuarios.first['is_adm'],
      );

      context.read<LoginStore>().setUsuario(
        usuario,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Login realizado',
          ),

          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,

        MaterialPageRoute(
          builder: (_) => usuario.isAdm ? const HomeFuncionario() : const HomeCliente(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Erro: $e',
          ),
        ),
      );
    }
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
                  const Text(
                    'Barbearia',
                    style: TextStyle(
                      fontSize: 30,

                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 30,
                  ),

                  TextFormField(
                    controller: loginController,

                    decoration: const InputDecoration(
                      labelText: 'Login',

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
                    height: 16,
                  ),

                  TextFormField(
                    controller: senhaController,

                    obscureText: obscureText,

                    decoration: InputDecoration(
                      labelText: 'Senha',

                      border: const OutlineInputBorder(),

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

                  SizedBox(
                    width: double.infinity,

                    child: ElevatedButton(
                      onPressed: autenticar,

                      child: const Text(
                        'Entrar',
                      ),
                    ),
                  ),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder:
                              (
                                context,
                              ) => const CadastroCliente(),
                        ),
                      );
                    },

                    child: const Text(
                      'Criar conta',
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
