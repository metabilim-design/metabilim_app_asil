import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:metabilim/auth_service.dart';
import 'package:metabilim/firebase_options.dart';
import 'package:metabilim/login_page.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // Modern görünüm için Google Fonts ekliyoruz

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Açık mavi tonlarında modern bir renk paleti tanımlıyoruz
    const Color primaryColor = Color(0xFF4FC3F7); // Canlı açık mavi
    const Color secondaryColor = Color(0xFF29B6F6); // Bir ton koyu mavi
    const Color backgroundColor = Color(0xFFF5F7FA); // Çok hafif mavimsi beyaz/gri
    const Color textColor = Color(0xFF37474F); // Okunabilir koyu gri

    return Provider<AuthService>(
      create: (_) => AuthService(),
      child: MaterialApp(
        title: 'Metabilim',
        debugShowCheckedModeBanner: false,

        theme: ThemeData(
          primaryColor: primaryColor,
          scaffoldBackgroundColor: backgroundColor,

          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.lightBlue,
          ).copyWith(
            primary: primaryColor,
            secondary: secondaryColor,
            background: backgroundColor,
          ),

          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme).apply(
            bodyColor: textColor,
            displayColor: textColor,
          ),

          appBarTheme: AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: textColor,
            elevation: 1,
            titleTextStyle: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            iconTheme: IconThemeData(color: textColor),
          ),

          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),

          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
          ),

          // --- HATA BURADAYDI, DÜZELTİLDİ ---
          // 'CardTheme' yerine doğru sınıf adı olan 'CardThemeData' kullanıldı.
          cardTheme: CardThemeData(
            elevation: 1.5,
            shadowColor: Colors.grey.withOpacity(0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        home: const LoginPage(),
      ),
    );
  }
}