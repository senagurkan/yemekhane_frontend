import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login_screen.dart';
import 'screens/student/student_home_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  // .env dosyasını yükleyin (tam yolu yazmayı unutmayın)
  await dotenv.load(fileName: "/Users/senagurkan/yemekhane_uygulamasi/.env");
  initializeDateFormatting('tr_TR', null).then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('tr', 'TR'),
      ],
      locale: const Locale('tr', 'TR'), // Varsayılan dil Türkçe
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/student': (context) => StudentHomeScreen(),
      },
    );
  }
}

