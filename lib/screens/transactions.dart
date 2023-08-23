import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rhyno_app/components/loading.dart';
import 'package:rhyno_app/helpers/constants.dart';
import 'package:rhyno_app/firebase/database.dart';
import 'package:rhyno_app/helpers/helper_functions.dart';

class Transactions extends StatefulWidget {
  final String userId;
  const Transactions({Key? key, required this.userId}) : super(key: key);

  @override
  State<Transactions> createState() => _TransactionsState();
}

class _TransactionsState extends State<Transactions> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text(
            'Transactions',
            style: TextStyle(color: c2),
          ),
          backgroundColor: appBarColor,
        ),
        body: FutureBuilder(
          future: DatabaseMethods().getTransactions(widget.userId),
          builder: (context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Loading();
            }
            return snapshot.hasData
                ? Column(
                    children: [
                      ...(snapshot.data.docs.map((e) {
                        return Container(
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: appBarColor,
                              borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            title: Text('Amount: \u{20B9} ${e['amount']}',
                                style: const TextStyle(color: c2)),
                            subtitle: Text('PaymentId: ${e['paymentId']}',
                                style: const TextStyle(color: c1)),
                            trailing: Text(
                              convertTimestamp(e['time']),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 8, color: c1),
                            ),
                          ),
                        );
                      })).toList()
                    ],
                  )
                : Center(
                    child: Column(
                      children: const [
                        Icon(
                          Icons.notes_rounded,
                          color: c1,
                          size: 100,
                        ),
                        Text(
                          'No booking found',
                          style: TextStyle(color: c1),
                        ),
                      ],
                    ),
                  );
          },
        ));
  }
}
