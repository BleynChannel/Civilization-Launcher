import 'package:civilization_launcher/ui/widgets/background_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

typedef BuilderCallback = Widget Function(BuildContext context);

class NavigatorView extends StatefulWidget {
  final String initialPage;
  final Map<String, BuilderCallback> routes;

  const NavigatorView({
    Key? key,
    required this.initialPage,
    required this.routes,
  }) : super(key: key);

  static void push(BuildContext context, String page) {
    context.findAncestorStateOfType<_NavigatorViewState>()?.push(page);
  }

  static void back(BuildContext context) {
    context.findAncestorStateOfType<_NavigatorViewState>()?.back();
  }

  @override
  _NavigatorViewState createState() => _NavigatorViewState();
}

class _NavigatorViewState extends State<NavigatorView>
    with SingleTickerProviderStateMixin {
  late List<Widget> _pages;

  BuilderCallback? _pushBuilder;
  late bool _isAnimating;
  late bool _isForward;
  late bool _isAnimationReverse;

  void push(String page) {
    setState(() {
      _pushBuilder = widget.routes[page]!;
      _isAnimating = true;
      _isForward = true;
    });
  }

  void back() {
    if (_pages.length > 1) {
      setState(() {
        _isAnimating = true;
        _isForward = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _pages = [];

    _isAnimating = false;
    _isForward = true;
    _isAnimationReverse = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_pages.isEmpty) {
      _pages.add(widget.routes[widget.initialPage]!(context));
    }

    return Scaffold(
      body: BackgroundView(
        child: Animate(
          effects: !_isAnimationReverse
              ? [
                  FadeEffect(end: 0.0, duration: 250.ms),
                  CallbackEffect(
                    delay: 248.ms,
                    callback: (_) => _isAnimationReverse = true,
                  ),
                ]
              : [
                  FadeEffect(begin: 0.0, end: 1.0, duration: 250.ms),
                  CallbackEffect(
                    delay: 248.ms,
                    callback: (_) => _isAnimationReverse = false,
                  ),
                ],
          onPlay: (controller) {
            !_isAnimating ? controller.stop() : null;
          },
          onComplete: (controller) => setState(() {
            if (_isAnimationReverse) {
              if (_pushBuilder != null) {
                _pages.add(_pushBuilder!(context));
                _pushBuilder = null;
              }

              if (!_isForward) {
                _pages.removeLast();
              }
            } else {
              _isAnimating = false;
              _isForward = true;
            }
          }),
          child: IndexedStack(
            key: ValueKey(_pages.length - 1),
            index: _pages.length - 1,
            children: _pages,
          ),
        ),
      ),
    );
  }
}
