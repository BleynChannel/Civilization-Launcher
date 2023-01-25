import 'package:flutter/material.dart';

class BackgroundView extends StatelessWidget {
  final Widget? child;

  const BackgroundView({Key? key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: Image.asset('assets/image/background.png').image,
          fit: BoxFit.cover,
        ),
      ),
      child: child,
    );
  }
}
