typedef VoidCallback = void Function();
typedef PathProgressCallback = void Function(int count, int total, String path);

class ActionCallback {
  final VoidCallback? start;
  final VoidCallback? stop;

  ActionCallback({required this.start, required this.stop});
}
