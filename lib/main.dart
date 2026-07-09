import 'package:app_barba/login.dart';
import 'package:app_barba/login_store.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Intl.defaultLocale = 'pt_BR';

  await Supabase.initialize(
    url: 'https://ftzucptuhqlrkhjlgcju.supabase.co',
    publishableKey: 'sb_publishable__ikP1qER35XD6Ll2MXchdw_PKzdlTwg',
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => LoginStore(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Barbearia',
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.brown,
        ),
        textTheme: TextTheme(
          titleLarge: GoogleFonts.oswald(
            fontSize: 28,
          ),
          bodyMedium: GoogleFonts.poppins(),
        ),
      ),
      home: const TelaLogin(),
    );
  }
}
