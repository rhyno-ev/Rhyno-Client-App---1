import 'package:flutter/material.dart';
import 'package:rhyno_app/helpers/constants.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final TextInputType type;
  final String placeholder;

  const CustomTextField(
      {Key? key,
      required this.controller,
      required this.type,
      required this.placeholder})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: c1.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        keyboardType: type,
        controller: controller,
        decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(color: Colors.white),
            border: InputBorder.none),
      ),
    );
  }
}
