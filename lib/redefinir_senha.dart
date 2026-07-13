import 'package:app_barba/login.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RedefinirSenha extends StatefulWidget {
  const RedefinirSenha({super.key});

  @override
  State<RedefinirSenha> createState() => _RedefinirSenhaState();
}

class _RedefinirSenhaState extends State<RedefinirSenha> {
  final formKey = GlobalKey<FormState>();
  final senhaController = TextEditingController();
  final confirmarSenhaController = TextEditingController();

  bool carregando = false;
  bool ocultarSenha = true;
  bool ocultarConfirmacao = true;

  @override
  void dispose() {
    senhaController.dispose();
    confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> salvarNovaSenha() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          password: senhaController.text,
        ),
      );

      await Supabase.instance.client.auth.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Senha alterada com sucesso. Faça login novamente.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const TelaLogin(),
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
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao redefinir senha: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        carregando = false;
      });
    }
  }

  String? validarSenha(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe a nova senha';
    }

    if (value.length < 6) {
      return 'A senha deve ter no mínimo 6 caracteres';
    }

    return null;
  }

  String? validarConfirmacao(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirme a nova senha';
    }

    if (value != senhaController.text) {
      return 'As senhas não conferem';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova senha'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 400,
            ),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.brown.shade100,
                        child: const Icon(
                          Icons.lock_reset,
                          size: 42,
                          color: Colors.brown,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Redefinir senha',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Digite sua nova senha para acessar a Barbearia FM.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: senhaController,
                        obscureText: ocultarSenha,
                        decoration: InputDecoration(
                          labelText: 'Nova senha',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                ocultarSenha = !ocultarSenha;
                              });
                            },
                            icon: Icon(
                              ocultarSenha ? Icons.visibility : Icons.visibility_off,
                            ),
                          ),
                        ),
                        validator: validarSenha,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: confirmarSenhaController,
                        obscureText: ocultarConfirmacao,
                        decoration: InputDecoration(
                          labelText: 'Confirmar nova senha',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                ocultarConfirmacao = !ocultarConfirmacao;
                              });
                            },
                            icon: Icon(
                              ocultarConfirmacao ? Icons.visibility : Icons.visibility_off,
                            ),
                          ),
                        ),
                        validator: validarConfirmacao,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: carregando ? null : salvarNovaSenha,
                          icon: carregando
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            carregando ? 'Salvando...' : 'Salvar nova senha',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
