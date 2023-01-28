import 'dart:io';

class Launch {
  static Future launchMinecraft({
    required String path,
    List<String>? args,
  }) async {
    await Process.run(path, args ?? []);
  }
}
