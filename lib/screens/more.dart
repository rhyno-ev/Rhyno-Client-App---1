import 'package:flutter/material.dart';
import 'package:rhyno_app/helpers/constants.dart';
import 'package:rhyno_app/screens/transactions.dart';
import 'package:rhyno_app/screens/vehicles.dart';

class More extends StatefulWidget {
  final String userId;
  const More({Key? key, required this.userId}) : super(key: key);

  @override
  State<More> createState() => _MoreState();
}

class _MoreState extends State<More> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(onPressed: (){
            Navigator.push(context, MaterialPageRoute(builder: (context) => Transactions(userId: widget.userId)));
          }, label: const Text('Transactions', style: TextStyle(color: c2, fontWeight: FontWeight.bold, fontSize: 16)), icon: const Icon(Icons.attach_money, color: c2, size: 24,),),
          TextButton.icon(onPressed: (){
            Navigator.push(context, MaterialPageRoute(builder: (context) => const Vehicles()));
          }, label: const Text('Vehicles', style: TextStyle(color: c2, fontWeight: FontWeight.bold, fontSize: 16)), icon: const Icon(Icons.electric_scooter, color: c2, size: 24,),)
        ],
      )
    );
  }
}