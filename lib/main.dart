import 'package:flutter/material.dart';
import 'pages/home.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // importapacote oficial supabase para flutter: autenticacao e storage

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized(); // Garante que o Flutter está inicializado antes de rodar código assíncrono

  await Supabase.initialize(
    url: 'https://fcllsohflbrwajretrza.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZjbGxzb2hmbGJyd2FqcmV0cnphIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY0NDM3OTQsImV4cCI6MjA3MjAxOTc5NH0.8ap41ZATa5UJJSqVogwTaIzPAQmUmrwhYutihwmW01s',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pay & Go',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const Home(),
    );
  }
}
