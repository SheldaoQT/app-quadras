import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginStore extends ChangeNotifier {
  User? get usuario => Supabase.instance.client.auth.currentUser;

  bool get logado => usuario != null;

  Future<void> sair() async {
    await Supabase.instance.client.auth.signOut();

    notifyListeners();
  }
}
