import 'package:app_quadras/cadastro_usuario.dart';
import 'package:app_quadras/login_store.dart';
import 'package:app_quadras/principal.dart';
import 'package:app_quadras/principal_adm.dart';
import 'package:app_quadras/usuario.dart';
import 'package:app_quadras/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  var obscureText = true;
  var formKey = GlobalKey<FormState>();
  var loginController = TextEditingController();
  var senhaController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // SizedBox(
      //   width: MediaQuery.of(context).size.width,
      //   height: MediaQuery.of(context).size.height,
      // )
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: 300,
            maxWidth: 300,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 16,
              children: [
                TextFormField(
                  controller: loginController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Login",
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Campo obrigatório!";
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: senhaController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Senha",
                    // suffixIcon: obscureText == true ? Icon(Icons.visibility) : Icon(Icons.visibility_off),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obscureText = !obscureText;
                        });
                      },
                      icon: obscureText == true ? Icon(Icons.visibility) : Icon(Icons.visibility_off),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Campo obrigatório!";
                    }
                    return null;
                  },
                  obscureText: obscureText,
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final supabase = Supabase.instance.client;
                      final usuarios = await supabase
                          .from("usuario") //
                          .select()
                          .eq("login", loginController.text)
                          .eq("senha", Utils.gerarMd5(senhaController.text));
                      if (usuarios.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Credenciais inválidas"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } else {
                        context.read<LoginStore>().setUsuario(
                          Usuario(
                            id: usuarios.first["id"],
                            nomeCompleto: usuarios.first["nome_completo"],
                            login: usuarios.first["login"],
                            senha: usuarios.first["senha"],
                            isAdm: usuarios.first["is_adm"],
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Usuário autenticado com sucesso"),
                            backgroundColor: Colors.green,
                          ),
                        );
                        if (usuarios.first["is_adm"]) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) {
                                return TelaPrincipalAdm();
                              },
                            ),
                          );
                        } else {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) {
                                return TelaPrincipal();
                              },
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: Text("Entrar"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return CadastroUsuario();
                        },
                      ),
                    );
                  },
                  child: Text("Cadastre-se"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
