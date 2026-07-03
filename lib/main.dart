import 'package:app_quadras/login.dart';
import 'package:app_quadras/login_store.dart';
import 'package:app_quadras/profissional_store.dart';
import 'package:app_quadras/servico_store.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://cmhkcugwpqqkpruzwete.supabase.co',

    anonKey: 'sb_publishable_ox2qFgPXRV9sktnc0-8Oag_s814sEe-',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => LoginStore(),
        ),

        ChangeNotifierProvider(
          create: (_) => ServicoStore(),
        ),

        ChangeNotifierProvider(
          create: (_) => ProfissionalStore(),
        ),
      ],

      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Barbearia',

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
        ),

        textTheme: TextTheme(
          titleLarge: GoogleFonts.oswald(
            fontSize: 28,
          ),

          bodyMedium: GoogleFonts.merriweather(),

          displaySmall: GoogleFonts.poppins(),
        ),
      ),

      home: const TelaLogin(),
    );
  }
}
