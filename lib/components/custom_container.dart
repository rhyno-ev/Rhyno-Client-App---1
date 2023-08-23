import 'package:flutter/material.dart';
import 'package:rhyno_app/helpers/constants.dart';

class CustomContainer extends StatelessWidget {
  final Widget customChild;
  const CustomContainer({Key? key, required this.customChild})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Container(
      width: width,
      height: width / 8,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: c1.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
      child: customChild,
    );
  }
}
