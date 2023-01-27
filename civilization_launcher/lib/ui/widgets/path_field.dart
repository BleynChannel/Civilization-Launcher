import 'package:civilization_launcher/ui/utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PathField extends StatefulWidget {
  final String? path;
  final void Function(String path)? onChangePath;
  final Future<String?> Function(String oldPath)? onPathPick;

  const PathField({
    Key? key,
    this.path,
    this.onChangePath,
    this.onPathPick,
  }) : super(key: key);

  @override
  _PathFieldState createState() => _PathFieldState();
}

class _PathFieldState extends State<PathField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.path?.trim() ?? '')
      ..addListener(() => widget.onChangePath?.call(_controller.text));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PathField oldWidget) {
    super.didUpdateWidget(oldWidget);

    _controller.text = widget.path?.trim() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    const pathButtonWidth = 80.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          TextField(
            controller: _controller,
            decoration: getTextFieldDecoration().copyWith(
              hintText: 'Введите путь...',
              contentPadding:
                  const EdgeInsets.only(left: 10, right: pathButtonWidth + 10),
            ),
            style: GoogleFonts.nunitoSans(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: pathButtonWidth,
                  child: InkWell(
                    onTap: () async {
                      _controller.text =
                          await widget.onPathPick?.call(_controller.text) ?? '';
                    },
                    child: Container(
                      color: Colors.white,
                      child: const Center(
                        child: Text(
                          '...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
