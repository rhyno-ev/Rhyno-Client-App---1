import 'package:flutter/material.dart';
import 'package:rhyno_app/helpers/constants.dart';

class CustomActionButton extends StatelessWidget {
  final dynamic onPressed;
  final String title;
  final bool buttonDisabled;
  const CustomActionButton({required this.onPressed, required this.title, required this.buttonDisabled, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width,
        height: width / 6,
        decoration: const BoxDecoration(
          color: c2,
          border: Border(top: BorderSide(width: 2, color: backgroundColor))
        ),
        child: buttonDisabled
            ? const Center(
                child: CircularProgressIndicator(color: backgroundColor),
              )
            : Center(
                child: Text(title,
                    style: const TextStyle(color: backgroundColor, fontWeight: FontWeight.bold)),
              ),
      ),
    );
  }
}