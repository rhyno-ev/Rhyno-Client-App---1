import 'package:flutter/material.dart';

class NotifationDot extends StatelessWidget {
  const NotifationDot({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration:
          const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
    );
  }
}
