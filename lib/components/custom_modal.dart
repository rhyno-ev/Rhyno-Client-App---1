import 'package:flutter/material.dart';
import 'package:rhyno_app/helpers/constants.dart';

class CustomModal extends StatelessWidget {
  final dynamic onSubmit, onCancel;
  final String title, content;
  const CustomModal(
      {required this.onSubmit,
      required this.onCancel,
      required this.title,
      required this.content,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: backgroundColor,
      actions: [
        TextButton(
            onPressed: onCancel,
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            )),
        TextButton(
            onPressed: onSubmit,
            child: const Text(
              'Okay',
              style: TextStyle(color: c2),
            ))
      ],
      title: Text(
        title,
        style: const TextStyle(color: c2),
      ),
      content: Text(
        content,
        style: const TextStyle(color: c1),
      ),
    );
  }
}
