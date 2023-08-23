import 'package:flutter/material.dart';
import 'package:rhyno_app/helpers/constants.dart';

class Loading extends StatelessWidget {
  const Loading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
          child: CircularProgressIndicator(
        color: c2,
      )),
    );
  }
}
