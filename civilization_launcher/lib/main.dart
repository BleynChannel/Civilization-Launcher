import 'package:civilization_launcher/const.dart';
import 'package:civilization_launcher/ui/pages/main_page.dart';
import 'package:civilization_launcher/ui/pages/settings_page.dart';
import 'package:civilization_launcher/ui/widgets/navigator_view.dart';
import 'package:desktop_window/desktop_window.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

Future main() async {
  runApp(DevicePreview(
    builder: (context) => const MyApp(),
    enabled: true,
  ));

  await DesktopWindow.setMinWindowSize(const Size(940, 560));
  await DesktopWindow.setMaxWindowSize(const Size(940, 560));

  Animate.restartOnHotReload = true;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Civilization Launcher',
      theme: ThemeData(
        primarySwatch: primaryColor,
        textTheme: TextTheme(
          headline4: GoogleFonts.nunitoSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          headline5: GoogleFonts.nunitoSans(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      home: NavigatorView(
        initialPage: 'main',
        routes: {
          'main': (context) => const MainPage(),
          'settings': (context) => const SettingsPage(),
        },
      ),

      // DevicePreview
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
    );
  }
}
