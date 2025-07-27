import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'main_app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/pin_screen.dart';

final wineRed = Color(0xFF7C2238);
final wineDark = Color(0xFF5C1A26);
final bgLight = Color(0xFFF8F8F8);
final dangerColor = Color(0xFFD7263D);

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Color(0xFF18191F),
  primaryColor: wineRed,
  colorScheme: ColorScheme.dark(
    primary: wineRed,
    secondary: wineDark,
    error: dangerColor,
    background: Color(0xFF18191F),
  ),
  textTheme: GoogleFonts.promptTextTheme(ThemeData.dark().textTheme).apply(
    bodyColor: Colors.white,
    displayColor: Colors.white,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Color(0xFF18191F),
    elevation: 0,
    titleTextStyle: GoogleFonts.prompt(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
    iconTheme: IconThemeData(color: Colors.white),
  ),
  cardTheme: CardThemeData(
    color: Color(0xFF23242A),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    elevation: 6,
  ),
);

final lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: bgLight,
  primaryColor: wineRed,
  colorScheme: ColorScheme.light(
    primary: wineRed,
    secondary: wineDark,
    error: dangerColor,
    background: bgLight,
  ),
  textTheme: GoogleFonts.promptTextTheme(ThemeData.light().textTheme).apply(
    bodyColor: Color(0xFF222222),
    displayColor: Color(0xFF222222),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.white,
    elevation: 0,
    titleTextStyle: GoogleFonts.prompt(fontSize: 22, color: wineRed, fontWeight: FontWeight.bold),
    iconTheme: IconThemeData(color: wineRed),
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    elevation: 5,
  ),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Installment App',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => SplashDecider(),
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const MainApp(),
      },
    );
  }
}

/// SplashDecider: decide to go login or main based on token
class SplashDecider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: ApiService().getToken(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final token = snapshot.data ?? '';
        Future.microtask(() async {
          if (token.isEmpty) {
            Navigator.of(context).pushReplacementNamed('/login');
          } else {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            String? pin = prefs.getString('user_pin');
            if (pin == null) {
              bool setup = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PinScreen(isSetup: true)),
              );
              if (setup == true) {
                Navigator.of(context).pushReplacementNamed('/main');
              } else {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            } else {
              bool ok = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PinScreen()),
              );
              if (ok == true) {
                Navigator.of(context).pushReplacementNamed('/main');
              } else {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            }
          }
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

