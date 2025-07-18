import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pages/launcher_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final prefs = await SharedPreferences.getInstance();

  final savedTheme = prefs.getString('themeMode') ?? 'light';
  themeNotifier.value = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;

  final hasLaunchedBefore = prefs.getBool('hasLaunchedBefore') ?? false;
  final token = prefs.getString('token');

  runApp(SanaApp(
    hasLaunchedBefore: hasLaunchedBefore,
    isLoggedIn: token != null,
  ));
}

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

class SanaApp extends StatelessWidget {
  final bool hasLaunchedBefore;
  final bool isLoggedIn;

  const SanaApp({
    super.key,
    required this.hasLaunchedBefore,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, ThemeMode currentMode, _) {
        return MaterialApp(
          title: 'معجم سنا',
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromRGBO(93, 151, 144, 1.0), // Teal
              brightness: Brightness.light,
            ),
            // These are optional overrides if needed
            appBarTheme: const AppBarTheme(
              backgroundColor: Color.fromRGBO(93, 151, 144, 1.0),
              foregroundColor: Colors.white,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(93, 151, 144, 1.0),
                foregroundColor: Colors.white,
              ),
            ),
            progressIndicatorTheme: const ProgressIndicatorThemeData(
              color: Color.fromRGBO(93, 151, 144, 1.0),
            ),
            inputDecorationTheme: const InputDecorationTheme(
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color.fromRGBO(93, 151, 144, 1.0)),
              ),
              labelStyle: TextStyle(color: Color.fromRGBO(93, 151, 144, 1.0)),
            ),
            fontFamily: 'Noto'
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.black,
            appBarTheme: const AppBarTheme(
              backgroundColor: Color.fromRGBO(93, 151, 144, 1.0),
            ),
            fontFamily: 'Noto',
          ),
          themeMode: currentMode,
          debugShowCheckedModeBanner: false,
          initialRoute: '/',
          routes: {
            '/': (context) => const LauncherPage(),
            '/login': (context) => const LoginPageWrapper(),
            '/home': (context) => const HomePage(),
          },
        );
      },
    );
  }
}

class LoginPageWrapper extends StatelessWidget {
  const LoginPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: const LoginPage(),
    );
  }
}
