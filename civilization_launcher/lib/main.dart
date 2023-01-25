import 'package:civilization_launcher/const.dart';
import 'package:civilization_launcher/ui/pages/main_page.dart';
import 'package:civilization_launcher/ui/pages/settings_page.dart';
import 'package:desktop_window/desktop_window.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';

Future main() async {
  runApp(DevicePreview(
    builder: (context) => const MyApp(),
    enabled: true,
  ));

  await DesktopWindow.setMinWindowSize(const Size(940, 560));
  await DesktopWindow.setMaxWindowSize(const Size(940, 560));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Civilization Launcher',
      theme: ThemeData(
        primarySwatch: primaryColor,
      ),
      routes: {
        '/': (context) => const MainPage(),
        '/settings': (context) => const SettingsPage(),
      },
      initialRoute: '/',

      // DevicePreview
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
    );
  }
}
