import 'package:civilization_launcher/core/civilization_lib.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const primaryColor = Colors.blue;

late SharedPreferences prefs;

const String prefsModpackPath = 'modpack_path';
const String prefsMinecraftPath = 'minecraft_path';

late ModpackUpdater updater;