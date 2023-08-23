import 'package:flutter/material.dart';

class Filler extends StatefulWidget {
  const Filler({Key? key}) : super(key: key);

  @override
  State<Filler> createState() => _FillerState();
}

class _FillerState extends State<Filler> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return SizedBox(height: width/3,);
  }
}